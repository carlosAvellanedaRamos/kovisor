import 'route_detail_model.dart';

class DeviceWS {
  final String name;
  final double timeDifference;

  DeviceWS({required this.name, required this.timeDifference});

  factory DeviceWS.fromJson(Map<String, dynamic> json) {
    return DeviceWS(
      name: json['name'] ?? '',
      timeDifference: (json['timeDifference'] ?? 0).toDouble(),
    );
  }
}

class DeviceWSAux {
  final String name;
  final String? currentGeofence;
  final String? route;
  final String? departureTime;
  final List<RouteDetail> routeDetails;

  DeviceWSAux({
    required this.name,
    this.currentGeofence,
    this.route,
    this.departureTime,
    this.routeDetails = const [],
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
    );
  }
}