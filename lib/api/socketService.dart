import 'package:http/http.dart' as http;
import 'package:kotexi_app/api/tts_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/device_ws_model.dart';
import 'dart:async';
import 'dart:math';

class KovisorWebSocketService extends ChangeNotifier {
  // Estado de los dispositivos
  List<DeviceWS> prevDevices = [];
  List<DeviceWS> nextDevices = [];
  DeviceWSAux? currentDevice;

  // Nueva variable para mensaje especial
  String? specialMessage;

  // Información del usuario
  String? plate;
  String? _currentUserId;
  String? _currentToken;
  String? _currentDeviceName;

  // Configuración del WebSocket
  IO.Socket? _socket;
  bool _isConnecting = false;
  bool _isConnected = false;
  Timer? _connectionTimeout;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 8);
  static const Duration _disconnectDelay = Duration(seconds: 3);

  // Control de conexiones y actualizaciones
  static bool _globalConnectionLock = false;
  DateTime? _lastDisconnectTime;
  DateTime? _lastDataUpdate;

  // Getters públicos
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String? get deviceName => _currentDeviceName;

  bool? _previousTripStarted;
  bool? _previousTripCompleted;
  String? _lastAnnouncedGeofence;

  bool _isVoiceAlertActive = false;
  Timer? _voiceAlertTimer;

  void emitVoiceAlert(String message) {
    TTSService.speak(message);
    _isVoiceAlertActive = true;
    notifyListeners();
    _voiceAlertTimer?.cancel();
    _voiceAlertTimer = Timer(const Duration(seconds: 2), () {
      _isVoiceAlertActive = false;
      notifyListeners();
    });
  }

  bool get isVoiceAlertActive => _isVoiceAlertActive;


  void _showTripNotification(String message) {
    // Voz
    TTSService.speak(message);

    // Visual
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('iniciado') ? Colors.green : Colors.blue,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _announceGeofence(String geofence) {
    if (geofence.isNotEmpty) {
      final msg = "Ingresando a $geofence";
      TTSService.speak(msg);
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.indigo,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Establece la placa del vehículo
  void setPlate(String? plateValue) {
    print('Configurando placa: $plateValue');
    plate = plateValue;
    notifyListeners();
  }

  /// Establece el nombre del dispositivo
  void setDeviceName(String? deviceName) {
    print('Configurando device name: $deviceName');
    _currentDeviceName = deviceName;
    notifyListeners();
  }

  /// Limpia el estado interno
  void _clearState() {
    prevDevices = [];
    nextDevices = [];
    currentDevice = null;
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _lastDataUpdate = null;
    _cancelTimers();
    notifyListeners();
  }

  /// Cancela todos los timers activos
  void _cancelTimers() {
    _connectionTimeout?.cancel();
    _connectionTimeout = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Espera el tiempo necesario desde la última desconexión
  Future<void> _waitForCleanDisconnect() async {
    if (_lastDisconnectTime != null) {
      final timeSinceDisconnect = DateTime.now().difference(_lastDisconnectTime!);
      if (timeSinceDisconnect < _disconnectDelay) {
        final waitTime = _disconnectDelay - timeSinceDisconnect;
        print('Esperando ${waitTime.inMilliseconds}ms desde última desconexión');
        await Future.delayed(waitTime);
      }
    }
  }

  /// Verifica que el servidor esté disponible antes de conectar
  Future<bool> _checkServerAvailability() async {
    try {
      print('🔍 Verificando disponibilidad del servidor...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        print('❌ Token no disponible para verificación');
        return false;
      }

      final response = await http.get(
        Uri.parse('http://control.kotexi.com/api/mobile/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Servidor disponible y token válido');
        return true;
      } else {
        print('Servidor respondió con código: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error verificando servidor: $e');
      return false;
    }
  }

  /// Conecta al WebSocket de Kovisor
  Future<void> connect({String? userId, String? deviceName}) async {
    if (_isConnecting) {
      print('Ya se está conectando, abortando...');
      return;
    }

    if (_globalConnectionLock) {
      print('Conexión bloqueada globalmente, esperando...');
      await Future.delayed(const Duration(seconds: 2));
    }

    _globalConnectionLock = true;
    _isConnecting = true;

    print('Iniciando conexión WebSocket');
    print('    Usuario: $userId');
    print('    Device: $deviceName');
    print('    Timestamp: ${DateTime.now().toIso8601String()}');

    try {
      // 1. Esperar tiempo desde última desconexión
      await _waitForCleanDisconnect();

      // 2. Verificar disponibilidad del servidor
      final serverAvailable = await _checkServerAvailability();
      if (!serverAvailable) {
        throw Exception('Servidor no disponible o token inválido');
      }

      // 3. Desconexión completa y forzada
      await _forceCompleteDisconnect();

      // 4. Pausa adicional para asegurar limpieza del servidor
      await Future.delayed(const Duration(seconds: 2));

      // 5. Obtener token fresco
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('Token JWT no encontrado');
      }

      // 6. Configurar variables de estado
      _currentUserId = userId;
      _currentToken = token;
      _currentDeviceName = deviceName;

      print('Token validado: ${token.substring(0, 20)}...');

      // 7. Crear conexión WebSocket con configuración muy robusta
      print('Creando socket con configuración robusta...');
      _socket = IO.io(
        'http://control.kotexi.com',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': 'Bearer $token'})
            .setTimeout(30000) // 30 segundos timeout
            .enableForceNewConnection()
            .disableAutoConnect() // Control manual de conexión
            .build(),
      );

      // 8. Configurar event listeners ANTES de conectar
      _setupSocketListeners();

      // 9. Conectar manualmente
      print('Iniciando conexión manual...');
      _socket!.connect();

      // 10. Timeout de conexión extendido
      _connectionTimeout = Timer(const Duration(seconds: 35), () {
        if (!_isConnected) {
          print('Timeout: Conexión no establecida en 35 segundos');
          _handleConnectionFailure();
        }
      });

      print('Socket creado y conectando...');

    } catch (e) {
      print('Error en connect: $e');
      _handleConnectionFailure();
      rethrow;
    } finally {
      _isConnecting = false;
      _globalConnectionLock = false;
    }
  }

  /// Obtiene el token JWT válido con validación
  Future<String?> _getValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        print('Token no válido o vacío');
        return null;
      }

      // Verificar formato básico del token
      if (!token.contains('|')) {
        print('Formato de token inválido');
        return null;
      }

      print('Token válido obtenido y verificado');
      return token;
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }

  /// Configura los event listeners del WebSocket
  void _setupSocketListeners() {
    if (_socket == null) return;

    print('Configurando listeners del WebSocket...');

    // Evento: Conexión exitosa
    _socket!.onConnect((_) {
      print('WebSocket conectado exitosamente!');
      print('Socket ID: ${_socket!.id}');
      print('Tiempo de conexión: ${DateTime.now().toIso8601String()}');

      _isConnected = true;
      _reconnectAttempts = 0;
      _cancelTimers();

      // Suscribirse al canal según la documentación
      _socket!.emit('subscribe', 'kotexi_despacho_database_kovisor_backtracking');
      print('Suscripción enviada al canal: kotexi_despacho_database_kovisor_backtracking');

      // Iniciar heartbeat
      _startHeartbeat();

      notifyListeners();
    });

    _socket!.on('kovisor', (data) {
      if (_socket != null && _isConnected) {
        print('Datos recibidos para usuario $_currentUserId');
        _processKovisorData(data);
      }
    });

    // Evento: Desconexión
    _socket!.onDisconnect((reason) {
      print('WebSocket desconectado: $reason');
      print('Tiempo de desconexión: ${DateTime.now().toIso8601String()}');

      _isConnected = false;
      _lastDisconnectTime = DateTime.now();
      _cancelTimers();
      notifyListeners();

      // Solo reconectar para desconexiones no intencionales
      if (reason != 'io client disconnect' &&
          reason != 'client namespace disconnect' &&
          reason != 'transport close' &&
          _reconnectAttempts < _maxReconnectAttempts) {
        print('Programando reconexión automática...');
        _scheduleReconnect();
      } else {
        print('No se reintentará reconexión. Razón: $reason');
      }
    });

    // Evento: Error de conexión
    _socket!.onConnectError((error) {
      print('Error de conexión WebSocket: $error');
      print('Tiempo de error: ${DateTime.now().toIso8601String()}');

      // Detectar errores de autenticación
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('authentication') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('401') ||
          errorStr.contains('403')) {
        print('Error de autenticación - no se reintentará');
        _isConnected = false;
        _isConnecting = false;
        _cancelTimers();
        notifyListeners();
      } else {
        _handleConnectionFailure();
      }
    });

    // Eventos de diagnóstico
    _socket!.on('connecting', (_) {
      print('WebSocket intentando conectar...');
    });

    _socket!.on('connect_timeout', (_) {
      print('Timeout durante conexión WebSocket');
    });

    _socket!.on('error', (error) {
      print('Error general WebSocket: $error');
    });

    _socket!.on('reconnect', (attempt) {
      print('Reconexión automática #$attempt');
    });
  }

  /// Inicia el sistema de heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_socket != null && _isConnected) {
        _socket!.emit('ping');
        print('Heartbeat enviado');

        // Verificar estado actual y forzar mensaje si es necesario
        bool noData = currentDevice == null && prevDevices.isEmpty && nextDevices.isEmpty;
        if (noData && specialMessage == null) {
          specialMessage = "Vehículo no programado";
          print('HEARTBEAT: Forzando mensaje especial por datos vacíos');
        }

        // Siempre notificar en heartbeat
        notifyListeners();
      }
    });
  }

  /// Procesa los datos recibidos del evento 'kovisor'
  void _processKovisorData(dynamic data) {
    try {
      // Imprimir los datos en bruto para debug
      print('DATOS RAW: ${data.runtimeType} - ${data.toString().substring(0, min(data.toString().length, 100))}...');

      // 1. PRIMERA PRIORIDAD: Detectar mensaje especial directo
      if (data is Map && data.containsKey('message')) {
        specialMessage = data['message']?.toString();
        prevDevices = [];
        nextDevices = [];
        currentDevice = null;
        print('MENSAJE ESPECIAL detectado: "$specialMessage"');
        notifyListeners();
        return;
      }

      // 2. SEGUNDA PRIORIDAD: Verificar si tenemos datos vacíos (arrays/objetos vacíos)
      bool hasEmptyData = false;

      if (data is Map) {
        bool emptyPrev = data['prevDevice'] is List && (data['prevDevice'] as List).isEmpty;
        bool emptyNext = data['nextDevice'] is List && (data['nextDevice'] as List).isEmpty;
        bool emptyCurrent = data['currentDevice'] == null ||
            (data['currentDevice'] is Map && (data['currentDevice'] as Map).isEmpty);

        if (emptyPrev && emptyNext && emptyCurrent) {
          hasEmptyData = true;
          print('Detectados objetos/arrays VACÍOS en los datos');
        }
      }

      // 3. SI NO HAY DATOS REALES: Forzar mensaje especial
      if (hasEmptyData) {
        specialMessage = "Vehículo no programado";
        prevDevices = [];
        nextDevices = [];
        currentDevice = null;
        print('FORZANDO mensaje especial porque los datos están vacíos');
        notifyListeners();
        return;
      }

      if (specialMessage == null && nextDevices.isNotEmpty) {
        final minNextTime = nextDevices[0].timeDifference;
        if (minNextTime <= 1) {
          emitVoiceAlert("Está muy cerca del primer vehículo, mantenga su distancia.");
        }
      }
      if (specialMessage == null && prevDevices.isNotEmpty) {
        final minPrevTime = prevDevices[0].timeDifference;
        if (minPrevTime <= 1) {
          emitVoiceAlert("Avance, el vehículo de atrás está muy cerca.");
        }
      }

      // 4. SI HAY DATOS REALES: Procesar normalmente
      try {
        // Limpiar mensaje especial si hay datos reales
        specialMessage = null;

        // Procesamiento normal de datos...
        if (data is Map) {
          // Procesar prevDevices y nextDevices (intercambiados según comentarios)
          if (data['nextDevice'] is List) {
            prevDevices = (data['nextDevice'] as List)
                .map((e) => DeviceWS.fromJson(e))
                .toList();
          } else {
            prevDevices = [];
          }

          if (data['prevDevice'] is List) {
            nextDevices = (data['prevDevice'] as List)
                .map((e) => DeviceWS.fromJson(e))
                .toList();
          } else {
            nextDevices = [];
          }

          // Procesar currentDevice
          if (data['currentDevice'] != null && data['currentDevice'] is Map) {
            final deviceData = data['currentDevice'];
            final deviceName = deviceData['name']?.toString();

            if (deviceName == _currentDeviceName) {
              currentDevice = DeviceWSAux.fromJson(deviceData);
              print('currentDevice actualizado: ${currentDevice?.name}');

              // --- ANUNCIO DE PARADERO ---
              final newGeofence = currentDevice?.currentGeofence;
              if (newGeofence != null && newGeofence.isNotEmpty && newGeofence != _lastAnnouncedGeofence) {
                _announceGeofence(newGeofence);
                _lastAnnouncedGeofence = newGeofence;
              }
            }
          } else {
            currentDevice = null;
          }

          _lastDataUpdate = DateTime.now();
          print('Datos procesados: ${prevDevices.length} atrás, ${nextDevices.length} adelante');
          notifyListeners();
        }
      } catch (e) {
        print('Error procesando datos: $e');
        print('Stack: ${StackTrace.current}');
      }

    } catch (e) {
      print('ERROR CRÍTICO: $e');
      // En caso de error grave, forzar mensaje especial como fallback
      specialMessage = "Vehículo no programado";
      prevDevices = [];
      nextDevices = [];
      currentDevice = null;
      notifyListeners();
    }

    // --- ANUNCIO DE INICIO/FIN DE VIAJE ---
    if (data is Map && data['currentDevice'] != null && data['currentDevice'] is Map) {
      final deviceData = data['currentDevice'] as Map;
      final newTripStarted = deviceData['tripStarted'] == true;
      final newTripCompleted = deviceData['tripCompleted'] == true;

      // Detecta cambio de inicio de viaje (de false a true)
      if (_previousTripStarted == false && newTripStarted == true) {
        _showTripNotification("Se ha iniciado el viaje");
      }
      // Detecta cambio de fin de viaje (de false a true)
      if (_previousTripCompleted == false && newTripCompleted == true) {
        _showTripNotification("Viaje finalizado");
      }
      // Actualiza los valores previos
      _previousTripStarted = newTripStarted;
      _previousTripCompleted = newTripCompleted;
    }
  }

  /// Verifica si los datos han cambiado de manera más precisa
  bool _hasDataChanged(List<DeviceWS> newPrev, List<DeviceWS> newNext, DeviceWSAux? newCurrent) {
    // Verificar cambios en el número de dispositivos
    if (prevDevices.length != newPrev.length || nextDevices.length != newNext.length) {
      print('Cambio detectado: Diferente número de dispositivos');
      print('   - Prev: ${prevDevices.length} -> ${newPrev.length}');
      print('   - Next: ${nextDevices.length} -> ${newNext.length}');
      return true;
    }

    // Verificar cambios en currentDevice
    if (currentDevice?.name != newCurrent?.name ||
        currentDevice?.currentGeofence != newCurrent?.currentGeofence ||
        currentDevice?.departureTime != newCurrent?.departureTime) {
      print('Cambio detectado: Información de dispositivo actual');
      return true;
    }

    // Verificar cambios detallados en dispositivos previos (atrás)
    for (int i = 0; i < prevDevices.length; i++) {
      if (i < newPrev.length) {
        final currentDevice = prevDevices[i];
        final newDevice = newPrev[i];

        if (currentDevice.name != newDevice.name ||
            (currentDevice.timeDifference - newDevice.timeDifference).abs() > 0.01) {
          print('Cambio detectado: Dispositivo atrás ${currentDevice.name}');
          print('   - TimeDifference: ${currentDevice.timeDifference} -> ${newDevice.timeDifference}');
          return true;
        }
      }
    }

    // Verificar cambios detallados en dispositivos siguientes (adelante)
    for (int i = 0; i < nextDevices.length; i++) {
      if (i < newNext.length) {
        final currentDevice = nextDevices[i];
        final newDevice = newNext[i];

        if (currentDevice.name != newDevice.name ||
            (currentDevice.timeDifference - newDevice.timeDifference).abs() > 0.01) {
          print('Cambio detectado: Dispositivo adelante ${currentDevice.name}');
          print('   - TimeDifference: ${currentDevice.timeDifference} -> ${newDevice.timeDifference}');
          return true;
        }
      }
    }

    return false;
  }

  /// Fuerza una actualización manual del UI
  void forceUpdate() {
    print('Forzando actualización manual del UI');
    _lastDataUpdate = DateTime.now();
    notifyListeners();
  }

  /// Obtiene información de debug sobre el estado actual
  Map<String, dynamic> getDebugInfo() {
    return {
      'isConnected': _isConnected,
      'lastDataUpdate': _lastDataUpdate?.toIso8601String(),
      'prevDevicesCount': prevDevices.length,
      'nextDevicesCount': nextDevices.length,
      'currentDevice': currentDevice?.name,
      'socketId': _socket?.id,
      'prevDevicesDetails': prevDevices.map((d) => '${d.name}: ${d.timeDifference}min').toList(),
      'nextDevicesDetails': nextDevices.map((d) => '${d.name}: ${d.timeDifference}min').toList(),
    };
  }

  /// Maneja fallos de conexión
  void _handleConnectionFailure() {
    print('Manejando fallo de conexión...');
    _isConnected = false;
    _isConnecting = false;
    _lastDisconnectTime = DateTime.now();
    _cancelTimers();
    notifyListeners();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      print('Máximo número de intentos de reconexión alcanzado');
      _globalConnectionLock = false;
    }
  }

  /// Programa un intento de reconexión
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectDelay.inSeconds * _reconnectAttempts);

    print('Programando reconexión (intento $_reconnectAttempts/$_maxReconnectAttempts) en ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () {
      if (_currentUserId != null && _currentDeviceName != null) {
        print('Ejecutando reconexión...');
        connect(userId: _currentUserId, deviceName: _currentDeviceName);
      }
    });
  }

  /// Desconexión completa y forzada
  Future<void> _forceCompleteDisconnect() async {
    print('Ejecutando desconexión completa y forzada...');

    _cancelTimers();

    if (_socket != null) {
      try {
        print('Limpiando listeners...');
        _socket!.clearListeners();

        print('Desconectando socket...');
        _socket!.disconnect();

        print('Cerrando socket...');
        _socket!.close();

        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        print('Error en desconexión forzada: $e');
      } finally {
        _socket = null;
      }
    }

    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _lastDisconnectTime = DateTime.now();

    print('Desconexión completa finalizada');
  }

  /// Desconecta completamente el servicio
  Future<void> disconnect() async {
    print('Desconectando servicio completo para usuario $_currentUserId');

    await _forceCompleteDisconnect();

    _clearState();
    _currentUserId = null;
    _currentToken = null;
    _currentDeviceName = null;
    plate = null;
    _globalConnectionLock = false;

    print('Servicio completamente desconectado');
  }

  /// Reconecta manualmente
  Future<void> reconnect() async {
    if (_currentUserId != null && _currentDeviceName != null) {
      print('Reconexión manual solicitada');
      _reconnectAttempts = 0; // Reset counter for manual reconnect
      await connect(userId: _currentUserId, deviceName: _currentDeviceName);
    }
  }

  /// Verifica el estado de conexión
  void checkConnection() {
    print('=== ESTADO DE CONEXIÓN ===');
    print('   - Conectado: $_isConnected');
    print('   - Conectando: $_isConnecting');
    print('   - Socket ID: ${_socket?.id ?? "null"}');
    print('   - Usuario: $_currentUserId');
    print('   - Device: $_currentDeviceName');
    print('   - Intentos reconexión: $_reconnectAttempts');
    print('   - Lock global: $_globalConnectionLock');
    print('   - Última desconexión: $_lastDisconnectTime');
    print('   - Última actualización: $_lastDataUpdate');
    print('========================');
  }

  @override
  void dispose() {
    print('🗑️ Disposing KovisorWebSocketService');
    _forceCompleteDisconnect();
    super.dispose();
  }
}

// Alias para mantener compatibilidad
typedef VehiclesWSProvider = KovisorWebSocketService;