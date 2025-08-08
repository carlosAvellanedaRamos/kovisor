class Parade {
  final String nombre;

  Parade({required this.nombre});

  factory Parade.fromJson(Map<String, dynamic> json) {
    return Parade(
      nombre: json['nombre'],
    );
  }
}