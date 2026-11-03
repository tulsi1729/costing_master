import 'dart:async';

import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/client/widgets/client_avatar.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adds a client, or edits [client]. Pops with the saved [Client].
class ClientFormScreen extends ConsumerStatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  late final _name = TextEditingController(text: widget.client?.name);
  late final _phone = TextEditingController(text: widget.client?.phone);
  late final _city = TextEditingController(text: widget.client?.city);
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.client == null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'નામ લખો · Enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final client = await ref.read(clientsProvider.notifier).save(
            name: _name.text,
            phone: _phone.text,
            city: _city.text,
            existing: widget.client,
          );
      unawaited(HapticFeedback.lightImpact());
      if (mounted) Navigator.pop(context, client);
    } on DuplicateClientException {
      setState(() => _error = 'આ નામે વેપારી પહેલેથી છે · Already exists');
    } catch (_) {
      setState(() => _error = 'સેવ ન થયું · Could not save');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'નવો વેપારી' : 'વેપારી સુધારો')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: ValueListenableBuilder(
              valueListenable: _name,
              builder: (_, value, __) =>
                  ClientAvatar(name: value.text, radius: 40),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            autofocus: _isNew,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'વેપારીનું નામ *',
              hintText: 'Trader or shop name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: const InputDecoration(
              labelText: 'ફોન (વૈકલ્પિક)',
              hintText: 'For WhatsApp · Optional',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'શહેર (વૈકલ્પિક)',
              hintText: 'City · Optional',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ફોન નંબર હશે તો વેપારીને એક ટેપમાં WhatsApp કરી શકશો.',
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        // Stays just above the keyboard while typing.
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.check_rounded),
            label: const Text('સેવ કરો'),
          ),
        ),
      ),
    );
  }
}
