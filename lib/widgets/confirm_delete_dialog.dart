import 'package:flutter/material.dart';

Future<bool> confirmDelete(BuildContext context, {required String title, required String message}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton.tonal(
          style: FilledButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return result ?? false;
}
