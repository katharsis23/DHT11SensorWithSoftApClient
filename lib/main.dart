import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:network_monitor/pages/get_credential_page.dart';
import 'package:network_monitor/pages/home_page.dart';
import 'package:network_monitor/services/softAp.dart';

final SoftAp softap_client = SoftAp();

void main() {
  const bool debug_mode = !bool.fromEnvironment('dart.vm.product');
  runApp(
    DevicePreview(
      enabled: !debug_mode,
      builder: (context) => NetworkMonitor(debug_mode: debug_mode),
    ),
  );
}

class NetworkMonitor extends StatelessWidget {
  const NetworkMonitor({super.key, required this.debug_mode});
  final bool debug_mode;

  @override
  Widget build(BuildContext context) {
    final String appTitle = debug_mode
        ? "Network Monitor(DEBUG)"
        : "Network Monitor";

    return MaterialApp(
      title: appTitle,
      locale: debug_mode ? DevicePreview.locale(context) : null,
      builder: debug_mode ? DevicePreview.appBuilder : null,
      theme: ThemeData.dark().copyWith(
        // ✅ Глобальна анімація переходів
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomSlideTransitionBuilder(),
            TargetPlatform.iOS: CustomSlideTransitionBuilder(),
            TargetPlatform.macOS: CustomSlideTransitionBuilder(),
            TargetPlatform.windows: CustomSlideTransitionBuilder(),
            TargetPlatform.linux: CustomSlideTransitionBuilder(),
            TargetPlatform.fuchsia: CustomSlideTransitionBuilder(),
          },
        ),
      ),
      home: GetCredentialPage(),
      //home: Home_Page(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/":
            return MaterialPageRoute(builder: (context) => GetCredentialPage());
          case "/chat":
            return MaterialPageRoute(builder: (context) => Home_Page());
        }
      },
    );
  }
}

/// ✅ Кастомний Slide Transition для всіх платформ
class CustomSlideTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Напрямок анімації залежить від напрямку навігації
    final bool isPush = route.animation!.status == AnimationStatus.forward;
    const Offset begin = Offset(1.0, 0.0); // справа наліво (push)
    const Offset reverseBegin = Offset(-1.0, 0.0); // зліва направо (pop)

    final Offset tweenBegin = isPush ? begin : reverseBegin;
    final tween = Tween<Offset>(
      begin: tweenBegin,
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    return SlideTransition(position: animation.drive(tween), child: child);
  }
}