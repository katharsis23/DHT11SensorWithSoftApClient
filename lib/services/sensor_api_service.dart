import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorApiService {
  final String baseUrl;
  
  SensorApiService({required String deviceIp}) : baseUrl = "http://$deviceIp";

  /// Get device IP address
  Future<String?> getDeviceIp() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.body.trim();
      }
      return null;
    } catch (e) {
      print('[SensorApi] Error getting device IP: $e');
      return null;
    }
  }

  /// Get all sensor data
  Future<Map<String, dynamic>?> getAllSensorsData() async {
    try {
      print('[SensorApi] Fetching all sensors data...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/sensors'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[SensorApi] Sensors data received: $data');
        return data;
      }
      
      print('[SensorApi] Failed to get sensors data: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[SensorApi] Error fetching sensors data: $e');
      return null;
    }
  }

  /// Get DHT22 sensor data (temperature and humidity)
  Future<DHT22Data?> getDHT22Data() async {
    try {
      print('[SensorApi] Fetching DHT22 data...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/sensors/dht'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[SensorApi] DHT22 data received: $data');
        
        // Перевіряємо різні формати відповіді
        if (data is Map<String, dynamic>) {
          // Формат 1: {"temperature": 18.6, "humidity": 45.0, ...}
          if (data.containsKey('temperature') && data.containsKey('humidity')) {
            return DHT22Data.fromJson(data);
          }
          // Формат 2: {"dht": {"temperature": 18.6, "humidity": 45.0, ...}}
          else if (data.containsKey('dht') && data['dht'] is Map<String, dynamic>) {
            final dhtData = data['dht'] as Map<String, dynamic>;
            if (dhtData.containsKey('temperature') && dhtData.containsKey('humidity')) {
              return DHT22Data.fromJson(dhtData);
            }
          }
        }
        
        print('[SensorApi] Unexpected DHT22 data format');
        return null;
      }
      
      print('[SensorApi] Failed to get DHT22 data: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[SensorApi] Error fetching DHT22 data: $e');
      return null;
    }
  }

  /// Get device information
  Future<DeviceInfo?> getDeviceInfo() async {
    try {
      print('[SensorApi] Fetching device info...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/device'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[SensorApi] Device info received: $data');
        return DeviceInfo.fromJson(data);
      }
      
      print('[SensorApi] Failed to get device info: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[SensorApi] Error fetching device info: $e');
      return null;
    }
  }

  /// Get mDNS name
  Future<String?> getMDNSName() async {
    try {
      print('[SensorApi] Fetching mDNS name...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/get-mDNS'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final mdnsName = response.body.trim();
        print('[SensorApi] mDNS name: $mdnsName');
        return mdnsName;
      }
      
      print('[SensorApi] Failed to get mDNS name: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[SensorApi] Error fetching mDNS name: $e');
      return null;
    }
  }

  /// Delete stored WiFi credentials
  Future<bool> deleteCredentials() async {
    try {
      print('[SensorApi] Deleting credentials...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/delete-credatials'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('[SensorApi] Credentials deleted successfully');
        return true;
      }
      
      print('[SensorApi] Failed to delete credentials: ${response.statusCode}');
      return false;
    } catch (e) {
      print('[SensorApi] Error deleting credentials: $e');
      return false;
    }
  }

  /// Test endpoint to check connectivity
  Future<bool> testConnection() async {
    try {
      print('[SensorApi] Testing connection...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/hello'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('[SensorApi] Connection test successful: ${response.body}');
        return true;
      }
      
      print('[SensorApi] Connection test failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('[SensorApi] Connection test error: $e');
      return false;
    }
  }

  /// Check protocol version (for provisioning mode)
  Future<bool> checkProtocolVersion() async {
    try {
      print('[SensorApi] Checking protocol version...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/proto-ver'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('[SensorApi] Protocol version OK: ${response.body}');
        return true;
      }
      
      print('[SensorApi] Protocol version check failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('[SensorApi] Protocol version error: $e');
      return false;
    }
  }
}

/// DHT22 Sensor Data Model
class DHT22Data {
  final double temperature;
  final double humidity;
  final DateTime timestamp;

  DHT22Data({
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory DHT22Data.fromJson(Map<String, dynamic> json) {
    return DHT22Data(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      timestamp: _parseTimestamp(json['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() => 'DHT22(temp: ${temperature.toStringAsFixed(1)}°C, humidity: ${humidity.toStringAsFixed(1)}%)';
}

/// Device Information Model
class DeviceInfo {
  final String deviceId;
  final String firmware;
  final String ip;
  final String mac;
  final String? mdnsName;
  final int uptime;
  final int freeHeap;
  final DateTime timestamp;

  DeviceInfo({
    required this.deviceId,
    required this.firmware,
    required this.ip,
    required this.mac,
    this.mdnsName,
    required this.uptime,
    required this.freeHeap,
    required this.timestamp,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id']?.toString() ?? json['id']?.toString() ?? 'Unknown',
      firmware: json['firmware']?.toString() ?? json['version']?.toString() ?? 'Unknown',
      ip: json['ip']?.toString() ?? '0.0.0.0',
      mac: json['mac']?.toString() ?? '00:00:00:00:00:00',
      mdnsName: json['mdns']?.toString() ?? json['mdns_name']?.toString(),
      uptime: (json['uptime'] ?? 0).toInt(),
      freeHeap: (json['free_heap'] ?? json['freeHeap'] ?? 0).toInt(),
      timestamp: DHT22Data._parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'firmware': firmware,
      'ip': ip,
      'mac': mac,
      'mdns': mdnsName,
      'uptime': uptime,
      'free_heap': freeHeap,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get uptimeFormatted {
    final hours = uptime ~/ 3600;
    final minutes = (uptime % 3600) ~/ 60;
    final seconds = uptime % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  String get freeHeapFormatted {
    if (freeHeap < 1024) {
      return '${freeHeap}B';
    } else if (freeHeap < 1024 * 1024) {
      return '${(freeHeap / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(freeHeap / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  @override
  String toString() => 'Device($deviceId, IP: $ip, Firmware: $firmware)';
}
