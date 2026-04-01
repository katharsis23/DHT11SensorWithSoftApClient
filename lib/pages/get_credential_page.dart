import 'package:flutter/material.dart';
import 'package:network_monitor/services/softAp.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetCredentialPage extends StatefulWidget {
  const GetCredentialPage({super.key});

  @override
  State<GetCredentialPage> createState() => _GetCredentialPageState();
}

class _GetCredentialPageState extends State<GetCredentialPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isConnectedToESP = false;

  @override
  void initState() {
    super.initState();
    _checkESPConnection();
  }

  Future<void> _checkESPConnection() async {
    final softAp = SoftAp();

    print('[Debug] Trying to connect to ESP32...');

    try {
      final connected = await softAp.isConnected();
      print('[Debug] Connection result: $connected');

      setState(() {
        _isConnectedToESP = connected;
      });

      if (connected) {
        print('[Debug] Successfully connected to ESP32!');

        // Спробуйте отримати версію протоколу
        final version = await softAp.getProtoVersion();
        print('[Debug] Protocol version: $version');
      } else {
        print('[Debug] Failed to connect to ESP32');
      }
    } catch (e) {
      print('[Debug] Error: $e');
      setState(() {
        _isConnectedToESP = false;
      });
    }
  }

  void _showConnectionWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please connect to ESP32_PROV WiFi network in device settings',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Відправити credentials на ESP32
  Future<void> _submitCredentials() async {
    // Валідація форми
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Перевірка підключення до ESP32
    if (!_isConnectedToESP) {
      _showConnectionWarning();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final softAp = SoftAp();

      // Надіслати credentials
      final result = await softAp.sendWifiCredentials(
        ssid: _ssidController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      // Показати результат
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        // Якщо успішно, перейти на домашню сторінку
        if (result.success) {
          // Показуємо повідомлення про успішне provisioning
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Provisioning successful! ESP32 is connecting to WiFi...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Зберігаємо IP для подальшого використання
          if (result.deviceIp != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ESP_IP', result.deviceIp!);
            print('[Debug] Saved ESP IP: ${result.deviceIp}');
          }

          // Завжди переходимо на домашню сторінку після успішного provisioning
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/chat');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("WiFi Credentials"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Статус підключення
              Card(
                color: _isConnectedToESP
                    ? Colors.green[100]
                    : Colors.orange[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        _isConnectedToESP ? Icons.wifi : Icons.wifi_off,
                        color: _isConnectedToESP ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isConnectedToESP
                              ? 'Connected to ESP32'
                              : 'Not connected to ESP32_PROV',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _checkESPConnection,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // SSID поле
              const Text(
                "Network SSID",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  hintText: 'Enter WiFi network name',
                  prefixIcon: Icon(Icons.wifi),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter network SSID';
                  }
                  if (value.length < 2) {
                    return 'SSID is too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              // Password поле
              const Text(
                "Password",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter WiFi password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitCredentials(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),

              // Submit кнопка
              ElevatedButton(
                onPressed: _isLoading ? null : _submitCredentials,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send Credentials',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Інструкції
              Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Instructions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('1. Connect to ESP32_PROV WiFi network'),
                      Text('2. Enter your home WiFi credentials'),
                      Text('3. Click "Send Credentials"'),
                      Text('4. ESP32 will connect to your WiFi'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}