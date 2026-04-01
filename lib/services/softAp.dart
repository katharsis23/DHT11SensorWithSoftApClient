import "dart:convert";
import "dart:typed_data";
import "package:http/http.dart" as http;

const String base_IP = "192.168.4.1";
const int base_port = 80;

class SoftAp {
  final String base_url;

  SoftAp({String? ip}) : base_url = "http://${ip ?? base_IP}:$base_port";

  /// Check if connected to ESP32
  Future<bool> isConnected() async {
    try {
      print('[SoftAP] Checking connection to $base_url...');

      final response = await http
          .get(
            Uri.parse("$base_url/proto-ver"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      final connected = response.statusCode == 200;
      print(
        '[SoftAP] Connection check: ${connected ? "✓ OK" : "✗ FAILED"} (${response.statusCode})',
      );

      if (connected && response.body.isNotEmpty) {
        print('[SoftAP] Response: ${response.body}');
      }

      return connected;
    } catch (e) {
      print('[SoftAP] Connection error: $e');
      return false;
    }
  }

  /// Get protocol version
  Future<Map<String, dynamic>?> getProtoVersion() async {
    try {
      print('[SoftAP] Getting protocol version...');

      final response = await http
          .get(
            Uri.parse('$base_url/proto-ver'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[SoftAP] Protocol version: $data');
        return data;
      }

      print('[SoftAP] Proto version request failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[SoftAP] Proto version error: $e');
      return null;
    }
  }

  /// Send WiFi credentials to ESP32
  Future<ProvisioningResult> sendWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    try {
      print('[SoftAP] ========== PROVISIONING START ==========');
      print('[SoftAP] Target SSID: $ssid');
      print('[SoftAP] Password length: ${password.length}');

      // Step 1: Send WiFi config (JSON format)
      print('[SoftAP] Step 1: Sending credentials...');

      final configPayload = jsonEncode({'ssid': ssid, 'password': password});

      print('[SoftAP] Payload: $configPayload');

      final configResponse = await http
          .post(
            Uri.parse('$base_url/prov-config'),
            headers: {'Content-Type': 'application/json'},
            body: configPayload,
          )
          .timeout(const Duration(seconds: 10));

      print('[SoftAP] Config response: ${configResponse.statusCode}');

      if (configResponse.body.isNotEmpty) {
        print('[SoftAP] Response body: ${configResponse.body}');
      }

      if (configResponse.statusCode != 200) {
        return ProvisioningResult(
          success: false,
          message: 'Failed to send config: ${configResponse.statusCode}',
        );
      }

      print('[SoftAP] ✓ Step 1 complete: Credentials sent');

      // Step 2: Wait for ESP32 to process and connect
      print('[SoftAP] Step 2: Waiting for ESP32 to connect (5 seconds)...');
      await Future.delayed(const Duration(seconds: 5));

      // Step 3: Check status
      print('[SoftAP] Step 3: Checking connection status...');

      try {
        final statusResponse = await http
            .get(
              Uri.parse('$base_url/prov-ctrl'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 5));

        if (statusResponse.statusCode == 200) {
          final statusData = jsonDecode(statusResponse.body);
          print('[SoftAP] ESP32 status: $statusData');

          if (statusData['status'] == 'connected') {
            print('[SoftAP] ✓ ESP32 connected to WiFi!');
            return ProvisioningResult(
              success: true,
              message:
                  'Provisioning successful! Device IP: ${statusData['ip']}',
              deviceIp: statusData['ip'],
            );
          } else if (statusData['status'] == 'connecting') {
            print('[SoftAP] ESP32 is still connecting...');
            return ProvisioningResult(
              success: true,
              message: 'ESP32 is connecting to WiFi... Please wait 10-15 seconds.',
            );
          }
        }
      } catch (statusError) {
        // ESP32 може вимкнути SoftAP після підключення до WiFi
        // Це нормально!
        print(
          '[SoftAP] Note: Cannot reach ESP32 status (normal - device may have switched networks)',
        );
      }

      print('[SoftAP] ========== PROVISIONING COMPLETE ==========');
      return ProvisioningResult(
        success: true,
        message:
            'Provisioning successful! ESP32 received credentials and is connecting to WiFi...',
      );
    } catch (e) {
      print('[SoftAP] ✗ Provisioning error: $e');
      return ProvisioningResult(success: false, message: 'Error: $e');
    }
  }

  /// Scan available WiFi networks
  Future<List<WifiNetwork>> scanNetworks() async {
    try {
      print('[SoftAP] Scanning WiFi networks...');

      final response = await http
          .post(
            Uri.parse('$base_url/prov-scan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 20));

      print('[SoftAP] Scan response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[SoftAP] Scan data: $data');

        List<WifiNetwork> networks = [];

        if (data['ap_list'] != null && data['ap_list'] is List) {
          for (var network in data['ap_list']) {
            networks.add(
              WifiNetwork(
                ssid: network['ssid'] ?? 'Unknown',
                rssi: network['rssi'] ?? 0,
                security: network['auth'] ?? 0,
              ),
            );
          }
        }

        print('[SoftAP] ✓ Found ${networks.length} networks');
        return networks;
      }

      print('[SoftAP] Scan failed: ${response.statusCode}');
      return [];
    } catch (e) {
      print('[SoftAP] Scan error: $e');
      return [];
    }
  }

  /// Get list of available WiFi networks (helper method)
  Future<void> debugScanNetworks() async {
    print('\n[DEBUG] === Available WiFi Networks ===');

    final networks = await scanNetworks();

    if (networks.isEmpty) {
      print('[DEBUG] No networks found');
      return;
    }

    for (var net in networks) {
      final securityType = _getSecurityType(net.security);
      print(
        '[DEBUG] ${net.ssid} | Signal: ${net.rssi}dBm | Security: $securityType',
      );
    }

    print('[DEBUG] ====================================\n');
  }

  /// Helper: Get security type name
  String _getSecurityType(int authMode) {
    switch (authMode) {
      case 0:
        return 'Open';
      case 1:
        return 'WEP';
      case 2:
        return 'WPA';
      case 3:
        return 'WPA2';
      case 4:
        return 'WPA3';
      default:
        return 'Unknown';
    }
  }
}

/// WiFi network data model
class WifiNetwork {
  final String ssid;
  final int rssi;
  final int security;

  WifiNetwork({required this.ssid, required this.rssi, required this.security});

  @override
  String toString() => 'WiFi: $ssid (RSSI: $rssi dBm, Security: $security)';
}

/// Provisioning result data model
class ProvisioningResult {
  final bool success;
  final String message;
  final String? deviceIp;

  ProvisioningResult({
    required this.success,
    required this.message,
    this.deviceIp,
  });

  @override
  String toString() =>
      'Result: success=$success, message=$message, ip=$deviceIp';
}