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
        final data = jsonDecode(response.body);
        return data['ip'] as String?;
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
        return DHT22Data.fromJson(data);
      }
      
      print('[SensorApi] Failed to get DHT22 data: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[SensorApi] Error fetching DHT22 data: $e');
      return null;
    }
  }

  /// Get MQ2 sensor data (gas levels)
  Future<MQ2Data?> getMQ2Data() async {
    try {
      print('[SensorApi] Fetching MQ2 data...');
      
      final response = await http
          .get(Uri.parse('$baseUrl/sensors/mq2'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[SensorApi] MQ2 data received: $data');
        return MQ2Data.fromJson(data);
      }
      
      print('[SensorApi] Failed to get MQ2 data: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[SensorApi] Error fetching MQ2 data: $e');
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
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
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

/// MQ2 Gas Sensor Data Model
class MQ2Data {
  final int lpg;
  final int co;
  final int smoke;
  final DateTime timestamp;

  MQ2Data({
    required this.lpg,
    required this.co,
    required this.smoke,
    required this.timestamp,
  });

  factory MQ2Data.fromJson(Map<String, dynamic> json) {
    return MQ2Data(
      lpg: json['lpg'] ?? 0,
      co: json['co'] ?? 0,
      smoke: json['smoke'] ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lpg': lpg,
      'co': co,
      'smoke': smoke,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() => 'MQ2(LPG: $lpg, CO: $co, Smoke: $smoke)';
}

/// Device Information Model
class DeviceInfo {
  final String deviceId;
  final String firmware;
  final String ip;
  final String mac;
  final int uptime;
  final int freeHeap;
  final DateTime timestamp;

  DeviceInfo({
    required this.deviceId,
    required this.firmware,
    required this.ip,
    required this.mac,
    required this.uptime,
    required this.freeHeap,
    required this.timestamp,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id'] ?? 'Unknown',
      firmware: json['firmware'] ?? 'Unknown',
      ip: json['ip'] ?? '0.0.0.0',
      mac: json['mac'] ?? '00:00:00:00:00:00',
      uptime: json['uptime'] ?? 0,
      freeHeap: json['free_heap'] ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'firmware': firmware,
      'ip': ip,
      'mac': mac,
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

  @override
  String toString() => 'Device($deviceId, IP: $ip, Firmware: $firmware)';
}
