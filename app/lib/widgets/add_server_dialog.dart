import 'dart:math';
import 'package:flutter/material.dart';
import '../models/server.dart';

/// Dialog for adding a new server to monitor.
class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key});

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '9100');
  final _tokenController = TextEditingController();
  DateTime? _expireDate;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final server = Server(
      id: _generateId(),
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      token: _tokenController.text.trim(),
      expireDate: _expireDate,
    );

    Navigator.pop(context, server);
  }

  String _generateId() {
    final rand = Random();
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
        rand.nextInt(99999).toRadixString(36);
  }

  Future<void> _pickExpireDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expireDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _expireDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Server'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. My VPS',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host / IP',
                  hintText: 'e.g. 192.168.1.100 or myserver.com',
                  prefixIcon: Icon(Icons.dns),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '9100',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final port = int.tryParse(v.trim());
                  if (port == null || port < 1 || port > 65535) return 'Invalid port';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Auth Token (optional)',
                  hintText: 'Leave empty if no auth',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(_expireDate == null
                    ? 'Set expiration date (optional)'
                    : 'Expires: ${_expireDate!.year}-${_expireDate!.month.toString().padLeft(2, '0')}-${_expireDate!.day.toString().padLeft(2, '0')}'),
                trailing: _expireDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expireDate = null),
                      )
                    : null,
                onTap: _pickExpireDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
