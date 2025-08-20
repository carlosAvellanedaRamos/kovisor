import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/loginViews/Login.dart';
import 'views/homeViews/Home.dart';
import 'package:provider/provider.dart';
import 'api/socketService.dart';
import 'api/authService.dart';
import 'api/sessionService.dart';
import 'api/userService.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Barra de estado transparente
    statusBarIconBrightness: Brightness.light, // Iconos claros
    systemNavigationBarColor: Colors.black, // Barra de navegación negra
    systemNavigationBarIconBrightness: Brightness.light, // Iconos claros
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge, // Permite que la app use toda la pantalla
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => VehiclesWSProvider(),
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
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  /// Verifica si hay una sesión válida al iniciar la app
  void _checkExistingSession() async {
    try {
      print('Verificando sesión existente...');

      // Verificar si hay una sesión válida
      final hasValidSession = await AuthService.hasValidSession();

      if (hasValidSession) {
        print('Sesión válida encontrada');

        // Obtener datos de sesión
        final sessionData = await SessionService.getSessionData();

        if (sessionData != null) {
          // Restaurar WebSocket automáticamente
          await _restoreWebSocketConnection(sessionData);

          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });

          print('Sesión restaurada exitosamente');
          return;
        }
      }

      print('No hay sesión válida');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });

    } catch (e) {
      print('Error verificando sesión: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  /// Restaura la conexión WebSocket con datos de sesión
  Future<void> _restoreWebSocketConnection(SessionData sessionData) async {
    try {
      print('Restaurando conexión WebSocket...');

      final wsProvider = Provider.of<VehiclesWSProvider>(context, listen: false);

      // Configurar provider con datos guardados
      wsProvider.setPlate(sessionData.plate);
      wsProvider.setDeviceName(sessionData.deviceName);

      // Intentar conectar WebSocket
      if (sessionData.userId != null && sessionData.deviceName != null) {
        await wsProvider.connect(
          userId: sessionData.userId!,
          deviceName: sessionData.deviceName!,
        );

        print('WebSocket restaurado exitosamente');
      }

    } catch (e) {
      print('Error restaurando WebSocket: $e');
      // No es crítico si falla la conexión WebSocket,
      // el usuario aún puede usar la app
    }
  }

  /// Maneja el login exitoso
  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  /// Maneja el logout
  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kovisor',
      debugShowCheckedModeBanner: false, // Remover banner de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0656C5),
          primary: const Color(0xFF0093e8),
          secondary: const Color(0xFF0691C4),
        ),
        useMaterial3: true,
      ),

      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: _isLoading
          ? const SplashScreen()
          : _isLoggedIn
          ? Home(onLogout: _onLogout)
          : LoginPage(onLoginSuccess: _onLoginSuccess),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0093e8),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/images/logo.png',
                width: 240,
                height: 120,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verificando sesión...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}