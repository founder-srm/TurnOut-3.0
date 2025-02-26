import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turnout/Screens/attendance.dart';
import 'package:turnout/Screens/scanner.dart';
import 'package:turnout/Screens/about.dart'; // Add this import
import 'Components/bottomNavbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['EXPO_PUBLIC_SUPABASE_URL']!,
    anonKey: dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TurnOut-3.0',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = const ScannerScreen();
        break;
      case 1:
        currentScreen = const AttendanceScreen();
        break;
      case 2:
        currentScreen = const AboutPage();
        break;
      default:
        currentScreen = const ScannerScreen();
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavbar(
        onTabChanged: _handleTabChange,
      ),
    );
  }
}
