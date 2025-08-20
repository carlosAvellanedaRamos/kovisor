import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../api/authService.dart';
import '../../api/sessionService.dart';
import '../../api/socketService.dart';
import '../../api/userService.dart';

class LoginPage extends StatefulWidget {
  final void Function() onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Configurar UI del sistema para pantalla de login
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0093e8),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final wsProvider = Provider.of<VehiclesWSProvider>(context, listen: false);

      // 1. Desconectar completamente cualquier conexión anterior
      print('Desconectando conexión anterior...');
      await wsProvider.disconnect();

      // 2. Hacer login y obtener token
      print('Iniciando sesión...');
      final token = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );

      // 3. Obtener datos del usuario
      print('Obteniendo datos del usuario...');

      // Guardar token temporalmente para poder hacer la petición
      await SessionService.updateToken(token);

      final userData = await UserService.fetchUser();

      // 4. Guardar sesión completa
      await SessionService.saveSession(
        token: token,
        userData: userData,
      );

      // Extraer datos necesarios
      final plate = userData['user_device']?['plate'] as String?;
      final userId = userData['user_device']?['user_id']?.toString();
      final deviceName = userData['user_device']?['name'] as String?;

      print('Datos extraídos correctamente:');
      print('   - User ID: $userId');
      print('   - Device Name: $deviceName');
      print('   - Plate: $plate');
      print('   - Token: ${token.substring(0, 20)}...');

      if (userId == null || deviceName == null) {
        throw Exception('Datos de usuario incompletos');
      }

      // 5. Configurar el provider
      wsProvider.setPlate(plate);
      wsProvider.setDeviceName(deviceName);

      print('Provider configurado con placa: $plate y device: $deviceName');

      // 6. Pausa para que el backend procese el login
      await Future.delayed(const Duration(milliseconds: 1200));

      // 7. Conectar WebSocket
      print('Conectando WebSocket para user_id: $userId, device: $deviceName...');
      await wsProvider.connect(userId: userId, deviceName: deviceName);

      print('Login y conexión completados exitosamente');
      widget.onLoginSuccess();

    } catch (e) {
      print('Error en login: $e');

      // Limpiar sesión si hay error
      await SessionService.clearSession();

      setState(() {
        _error = "Ocurrió un error: ${e.toString().contains('Error de autenticación') ? 'Credenciales incorrectas' : e.toString()}";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0093e8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'lib/assets/images/logo.png',
                  width: 200,
                  height: 100,
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: SizedBox(
                        width: 320,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Iniciar sesión", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: "Correo electrónico"),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                              value != null && value.contains("@") ? null : "Correo inválido",
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(labelText: "Contraseña"),
                              obscureText: true,
                              validator: (value) =>
                              value != null && value.isNotEmpty ? null : "La contraseña es obligatoria",
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0656C5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _loading
                                    ? null
                                    : () {
                                  if (_formKey.currentState!.validate()) {
                                    _login();
                                  }
                                },
                                child: _loading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                    : const Text("Entrar"),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}