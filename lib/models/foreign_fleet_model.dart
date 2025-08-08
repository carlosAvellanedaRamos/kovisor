class ForeignFleet {
  final String placa;
  final int diferenciaMinutos;

  ForeignFleet({
    required this.placa,
    required this.diferenciaMinutos,
  });

  factory ForeignFleet.fromJson(Map<String, dynamic> json) {
    return ForeignFleet(
      placa: json['placa'],
      diferenciaMinutos: json['diferencia_minutos'],
    );
  }
}