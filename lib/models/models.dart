export 'scan_result.dart';
export 'scan_history.dart';
flutter/services.dart';
import 'ui/screens/scan_screen.dart';
import 'ui/screens/results_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runate(const AthenaApp());
}

class AthenaApp extends StatelessWidget {
  const AthenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1A1A2E),
          error: Color(0xFFEF4444),
          success: Color(0xFF10B981),
          warning: Color(0xFFF59E0B),
        ),
      ),
      home: const ScanScreen(),
    );
  }
}
