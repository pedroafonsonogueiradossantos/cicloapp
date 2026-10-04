import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!ok && context.mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_alt_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Ciclo App',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: auth.isLoading ? null : () => _signIn(context),
                    icon: auth.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Entrar com Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
