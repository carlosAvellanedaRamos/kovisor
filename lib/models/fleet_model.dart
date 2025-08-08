class Fleet {
  final String geocerca;
  final String? horaLlegada;
  final String placa;

  Fleet({
    required this.geocerca,
    required this.horaLlegada,
    required this.placa,
  });

  factory Fleet.fromJson(Map<String, dynamic> json) {
    return Fleet(
      geocerca: json['geocerca'] ?? '',
      horaLlegada: json['hora_llegada']?.toString(),
      placa: json['placa'] ?? '',
    );
  }
}