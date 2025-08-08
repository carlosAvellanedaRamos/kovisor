import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/loginViews/Login.dart';
import 'views/homeViews/Home.dart';
import 'package:provider/provider.dart';
import 'api/socketService.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => VehiclesWSProvider()..connect(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kovisor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0656C5),
          primary: const Color(0xFF0093e8),
          secondary: const Color(0xFF0691C4),
        ),
        useMaterial3: true,
      ),
      home: _loggedIn
          ? const Home()
          : LoginPage(onLoginSuccess: () {
        setState(() {
          _loggedIn = true;
        });
      }),
    );
  }
}