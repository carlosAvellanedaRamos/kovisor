import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/socketService.dart';

class ActualFleetWidget extends StatelessWidget {
  const ActualFleetWidget({super.key});

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehiclesWSProvider>(
      builder: (context, wsProvider, _) {
        final device = wsProvider.currentDevice;
        if (device == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Card(
          margin: const EdgeInsets.all(16),
          child: SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Flota actual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hora actual: ${_getCurrentTime()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Placa: ${device.name}', style: const TextStyle(fontSize: 16)),
                  Text('Geocerca: ${device.currentGeofence ?? ""}', style: const TextStyle(fontSize: 16)),
                  Text('Ruta: ${device.route ?? ""}', style: const TextStyle(fontSize: 16)),
                  Text('Hora salida: ${device.departureTime ?? ""}', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}