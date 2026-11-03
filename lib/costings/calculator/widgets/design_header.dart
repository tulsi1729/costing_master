import 'dart:io';

import 'package:costing_master/costings/calculator/costing_draft.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Photo, sari name and design number.
class DesignHeader extends ConsumerStatefulWidget {
  final DraftProvider draft;
  final bool showErrors;

  const DesignHeader(
      {super.key, required this.draft, required this.showErrors});

  @override
  ConsumerState<DesignHeader> createState() => _DesignHeaderState();
}

class _DesignHeaderState extends ConsumerState<DesignHeader> {
  late final TextEditingController _name;
  late final TextEditingController _designNo;
  File? _localPreview;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    final costing = ref.read(widget.draft).costing;
    _name = TextEditingController(text: costing.sariName);
    _designNo = TextEditingController(text: costing.designNo?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _designNo.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final hasPhoto = ref.read(widget.draft).hasPhoto;
    final choice = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('કેમેરા'),
              subtitle: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, _PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('ગેલેરી'),
              subtitle: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, _PhotoAction.gallery),
            ),
            if (hasPhoto)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('ફોટો કાઢો'),
                subtitle: const Text('Remove photo'),
                onTap: () => Navigator.pop(context, _PhotoAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final notifier = ref.read(widget.draft.notifier);
    if (choice == _PhotoAction.remove) {
      setState(() => _localPreview = null);
      notifier.setImageUrl('');
      return;
    }

    final storage = ref.read(imageStorageProvider);
    final File? file;
    try {
      file = await storage.pick(fromCamera: choice == _PhotoAction.camera);
    } on PlatformException catch (e) {
      if (mounted) {
        showAppSnack(context, 'ફોટો ખોલી શકાયો નહીં (${e.code})',
            type: SnackType.error);
      }
      return;
    }
    if (file == null || !mounted) return;

    setState(() {
      _localPreview = file;
      _uploadProgress = 0;
    });
    final costing = ref.read(widget.draft).costing;
    try {
      // Kept on the phone; it is uploaded with the costing on backup.
      final photo = await LocalImages.save(
          file, '${costing.guid}_${DateTime.now().millisecondsSinceEpoch}');
      notifier.setImageUrl(photo);
    } catch (_) {
      if (mounted) {
        setState(() => _localPreview = null);
        showAppSnack(
            context, 'ફોટો સેવ ન થયો, ફરી પ્રયત્ન કરો · Could not save photo',
            type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ref.watch(
        widget.draft.select((d) => d.hasPhoto ? d.costing.imageUrl : ''));
    final nameMissing =
        widget.showErrors && ref.watch(widget.draft.select((d) => !d.hasName));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoTile(
              imageUrl: imageUrl,
              localPreview: _localPreview,
              progress: _uploadProgress,
              onTap: _uploadProgress == null ? _choosePhoto : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: ref.read(widget.draft.notifier).setSariName,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'સાડીનું નામ *',
                      hintText: 'Sari name',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      errorText: nameMissing ? 'નામ જરૂરી છે · Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _designNo,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (text) => ref
                        .read(widget.draft.notifier)
                        .setDesignNo(int.tryParse(text)),
                    decoration: const InputDecoration(
                      labelText: 'ડિઝાઇન નંબર',
                      hintText: 'Design no.',
                      prefixText: '# ',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, remove }

class _PhotoTile extends StatelessWidget {
  final String imageUrl;
  final File? localPreview;
  final double? progress;
  final VoidCallback? onTap;

  const _PhotoTile({
    required this.imageUrl,
    required this.localPreview,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final Widget content;
    if (localPreview != null && (progress != null || imageUrl.isEmpty)) {
      content = Image.file(localPreview!, fit: BoxFit.cover, cacheWidth: 300);
    } else if (imageUrl.isNotEmpty) {
      content = NetworkThumb(url: imageUrl);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded,
              size: 30, color: context.colors.primary),
          const SizedBox(height: 6),
          Text(
            'ફોટો',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Text('Optional', style: context.text.labelSmall),
        ],
      );
    }

    return Semantics(
      button: true,
      label: 'Design photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 104,
          height: 132,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: context.colors.primaryContainer.withValues(alpha: 0.35),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: Motion.of(context, Motion.medium),
                  child: KeyedSubtree(
                    key: ValueKey('$imageUrl${localPreview?.path}'),
                    child: content,
                  ),
                ),
                if (progress != null)
                  ColoredBox(
                    color: Colors.black38,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: Motion.fast,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                          value: value == 0 ? null : value,
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  )
                else if (imageUrl.isNotEmpty)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.edit_rounded,
                          size: 15, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
