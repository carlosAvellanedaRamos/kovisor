import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/socketService.dart';
import 'dart:async';

class ActualFleetWidget extends StatefulWidget {
  const ActualFleetWidget({super.key});

  @override
  State<ActualFleetWidget> createState() => _ActualFleetWidgetState();
}

class _ActualFleetWidgetState extends State<ActualFleetWidget> {
  late Timer _timer;
  String _currentTime = "";
  String _timeFormat = "AM";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      _timeFormat = now.hour >= 12 ? "PM" : "AM";
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getCurrentGeofenceTime(device) {
    final currentGeofence = device.currentGeofence;
    final routeDetails = device.routeDetails ?? [];

    if (currentGeofence != null && routeDetails.isNotEmpty) {
      for (var routeDetail in routeDetails) {
        if (routeDetail.geofenceName == currentGeofence) {
          if (routeDetail.eventTime != null && routeDetail.eventTime!.isNotEmpty) {
            return _formatTime(routeDetail.eventTime!);
          } else if (routeDetail.scheduled.isNotEmpty) {
            return _formatTime(routeDetail.scheduled);
          }
        }
      }
    }
    final fallbackTime = device.departureTime;
    if (fallbackTime != null && fallbackTime.isNotEmpty) {
      return fallbackTime;
    }
    return "";
  }

  String _formatTime(String timeString) {
    try {
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          return "${parts[0]}:${parts[1]}";
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehiclesWSProvider>(
      builder: (context, wsProvider, _) {
        // SOLO mostrar Card de advertencia si hay mensaje especial
        if (wsProvider.specialMessage != null) {
          return Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: SizedBox(
              width: 260,
              height: 240,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      wsProvider.specialMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Si NO hay mensaje especial, sigue la lógica normal
        final device = wsProvider.currentDevice;
        final plate = wsProvider.plate ?? "";

        if (device == null) {
          return Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const SizedBox(
              width: 260,
              height: 240,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Conectando...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final currentGeofenceTime = _getCurrentGeofenceTime(device);

        return Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            width: 260,
            height: 240,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        "FLOTA ACTUAL ${device.name}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentTime,
                              style: const TextStyle(
                                fontSize: 32,
                                color: Color(0xFF8A98A9),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              _timeFormat,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFF8A98A9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "($plate)",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.currentGeofence ?? "Sin ubicación",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (currentGeofenceTime.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          currentGeofenceTime,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}