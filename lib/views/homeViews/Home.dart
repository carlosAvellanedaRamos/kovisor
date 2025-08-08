import 'package:flutter/material.dart';
import 'ParadeListWidget.dart';
import 'ActualFleetWidget.dart';
import 'VehiclesWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../loginViews/Login.dart';
import 'package:http/http.dart' as http;
import '../../api/userService.dart';
import 'UserInfoDialog.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      final response = await http.get(
        Uri.parse('http://control.kotexi.com/api/mobile/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      // Puedes manejar el mensaje de respuesta si lo deseas
    }
    await prefs.remove('jwt_token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage(onLoginSuccess: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Home()),
        );
      })),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
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
            icon: const Icon(Icons.logout),
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
                backgroundImage: NetworkImage('https://ejemplo.com/foto_perfil.jpg'),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Expanded(child: ParadeListWidget()),
          Expanded(child: ActualFleetWidget()),
          Expanded(child: VehiclesWidget()),
        ],
      ),
    );
  }
}