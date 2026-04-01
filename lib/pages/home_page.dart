import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_monitor/services/esp_manager.dart';
import 'package:network_monitor/pages/sensor_dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home_Page extends StatefulWidget {
  Home_Page({super.key});

  @override
  State<Home_Page> createState() => _Home_PageState();
}

class _Home_PageState extends State<Home_Page> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  // ✅ Singleton сервіси
  final EspManager _espManager = EspManager();

  // ✅ Статус підключення
  bool _isEspConnected = false;

  @override
  void initState() {
    super.initState();

    // Анімації
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);

    // ✅ Завантажити ESP IP та перевірити підключення
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _espManager.loadEspIp();
      _checkEspConnection();
    });
  }

  /// ✅ Перевірити підключення до ESP
  Future<void> _checkEspConnection() async {
    try {
      _isEspConnected = await _espManager.pingEsp();
      setState(() {});
      print('✅ ESP Connection: $_isEspConnected');
      
      // Якщо не підключено, спробуємо ще раз через 5 секунд
      if (!_isEspConnected) {
        await Future.delayed(const Duration(seconds: 5));
        _isEspConnected = await _espManager.pingEsp();
        setState(() {});
        print('✅ ESP Connection (retry): $_isEspConnected');
      }
    } catch (e) {
      _isEspConnected = false;
      setState(() {});
      print('❌ ESP Connection failed: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              // ✅ Header
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sensor Monitor',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ ESP32 Animation
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardSize =
                          constraints.maxWidth *
                          0.75; // ✅ 75% від ширини екрану
                      return Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: Tween<double>(
                                begin: 1.0,
                                end: 1.15,
                              ).transform(_pulseController.value),
                              child: Container(
                                width: cardSize,
                                height: cardSize * 1.14, // ✅ Відносна висота
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF1D4ED8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF3B82F6).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: Esp32Painter(),
                                      ),
                                    ),

                                    // Status Badge
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: AnimatedBuilder(
                                        animation: _bounceController,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              0,
                                              -10 *
                                                  (1 - _bounceController.value),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _isEspConnected
                                                    ? Colors.green.withOpacity(
                                                        0.9,
                                                      )
                                                    : Colors.red.withOpacity(
                                                        0.9,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    _isEspConnected
                                                        ? 'CONNECTED'
                                                        : 'DISCONNECTED',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
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
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 32),
                sliver: SliverToBoxAdapter(child: SizedBox()),
              ),

              // ✅ ESP Settings Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _EspSettingsCard(
                    espManager: _espManager,
                    isConnected: _isEspConnected,
                    onCheckConnection: _checkEspConnection,
                  ),
                ),
              ),

              // ✅ Sensor Dashboard Button
              if (_isEspConnected)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SensorDashboardPage(
                                deviceIp: _espManager.ip,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.sensors, size: 20),
                        label: Text(
                          'Open Sensor Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ✅ Manual Refresh Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkEspConnection,
                      icon: Icon(Icons.refresh, size: 20),
                      label: Text(
                        'Refresh Connection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ Додатковий простір внизу
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 100),
                sliver: SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ ESP Settings Card Widget (відносні розміри)
class _EspSettingsCard extends StatefulWidget {
  final EspManager espManager;
  final bool isConnected;
  final VoidCallback onCheckConnection;

  const _EspSettingsCard({
    required this.espManager,
    required this.isConnected,
    required this.onCheckConnection,
  });

  @override
  State<_EspSettingsCard> createState() => _EspSettingsCardState();
}

class _EspSettingsCardState extends State<_EspSettingsCard> {
  late TextEditingController _ipController;
  bool _isLoading = false;
  String? _currentIp;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _loadCurrentIp();
  }

  Future<void> _loadCurrentIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('ESP_IP') ?? 'esp.local';

      if (mounted) {
        setState(() {
          _currentIp = ip;
          _ipController.text = ip;
        });
      }
    } catch (e) {
      print('Error loading IP: $e');
    }
  }

  Future<void> _saveNewIp() async {
    if (_ipController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await widget.espManager.saveEspIp(_ipController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ IP збережено: ${_ipController.text}')),
        );
        widget.onCheckConnection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateIp(String? value) {
    if (value == null || value.isEmpty) return 'Введіть IP адресу';
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    if (!ipRegex.hasMatch(value)) return 'Невірний формат IP';
    return null;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              constraints.maxWidth * 0.06,
            ), // ✅ Відносний padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    Icon(Icons.settings, color: Colors.deepPurple, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ESP32 Налаштування',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Current IP & Status
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isConnected
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isConnected ? Colors.green : Colors.red,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: widget.isConnected ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Поточний IP:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _currentIp ?? 'Завантажується...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.isConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: widget.onCheckConnection,
                        icon: Icon(Icons.refresh, size: 16),
                        label: Text('Check'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // New IP Field
                TextFormField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'New IP',
                    prefixIcon: Icon(Icons.edit, color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _validateIp,
                  enabled: !_isLoading,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),

                SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveNewIp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Зберігаємо...',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Text(
                            'ЗМІНИТИ IP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter для ESP32
class Esp32Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(size.width * 0.2, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.3);
    path.lineTo(size.width * 0.85, size.height * 0.4);
    path.lineTo(size.width * 0.85, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.75);
    path.lineTo(size.width * 0.2, size.height * 0.75);
    path.lineTo(size.width * 0.15, size.height * 0.7);
    path.lineTo(size.width * 0.15, size.height * 0.4);
    path.close();

    path.moveTo(size.width * 0.1, size.height * 0.35);
    path.lineTo(size.width * 0.05, size.height * 0.25);
    path.lineTo(size.width * 0.08, size.height * 0.25);

    path.moveTo(size.width * 0.9, size.height * 0.35);
    path.lineTo(size.width * 0.95, size.height * 0.25);
    path.lineTo(size.width * 0.92, size.height * 0.25);

    canvas.drawPath(path, paint);

    final ledPaint = Paint()..color = Colors.green.withOpacity(0.8);
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.4),
      4,
      ledPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.4),
      4,
      ledPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
