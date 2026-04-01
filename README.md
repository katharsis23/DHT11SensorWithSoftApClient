# DHT11 Sensor Monitor with SoftAP Provisioning

A Flutter application designed to monitor DHT11/DHT22 sensor data from an ESP32 device. It includes a built-in "SoftAP Provisioning" flow to connect the ESP32 to your local WiFi network.

##  How it Works

1. **Provisioning Mode**: The ESP32 starts as a Soft Access Point (WiFi network: `ESP32_PROV`). The app connects to this network and sends your home WiFi credentials (SSID and Password) to the ESP32.
2. **Station Mode**: Once configured, the ESP32 connects to your home WiFi.
3. **Monitoring**: The app then communicates with the ESP32 over the local network via HTTP GET requests to fetch real-time temperature, humidity, and device status.

## Installation

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable version)
* Dart SDK (included with Flutter)
* Android Studio / Xcode (for mobile development)

### Setup

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd sensor_collector
   ```

2. **Install dependencies**:

   ```bash
   flutter pub get
   ```

3. **Run the application**:

   * **Android/iOS**: Connect your device or start an emulator and run:

     ```bash
     flutter run
     ```

   * **Desktop (Linux/Windows/macOS)**:

     ```bash
     flutter run -d linux # or windows/macos
     ```

##  File Structure

```text
sensor_collector/
├── android/          # Android specific files
├── ios/              # iOS specific files
├── linux/            # Linux specific files
├── windows/          # Windows specific files
├── macos/            # macOS specific files
├── web/              # Web specific files
├── lib/              # Core application logic (Dart)
│   ├── pages/        # UI Screens
│   ├── services/     # API and Business Logic
│   └── shared_widgets/# Reusable UI components
├── test/             # Unit and Widget tests
├── pubspec.yaml      # Project dependencies and assets
└── README.md         # This file
```

##  Library (`lib/`) Specification

### `lib/pages/`

* `get_credential_page.dart`: The initial screen for WiFi provisioning. Connects to `ESP32_PROV` and sends credentials.
* `home_page.dart`: Main dashboard overview and ESP32 connection management.
* `sensor_dashboard_page.dart`: Detailed view of sensor data (Temperature, Humidity) with real-time updates.

### `lib/services/`

* `softAp.dart`: Handles low-level communication with the ESP32 during provisioning mode (sending SSID/Password).
* `sensor_api_service.dart`: The main HTTP client for fetching sensor data (`/sensors`, `/device`, etc.) once the ESP32 is on the network.
* `esp_manager.dart`: Manages the lifecycle of the ESP32 connection, including IP discovery and health checks (ping).

### `lib/shared_widgets/`

* `bottom_bar.dart`: Reusable navigation component used across different screens.

##  Specifications

* **ESP32 Default Network**: `ESP32_PROV`
* **Provisioning Protocol**: Custom HTTP/JSON over SoftAP.
* **Sensor Support**: DHT11, DHT22.
* **API Endpoints**:
  * `GET /sensors`: Returns all sensor data in JSON.
  * `GET /device`: Returns device metadata (uptime, firmware version, IP).
  * `GET /hello`: Connection health check.