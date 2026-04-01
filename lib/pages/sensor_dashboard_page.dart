import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_monitor/services/sensor_api_service.dart';

class SensorDashboardPage extends StatefulWidget {
  final String deviceIp;
  
  const SensorDashboardPage({super.key, required this.deviceIp});

  @override
  State<SensorDashboardPage> createState() => _SensorDashboardPageState();
}

class _SensorDashboardPageState extends State<SensorDashboardPage>
    with TickerProviderStateMixin {
  late SensorApiService _sensorApi;
  late AnimationController _tempController;
  late AnimationController _humidityController;
  
  DHT22Data? _dht22Data;
  DeviceInfo? _deviceInfo;
  String? _mdnsName;
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;
  
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _sensorApi = SensorApiService(deviceIp: widget.deviceIp);
    
    // Анімації для температури та вологості
    _tempController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _humidityController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _testConnection();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tempController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isConnected) {
        _refreshDHTData();
      }
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connected = await _sensorApi.testConnection();
      setState(() {
        _isConnected = connected;
        _isLoading = false;
        if (!connected) {
          _errorMessage = 'Failed to connect to device at ${widget.deviceIp}';
        }
      });

      if (connected) {
        _refreshDHTData();
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  Future<void> _refreshDHTData() async {
    if (!_isConnected) return;

    try {
      // Спочатку спробуємо отримати всі сенсори через /sensors
      final allSensorsData = await _sensorApi.getAllSensorsData();
      
      if (allSensorsData != null && allSensorsData.containsKey('dht')) {
        final dhtData = allSensorsData['dht'] as Map<String, dynamic>;
        final dht22Data = DHT22Data.fromJson(dhtData);
        
        setState(() {
          _dht22Data = dht22Data;
          _errorMessage = null;
        });
      } else {
        // Якщо формат не очікуваний, спробуємо старий ендпоінт
        final dhtData = await _sensorApi.getDHT22Data();
        setState(() {
          _dht22Data = dhtData;
          _errorMessage = null;
        });
      }

      // Отримуємо інформацію про пристрій
      final deviceInfo = await _sensorApi.getDeviceInfo();
      final mdnsName = await _sensorApi.getMDNSName();
      
      setState(() {
        _deviceInfo = deviceInfo;
        _mdnsName = mdnsName;
      });

      // Запускаємо анімації при оновленні даних
      if (_dht22Data != null) {
        _tempController.forward().then((_) => _tempController.reverse());
        _humidityController.forward().then((_) => _humidityController.reverse());
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
      });
    }
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 10) return Colors.blue;
    if (temp < 20) return Colors.cyan;
    if (temp < 25) return Colors.green;
    if (temp < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.orange;
    if (humidity < 60) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('DHT22 Sensor (${widget.deviceIp})'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshDHTData,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteCredentials,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDHTData,
        color: Colors.blue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              _buildConnectionStatusCard(),
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 24),
              ],
              
              // Main DHT22 Display
              if (_dht22Data != null) ...[
                _buildMainDHTCard(),
                const SizedBox(height: 24),
                
                // Device Information Card
                if (_deviceInfo != null) ...[
                  _buildDeviceInfoCard(),
                  const SizedBox(height: 24),
                ],
                
                // Detailed Stats
                _buildDetailedStats(),
                const SizedBox(height: 24),
              ],
              
              // Loading State
              if (_isLoading && _dht22Data == null)
                _buildLoadingState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected 
            ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
            : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  'Device: ${widget.deviceIp}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          if (!_isConnected)
            ElevatedButton(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reconnect'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDHTCard() {
    final tempColor = _getTemperatureColor(_dht22Data!.temperature);
    final humidityColor = _getHumidityColor(_dht22Data!.humidity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A8A),
            const Color(0xFF312E81),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'DHT22 Sensor Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              // Temperature
              Expanded(
                child: AnimatedBuilder(
                  animation: _tempController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_tempController.value * 0.1),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: tempColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tempColor.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: tempColor,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Temperature',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[300],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_dht22Data!.temperature.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: tempColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Humidity
              Expanded(
                child: AnimatedBuilder(
                  animation: _humidityController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_humidityController.value * 0.1),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: humidityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: humidityColor.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: humidityColor,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Humidity',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[300],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_dht22Data!.humidity.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: humidityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Last Update
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Last updated: ${_formatDateTime(_dht22Data!.timestamp)}',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Device ID', _deviceInfo!.deviceId),
          _buildInfoRow('IP Address', _deviceInfo!.ip),
          if (_mdnsName != null) _buildInfoRow('mDNS Name', _mdnsName!),
          _buildInfoRow('MAC Address', _deviceInfo!.mac),
          _buildInfoRow('Firmware', _deviceInfo!.firmware),
          _buildInfoRow('Uptime', _deviceInfo!.uptimeFormatted),
          _buildInfoRow('Free Memory', _deviceInfo!.freeHeapFormatted),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    final tempColor = _getTemperatureColor(_dht22Data!.temperature);
    final humidityColor = _getHumidityColor(_dht22Data!.humidity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensor Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStatusRow('Temperature Status', _getTemperatureStatus(_dht22Data!.temperature), tempColor),
          _buildStatusRow('Humidity Status', _getHumidityStatus(_dht22Data!.humidity), humidityColor),
          _buildStatusRow('Comfort Level', _getComfortLevel(_dht22Data!.temperature, _dht22Data!.humidity), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(64.0),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Loading sensor data...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCredentials() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete WiFi Credentials'),
        content: const Text('This will remove all stored WiFi credentials from the ESP32. The device will restart in provisioning mode.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _sensorApi.deleteCredentials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Credentials deleted successfully' : 'Failed to delete credentials'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _getTemperatureStatus(double temp) {
    if (temp < 10) return 'Cold';
    if (temp < 20) return 'Cool';
    if (temp < 25) return 'Comfortable';
    if (temp < 30) return 'Warm';
    return 'Hot';
  }

  String _getHumidityStatus(double humidity) {
    if (humidity < 30) return 'Dry';
    if (humidity < 60) return 'Comfortable';
    return 'Humid';
  }

  String _getComfortLevel(double temp, double humidity) {
    if (temp >= 20 && temp <= 25 && humidity >= 40 && humidity <= 60) {
      return 'Optimal';
    }
    if (temp >= 18 && temp <= 27 && humidity >= 30 && humidity <= 70) {
      return 'Good';
    }
    return 'Poor';
  }
}
