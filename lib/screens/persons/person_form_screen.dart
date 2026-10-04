import 'package:flutter/material.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/person.dart';
import '../../services/person_service.dart';

class PersonFormScreen extends StatefulWidget {
  const PersonFormScreen({super.key, this.person, this.initialName});

  final Person? person;

  final String? initialName;

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _personService = sl<PersonService>();
  bool _saving = false;

  bool get _isEditing => widget.person != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? widget.initialName ?? '');
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
      final person = Person(name: _nameController.text.trim());
      final saved = _isEditing
          ? await _personService.update(widget.person!.id!, person)
          : await _personService.create(person);
      if (mounted) Navigator.pop(context, saved);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar cliente' : 'Novo cliente')),
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
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
