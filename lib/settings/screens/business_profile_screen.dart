import 'dart:async';

import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/settings/widgets/settings_widgets.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Business name, logo and contact details printed at the top of quotes.
/// Every change is saved on its own; there is no save button.
class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'બિઝનેસ પ્રોફાઇલ',
      body: (settings) => _ProfileForm(initial: settings.profile),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final BusinessProfile initial;
  const _ProfileForm({required this.initial});

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  // Kept so pending edits can still be saved from dispose(), where ref is gone.
  late final SettingsNotifier _notifier = ref.read(settingsProvider.notifier);
  late BusinessProfile _profile = widget.initial;
  late final _business = TextEditingController(text: _profile.businessName);
  late final _owner = TextEditingController(text: _profile.ownerName);
  late final _phone = TextEditingController(text: _profile.phone);
  late final _city = TextEditingController(text: _profile.city);
  late final _tagline = TextEditingController(text: _profile.tagline);
  Timer? _debounce;
  bool _savingLogo = false;

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      final profile = _profileFromFields();
      final notifier = _notifier;
      // Saved after unmount completes; listeners must not rebuild mid-dispose.
      scheduleMicrotask(() => notifier
          .edit((s) => s.copyWith(profile: profile, profilePrompted: true))
          .catchError((Object _) {}));
    }
    for (final c in [_business, _owner, _phone, _city, _tagline]) {
      c.dispose();
    }
    super.dispose();
  }

  BusinessProfile _profileFromFields() => _profile.copyWith(
        businessName: _business.text.trim(),
        ownerName: _owner.text.trim(),
        phone: _phone.text.trim(),
        city: _city.text.trim(),
        tagline: _tagline.text.trim(),
      );

  void _onChanged(String _) {
    setState(() => _profile = _profileFromFields());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _flush);
  }

  void _flush() {
    final profile = _profileFromFields();
    if (!mapEquals(profile.toMap(), _notifier.current.profile.toMap())) {
      _save(profile);
    }
  }

  void _save(BusinessProfile profile) => saveSettings(context, _notifier,
      (s) => s.copyWith(profile: profile, profilePrompted: true));

  Future<void> _pickLogo() async {
    final storage = ref.read(imageStorageProvider);
    final file = await storage.pick(fromCamera: false, maxWidth: 512);
    if (file == null || !mounted) return;
    setState(() => _savingLogo = true);
    try {
      final logo = await LocalImages.save(
          file, 'logo_${DateTime.now().millisecondsSinceEpoch}');
      setState(() => _profile = _profileFromFields().copyWith(logoUrl: logo));
      _save(_profile);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'લોગો સેવ ન થયો', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _savingLogo = false);
    }
  }

  void _removeLogo() {
    setState(() => _profile = _profileFromFields().copyWith(logoUrl: ''));
    _save(_profile);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: InkWell(
            onTap: _savingLogo ? null : _pickLogo,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: context.colors.primaryContainer,
              child: _savingLogo
                  ? const CircularProgressIndicator()
                  : _profile.logoUrl.isEmpty
                      ? Icon(Icons.add_photo_alternate_outlined,
                          size: 32, color: context.colors.onPrimaryContainer)
                      : ClipOval(
                          child: SizedBox.square(
                            dimension: 96,
                            child: NetworkThumb(url: _profile.logoUrl),
                          ),
                        ),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: _profile.logoUrl.isEmpty ? _pickLogo : _removeLogo,
            child: Text(_profile.logoUrl.isEmpty
                ? 'લોગો ઉમેરો · Add logo'
                : 'લોગો કાઢો · Remove logo'),
          ),
        ),
        const SectionTitle('બિઝનેસ', 'Shown at the top of every quote'),
        SettingsField(_business, 'બિઝનેસનું નામ', 'Business name', _onChanged),
        const SizedBox(height: 12),
        SettingsField(
            _tagline, 'ટેગલાઇન', 'e.g. હેન્ડવર્ક સ્પેશિયાલિસ્ટ', _onChanged),
        const SectionTitle('સંપર્ક', 'Contact'),
        SettingsField(_owner, 'માલિકનું નામ', 'Owner name', _onChanged),
        const SizedBox(height: 12),
        SettingsField(_phone, 'ફોન', 'Phone', _onChanged,
            keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        SettingsField(_city, 'શહેર', 'City', _onChanged),
      ],
    );
  }
}
