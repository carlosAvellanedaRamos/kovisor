import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/socketService.dart';
import '../../models/kovisor_colors.dart';

class ParadeListWidget extends StatefulWidget {
  const ParadeListWidget({super.key});

  @override
  State<ParadeListWidget> createState() => _ParadeListWidgetState();
}

class _ParadeListWidgetState extends State<ParadeListWidget> {
  final _scrollController = ScrollController();
  String? _lastCurrentGeofence;
  List<dynamic>? _lastParaderos;

  @override
  void initState() {
    super.initState();
    print('ParadeListWidget iniciado');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerCurrentGeofence({bool animated = true}) {
    final wsProvider = Provider.of<VehiclesWSProvider>(context, listen: false);
    final device = wsProvider.currentDevice;
    final paraderos = device?.routeDetails ?? [];
    final currentGeofence = device?.currentGeofence ?? '';

    if (paraderos.isEmpty || currentGeofence.isEmpty) {
      print('No hay datos para centrar la vista');
      return;
    }

    final index = paraderos.indexWhere((p) => p.geofenceName == currentGeofence);

    if (index != -1) {
      print('Centrando en geocerca "$currentGeofence" (índice: $index)');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final itemHeight = 50.0;
          final viewportHeight = _scrollController.position.viewportDimension;
          final totalHeight = paraderos.length * itemHeight;
          final itemPosition = index * itemHeight;
          final centeredOffset = itemPosition - (viewportHeight / 2) + (itemHeight / 2);
          final maxOffset = totalHeight - viewportHeight;
          final targetOffset = centeredOffset.clamp(0.0, maxOffset > 0 ? maxOffset : 0.0);

          if (animated) {
            _scrollController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            );
          } else {
            _scrollController.jumpTo(targetOffset);
          }
        }
      });
    }
  }

  void _checkForRecenter(VehiclesWSProvider wsProvider) {
    final device = wsProvider.currentDevice;
    final paraderos = device?.routeDetails ?? [];
    final currentGeofence = device?.currentGeofence ?? '';

    final geofenceChanged = _lastCurrentGeofence != currentGeofence;
    final paraderosChanged = _lastParaderos?.length != paraderos.length ||
        (_lastParaderos != null && paraderos.isNotEmpty &&
            _lastParaderos![0]?.geofenceName != paraderos[0].geofenceName);

    if (geofenceChanged || paraderosChanged) {
      _lastCurrentGeofence = currentGeofence;
      _lastParaderos = List.from(paraderos);
      _centerCurrentGeofence(animated: true);
    }
  }

  Color getMinutesLateColor(int minutesLate) {
    if (minutesLate > 0) return KovisorColors.rojo;
    if (minutesLate < 0) return KovisorColors.verde;
    return KovisorColors.blanco;
  }

  @override
  Widget build(BuildContext context) {
    print('ParadeListWidget build() ejecutado');
    return Consumer<VehiclesWSProvider>(
      builder: (context, wsProvider, _) {
        if (wsProvider.specialMessage != null) {
          return Card(
            color: KovisorColors.fondoOscuro,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: SizedBox(
              width: 370,
              height: 290,
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

        final device = wsProvider.currentDevice;
        final paraderos = device?.routeDetails ?? [];
        final currentGeofence = device?.currentGeofence ?? '';
        final routeName = device?.route ?? '';

        _checkForRecenter(wsProvider);

        if (_lastCurrentGeofence == null && currentGeofence.isNotEmpty) {
          _lastCurrentGeofence = currentGeofence;
          _lastParaderos = List.from(paraderos);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerCurrentGeofence(animated: false);
          });
        }

        return Card(
          color: KovisorColors.fondoOscuro,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            width: 370,
            height: 290,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 14, left: 16, right: 16, bottom: 8),
                  child: Text(
                    routeName.isNotEmpty ? routeName : 'Cargando ruta...',
                    style: TextStyle(
                      fontSize: 15,
                      color: KovisorColors.azulClaro,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: paraderos.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: KovisorColors.azulClaro),
                        SizedBox(height: 12),
                        Text(
                          'Cargando paraderos...',
                          style: TextStyle(
                            color: KovisorColors.grisClaro,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        print('Scroll position: ${notification.metrics.pixels}');
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                      itemCount: paraderos.length,
                      itemBuilder: (context, index) {
                        final parada = paraderos[index];
                        final isCurrent = parada.geofenceName == currentGeofence;

                        return Container(
                          height: 50.0,
                          margin: const EdgeInsets.only(bottom: 1.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? KovisorColors.azulClaro.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrent
                                ? Border.all(color: KovisorColors.azulClaro, width: 1)
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? KovisorColors.azulClaro
                                      : KovisorColors.naranja,
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                    BoxShadow(
                                      color: KovisorColors.azulClaro.withOpacity(0.5),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  parada.minutesLate.toString(),
                                  style: TextStyle(
                                    color: getMinutesLateColor(parada.minutesLate),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      parada.geofenceName,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? KovisorColors.blanco
                                            : KovisorColors.grisClaro,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (parada.scheduled.isNotEmpty)
                                      Text(
                                        'Programado: ${parada.scheduled}',
                                        style: TextStyle(
                                          color: KovisorColors.azulClaro,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: KovisorColors.verde,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTUAL',
                                    style: TextStyle(
                                      color: KovisorColors.fondoOscuro,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
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