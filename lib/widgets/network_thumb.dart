import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/skeleton.dart';
import 'package:flutter/material.dart';

/// A network image decoded at display size (not full resolution), with a
/// skeleton while loading and a fade-in once the first frame arrives.
/// Photos not yet backed up ([LocalImages] refs) are read from the phone.
class NetworkThumb extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const NetworkThumb({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty || url == 'null') return _placeholder(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? (constraints.maxWidth * dpr).round()
              : null;
          final ImageProvider source = LocalImages.isLocal(url)
              ? FileImage(LocalImages.file(url)) as ImageProvider
              : NetworkImage(url);
          return Image(
            image: ResizeImage.resizeIfNeeded(
                fit == BoxFit.cover ? width : null, null, source),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSyncLoaded) {
              if (wasSyncLoaded) return child;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (frame == null) Skeleton(borderRadius: borderRadius),
                  AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: child,
                  ),
                ],
              );
            },
            errorBuilder: (context, _, __) => _placeholder(context),
          );
        },
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.image_outlined,
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      );
}
