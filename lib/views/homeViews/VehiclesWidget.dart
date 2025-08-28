import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/socketService.dart';
import '../../models/device_ws_model.dart';
import '../../models/kovisor_colors.dart';

class VehiclesWidget extends StatefulWidget {
  const VehiclesWidget({super.key});

  @override
  State<VehiclesWidget> createState() => _VehiclesWidgetState();
}

class _VehiclesWidgetState extends State<VehiclesWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<VehiclesWSProvider>(
      builder: (context, wsProvider, child) {
        // No lógicas de alerta aquí, solo renderizado UI!
        if (wsProvider.specialMessage != null) {
          return Card(
            color: KovisorColors.fondoOscuro,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 260,
              height: 240,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: KovisorColors.naranja, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      wsProvider.specialMessage!,
                      style: TextStyle(
                        color: KovisorColors.rojo,
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

        final sortedNextDevices = List<DeviceWS>.from(wsProvider.nextDevices);
        sortedNextDevices.sort((a, b) => b.timeDifference.compareTo(a.timeDifference));
        final sortedPrevDevices = wsProvider.prevDevices;

        Color getVehicleColor(double timeDifference) {
          if (timeDifference <= 1) return KovisorColors.purpuraAlerta;
          if (timeDifference > 1 && timeDifference <= 3) return KovisorColors.naranja;
          if (timeDifference > 3) return KovisorColors.verde;
          return KovisorColors.grisClaro;
        }

        Color getTextColor(double timeDifference) {
          if (timeDifference <= 1) return KovisorColors.purpuraAlerta;
          if (timeDifference > 1 && timeDifference <= 3) return KovisorColors.naranja;
          if (timeDifference > 3) return KovisorColors.verde;
          return KovisorColors.grisClaro;
        }

        return Card(
          color: KovisorColors.fondoOscuro,
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
                    Text(
                      'VEHÍCULOS - PLACA(MIN)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: KovisorColors.azulClaro,
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
                              color: KovisorColors.verde,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Conectado',
                              style: TextStyle(
                                fontSize: 10,
                                color: KovisorColors.verde,
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
                          Text(
                            'Delante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: KovisorColors.blanco,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: KovisorColors.azulClaro.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sortedNextDevices.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: KovisorColors.azulClaro,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: sortedNextDevices.isEmpty
                            ? Center(
                          child: Text(
                            'Sin flotas por delante',
                            style: TextStyle(
                              color: KovisorColors.grisClaro,
                              fontSize: 12,
                            ),
                          ),
                        )
                            : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sortedNextDevices.length,
                          itemBuilder: (context, index) {
                            final device = sortedNextDevices[index];
                            final color = getVehicleColor(device.timeDifference);
                            final textColor = getTextColor(device.timeDifference);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      device.name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "(${device.timeDifference.toStringAsFixed(1)} min)",
                                      style: TextStyle(
                                        color: color,
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
                        KovisorColors.grisClaro.withOpacity(0.3),
                        KovisorColors.azulClaro.withOpacity(0.5),
                        KovisorColors.grisClaro.withOpacity(0.3),
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
                          Text(
                            'Atrás',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: KovisorColors.blanco,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: KovisorColors.naranja.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sortedPrevDevices.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: KovisorColors.naranja,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: sortedPrevDevices.isEmpty
                            ? Center(
                          child: Text(
                            'Sin flotas por detrás',
                            style: TextStyle(
                              color: KovisorColors.grisClaro,
                              fontSize: 12,
                            ),
                          ),
                        )
                            : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sortedPrevDevices.length,
                          itemBuilder: (context, index) {
                            final device = sortedPrevDevices[index];
                            final color = getVehicleColor(device.timeDifference);
                            final textColor = getTextColor(device.timeDifference);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      device.name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "(${device.timeDifference.toStringAsFixed(1)} min)",
                                      style: TextStyle(
                                        color: color,
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