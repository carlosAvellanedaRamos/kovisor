import 'route_detail_model.dart';

class DeviceWS {
  final String name;
  final double timeDifference;
  final String? departureTime;
  final int? order;

  DeviceWS({
    required this.name,
    required this.timeDifference,
    this.departureTime,
    this.order,
  });

  factory DeviceWS.fromJson(Map<String, dynamic> json) {
    return DeviceWS(
      name: json['name'] ?? '',
      timeDifference: (json['timeDifference'] ?? 0).toDouble(),
      departureTime: json['departureTime'],
      order: json['order'],
    );
  }
}

class DeviceWSAux {
  final String name;
  final String? currentGeofence;
  final String? route;
  final String? departureTime;
  final List<RouteDetail> routeDetails;
  final bool tripStarted;    // Nuevo campo
  final bool tripCompleted;  // Nuevo campo

  DeviceWSAux({
    required this.name,
    this.currentGeofence,
    this.route,
    this.departureTime,
    this.routeDetails = const [],
    this.tripStarted = false,    // Valor por defecto
    this.tripCompleted = false,  // Valor por defecto
  });

  factory DeviceWSAux.fromJson(Map<String, dynamic> json) {
    return DeviceWSAux(
      name: json['name'] ?? '',
      currentGeofence: json['currentGeofence'],
      route: json['route'],
      departureTime: json['departureTime'],
      routeDetails: (json['routeDetails'] as List<dynamic>?)
          ?.map((e) => RouteDetail.fromJson(e))
          .toList() ??
          [],
      tripStarted: json['tripStarted'] == true,    // Parsear booleano
      tripCompleted: json['tripCompleted'] == true, // Parsear booleano
    );
  }
}