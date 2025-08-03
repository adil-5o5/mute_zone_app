// lib/widgets/edit_zone_dialog.dart
import 'package:flutter/material.dart';
import '../models/mute_zone.dart';

class EditZoneDialog extends StatefulWidget {
  final MuteZone zone;
  final Function(MuteZone) onSave;

  const EditZoneDialog({super.key, required this.zone, required this.onSave});

  @override
  State<EditZoneDialog> createState() => _EditZoneDialogState();
}

class _EditZoneDialogState extends State<EditZoneDialog> {
  final _nameController = TextEditingController();
  final _radiusController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.zone.name;
    _radiusController.text = widget.zone.radius.toString();
    _isActive = widget.zone.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Mute Zone'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Zone Name'),
          ),
          TextField(
            controller: _radiusController,
            decoration: const InputDecoration(labelText: 'Radius (meters)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? true;
                  });
                },
              ),
              const Text('Active'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text;
            final radius = double.tryParse(_radiusController.text) ?? 50.0;
            if (name.isNotEmpty) {
              final updatedZone = widget.zone.copyWith(
                name: name,
                radius: radius,
                isActive: _isActive,
              );
              widget.onSave(updatedZone);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}