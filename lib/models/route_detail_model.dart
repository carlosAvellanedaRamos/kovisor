class RouteDetail {
  final String geofenceName;
  final String scheduled;
  final String? eventTime;
  final int minutesLate;
  final bool entered;

  RouteDetail({
    required this.geofenceName,
    required this.scheduled,
    this.eventTime,
    required this.minutesLate,
    required this.entered,
  });

  factory RouteDetail.fromJson(Map<String, dynamic> json) {
    return RouteDetail(
      geofenceName: json['geofence_name'] ?? '',
      scheduled: json['scheduled'] ?? '',
      eventTime: json['event_time'],
      minutesLate: json['minutes_late'] ?? 0,
      entered: json['entered'] ?? false,
    );
  }
}