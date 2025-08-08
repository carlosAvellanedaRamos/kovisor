import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_ws_model.dart';


class SocketService {
  IO.Socket? socket;

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('Token no encontrado');

    socket = IO.io(
      'http://control.kotexi.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    socket!.onConnect((_) {
      print('Conectado con ID: ${socket!.id}');
      socket!.emit('subscribe', 'kotexi_despacho_database_kovisor_backtracking');
    });

    socket!.on('kovisor', (data) {
      print('Datos recibidos: $data');
      // Aquí puedes manejar los datos recibidos
    });

    socket!.onConnectError((err) {
      print('Error de conexión: $err');
    });
  }

  void disconnect() {
    socket?.disconnect();
  }
}

class VehiclesWSProvider extends ChangeNotifier {
  List<DeviceWS> prevDevices = [];
  List<DeviceWS> nextDevices = [];
  DeviceWSAux? currentDevice;

  IO.Socket? _socket;

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    _socket = IO.io(
      'http://control.kotexi.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('subscribe', 'kotexi_despacho_database_kovisor_backtracking');
    });

    _socket!.on('kovisor', (data) {
      prevDevices = (data['prevDevice'] as List)
          .map((e) => DeviceWS.fromJson(e))
          .toList();
      nextDevices = (data['nextDevice'] as List)
          .map((e) => DeviceWS.fromJson(e))
          .toList();
      currentDevice = DeviceWSAux.fromJson(data['currentDevice']);
      notifyListeners();
    });
  }

  void disconnect() {
    _socket?.disconnect();
  }
}