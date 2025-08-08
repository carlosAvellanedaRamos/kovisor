import 'package:flutter/material.dart';

class UserInfoDialog extends StatelessWidget {
  final Map<String, dynamic> userData;
  const UserInfoDialog({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final user = userData;
    final device = user['user_device'] ?? {};
    return AlertDialog(
      title: const Text('Datos del usuario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nombre: ${user['name'] ?? ''}'),
          Text('Email: ${user['email'] ?? ''}'),
          const SizedBox(height: 8),
          Text('Placa: ${device['plate'] ?? ''}'),
          Text('Compañía: ${device['company'] ?? ''}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}