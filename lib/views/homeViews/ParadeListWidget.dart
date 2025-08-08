import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/socketService.dart';

class ParadeListWidget extends StatelessWidget {
  const ParadeListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehiclesWSProvider>(
      builder: (context, wsProvider, _) {
        final device = wsProvider.currentDevice;
        final paraderos = device?.routeDetails ?? [];
        return Card(
          margin: const EdgeInsets.all(16),
          child: SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Subida', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: paraderos.isEmpty
                      ? const Center(child: Text('Sin paraderos'))
                      : ListView.builder(
                    itemCount: paraderos.length,
                    itemBuilder: (context, index) {
                      final parada = paraderos[index];
                      return ListTile(
                        title: Text(parada.geofenceName),
                        subtitle: Text('Programado: ${parada.scheduled}'),
                        trailing: parada.entered
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.access_time, color: Colors.grey),
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