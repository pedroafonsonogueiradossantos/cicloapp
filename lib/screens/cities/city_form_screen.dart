import 'package:flutter/material.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/city.dart';
import '../../services/city_service.dart';

class CityFormScreen extends StatefulWidget {
  const CityFormScreen({super.key, this.city});

  final City? city;

  @override
  State<CityFormScreen> createState() => _CityFormScreenState();
}

class _CityFormScreenState extends State<CityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _cityService = sl<CityService>();
  bool _saving = false;

  bool get _isEditing => widget.city != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.city?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final city = City(name: _nameController.text.trim());
      if (_isEditing) {
        await _cityService.update(widget.city!.id!, city);
      } else {
        await _cityService.create(city);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar cidade' : 'Nova cidade')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                autofocus: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
