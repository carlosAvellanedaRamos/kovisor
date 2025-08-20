import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/authService.dart';
import '../../api/socketService.dart';
import 'ParadeListWidget.dart';
import 'ActualFleetWidget.dart';
import 'VehiclesWidget.dart';
import '../../api/userService.dart';
import 'UserInfoDialog.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  final void Function()? onLogout;
  const Home({super.key, this.onLogout});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  void initState() {
    super.initState();
    // Asegurar que las barras del sistema estén configuradas correctamente
    _configureSystemUI();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0093e8), // Color que coincida con el AppBar
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  void _logout() async {
    try {
      print('Iniciando proceso de logout...');

      // 1. Cerrar sesión en el servidor y limpiar datos locales
      await AuthService.logout();

      // 2. Desconectar WebSocket
      final wsProvider = Provider.of<VehiclesWSProvider>(context, listen: false);
      await wsProvider.disconnect();
      print('WebSocket desconectado');

      // 3. Pausa para asegurar que todo se limpie
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Notificar al widget padre
      if (widget.onLogout != null) {
        widget.onLogout!();
      }

    } catch (e) {
      print('Error en logout: $e');
      // Aún así ejecutar logout
      if (widget.onLogout != null) {
        widget.onLogout!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0093e8),
          statusBarIconBrightness: Brightness.light,
        ),
        title: Row(
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              height: 36,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Finalizar sesión',
            onPressed: _logout,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () async {
                try {
                  final userData = await UserService.fetchUser();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => UserInfoDialog(userData: userData),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true, // Importante: protege contra la barra de navegación
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: ParadeListWidget()),
              Expanded(child: ActualFleetWidget()),
              Expanded(child: VehiclesWidget()),
            ],
          ),
        ),
      ),
    );
  }
}