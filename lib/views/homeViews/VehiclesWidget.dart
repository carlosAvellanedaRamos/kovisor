import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/socketService.dart';
import '../../models/device_ws_model.dart';

class VehiclesWidget extends StatelessWidget {
  const VehiclesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehiclesWSProvider>(
      builder: (context, wsProvider, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'VEHÍCULOS - PLACA(MIN)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Delante',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: wsProvider.nextDevices.isEmpty
                      ? const Center(child: Text('Sin flotas por delante'))
                      : ListView.builder(
                    itemCount: wsProvider.nextDevices.length,
                    itemBuilder: (context, index) {
                      final device = wsProvider.nextDevices[index];
                      return Row(
                        children: [
                          Text(
                            "${device.name}",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${device.timeDifference.toStringAsFixed(1)} min)",
                            style: const TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 30),
                const Text(
                  'Atrás',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: wsProvider.prevDevices.isEmpty
                      ? const Center(child: Text('Sin flotas por detrás'))
                      : ListView.builder(
                    itemCount: wsProvider.prevDevices.length,
                    itemBuilder: (context, index) {
                      final device = wsProvider.prevDevices[index];
                      return Row(
                        children: [
                          Text(
                            "${device.name}",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${device.timeDifference.toStringAsFixed(1)} min)",
                            style: const TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}