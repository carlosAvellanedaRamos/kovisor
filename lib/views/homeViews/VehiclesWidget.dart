import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/socketService.dart';
import '../../models/device_ws_model.dart';

class VehiclesWidget extends StatefulWidget {
  const VehiclesWidget({super.key});

  @override
  State<VehiclesWidget> createState() => _VehiclesWidgetState();
}

class _VehiclesWidgetState extends State<VehiclesWidget> {
  @override
  void initState() {
    super.initState();
    print('VehiclesWidget iniciado');
  }

  @override
  Widget build(BuildContext context) {
    print('VehiclesWidget build() ejecutado');
    return Consumer<VehiclesWSProvider>(
      builder: (context, wsProvider, child) {
        // Mostrar mensaje especial si existe
        if (wsProvider.specialMessage != null) {
          return Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
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

        final debugInfo = wsProvider.getDebugInfo();
        print('VehiclesWidget Consumer rebuild:');
        print('   - IsConnected: ${debugInfo['isConnected']}');
        print('   - LastUpdate: ${debugInfo['lastDataUpdate']}');
        print('   - PrevDevices: ${debugInfo['prevDevicesCount']}');
        print('   - NextDevices: ${debugInfo['nextDevicesCount']}');
        print('   - PrevDetails: ${debugInfo['prevDevicesDetails']}');
        print('   - NextDetails: ${debugInfo['nextDevicesDetails']}');

        // Ordenar dispositivos "Delante" por timeDifference DESCENDENTE (mayor a menor)
        final sortedNextDevices = List<DeviceWS>.from(wsProvider.nextDevices);
        sortedNextDevices.sort((a, b) => b.timeDifference.compareTo(a.timeDifference));

        final sortedPrevDevices = wsProvider.prevDevices;

        print('Ordenamiento aplicado:');
        print('   - Delante (ordenado desc): ${sortedNextDevices.map((d) => '${d.name}:${d.timeDifference}min').toList()}');
        print('   - Atrás (orden original): ${sortedPrevDevices.map((d) => '${d.name}:${d.timeDifference}min').toList()}');

        return Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            width: 260,
            height: 240,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    const Text(
                      'VEHÍCULOS - PLACA(MIN)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (wsProvider.isConnected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Conectado',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sección Delante
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Delante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sortedNextDevices.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: sortedNextDevices.isEmpty
                            ? const Center(
                          child: Text(
                            'Sin flotas por delante',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        )
                            : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sortedNextDevices.length,
                          itemBuilder: (context, index) {
                            final device = sortedNextDevices[index];
                            print('Renderizando device adelante (ordenado): ${device.name} - ${device.timeDifference}min');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      device.name,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "(${device.timeDifference.toStringAsFixed(1)} min)",
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                        Colors.grey.shade300,
                      ],
                    ),
                  ),
                ),

                // Sección Atrás
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Atrás',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sortedPrevDevices.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: sortedPrevDevices.isEmpty
                            ? const Center(
                          child: Text(
                            'Sin flotas por detrás',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        )
                            : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sortedPrevDevices.length,
                          itemBuilder: (context, index) {
                            final device = sortedPrevDevices[index];
                            print('Renderizando device atrás (orden original): ${device.name} - ${device.timeDifference}min');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      device.name,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "(${device.timeDifference.toStringAsFixed(1)} min)",
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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