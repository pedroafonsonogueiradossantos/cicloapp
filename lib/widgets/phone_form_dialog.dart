import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../models/phone.dart';
import '../services/phone_service.dart';

Future<bool> showPhoneFormDialog(BuildContext context, {required String personId, Phone? phone}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _PhoneFormDialog(personId: personId, phone: phone),
  ).then((v) => v ?? false);
}

class _PhoneFormDialog extends StatefulWidget {
  const _PhoneFormDialog({required this.personId, this.phone});

  final String personId;
  final Phone? phone;

  @override
  State<_PhoneFormDialog> createState() => _PhoneFormDialogState();
}

class _PhoneFormDialogState extends State<_PhoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  final _phoneService = PhoneService();
  late PhoneType _type;
  bool _saving = false;

  bool get _isEditing => widget.phone != null;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.phone?.number ?? '');
    _type = widget.phone?.type ?? PhoneType.mobile;
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final phone = Phone(personId: widget.personId, number: _number.text.trim(), type: _type);
      if (_isEditing) {
        await _phoneService.update(widget.phone!.id!, phone);
      } else {
        await _phoneService.create(phone);
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
    return AlertDialog(
      title: Text(_isEditing ? 'Editar telefone' : 'Novo telefone'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Número'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o número' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PhoneType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: PhoneType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? PhoneType.mobile),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
