import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EspManager {
  // ✅ Singleton
  static final EspManager _instance = EspManager._internal();
  factory EspManager() => _instance;
  EspManager._internal();

  String _ip = 'esp.local';

  // ✅ Getter для IP
  String get ip => _ip;

  /// ✅ Завантажити IP з SharedPreferences
  Future<void> loadEspIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('ESP_IP');
      if (savedIp != null && savedIp.isNotEmpty) {
        _ip = savedIp;
        print('✅ Loaded ESP IP: $_ip');
      } else {
        print('ℹ️ No saved IP, using default: $_ip');
      }
    } catch (e) {
      print('❌ Error loading ESP IP: $e');
    }
  }

  /// ✅ Зберегти IP в SharedPreferences
  Future<void> saveEspIp(String newIp) async {
    try {
      _ip = newIp;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ESP_IP', newIp);
      print('✅ Saved ESP IP: $_ip');
    } catch (e) {
      print('❌ Error saving ESP IP: $e');
      rethrow;
    }
  }

  /// ✅ Змінити IP (збереження в SharedPreferences)
  Future<void> set_base_url(String new_url) async {
    await saveEspIp(new_url);
  }

  /// ✅ Отримати пристрої з ESP32
 

  /// ✅ Перевірити статус підключення до ESP
  Future<bool> pingEsp() async {
    try {
      // Спробуємо різні ендпоінти та порти
      final endpoints = [
        "http://$_ip:80/hello",           // Основний тестовий ендпоінт
        "http://$_ip:80/proto-ver",       // Для provisioning режиму
        "http://$_ip:80/",                // Отримання IP
        "http://$_ip:80/sensors/dht",     // DHT сенсор
        "http://$_ip:80/device",          // Інформація про пристрій
        "http://$_ip:80/get-mDNS",        // mDNS ім'я
      ];
      
      for (String endpoint in endpoints) {
        try {
          print('[EspManager] Trying endpoint: $endpoint');
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {'Connection': 'close'},
          ).timeout(const Duration(seconds: 3));
          
          if (response.statusCode == 200) {
            print('[EspManager] ✓ Success on: $endpoint');
            return true;
          }
        } catch (e) {
          print('[EspManager] ✗ Failed on $endpoint: $e');
          continue;
        }
      }
      
      print('[EspManager] ❌ All endpoints failed');
      return false;
    } catch (e) {
      print('❌ ESP ping failed: $e');
      return false;
    }
  }

  /// ✅ Очистити збережений IP
  Future<void> clearEspIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ESP_IP');
      _ip = 'esp.local';
      print('🗑️ ESP IP cleared');
    } catch (e) {
      print('❌ Error clearing ESP IP: $e');
    }
  }
}