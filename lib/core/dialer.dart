import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> callNumber(BuildContext context, String number) async {
  final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: digits);
  bool launched = false;
  try {
    launched = await launchUrl(uri);
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Não foi possível abrir o discador para $number')),
    );
  }
}
