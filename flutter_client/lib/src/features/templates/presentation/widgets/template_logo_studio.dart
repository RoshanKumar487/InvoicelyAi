import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';

class TemplateLogoStudioCard extends StatelessWidget {
  const TemplateLogoStudioCard({
    super.key,
    required this.logoWidget,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemoveLogo,
  });

  final Widget? logoWidget;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onRemoveLogo;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Business Logo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Shown in invoice header when added',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (logoWidget != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  logoWidget!,
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onPickGallery,
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Change Logo'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: onPickCamera,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onRemoveLogo,
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 6),
                  const Text(
                    'No logo attached to this template yet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: onPickGallery,
                        icon: const Icon(Icons.photo_library, size: 17),
                        label: const Text('Upload Gallery'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: onPickCamera,
                        icon: const Icon(Icons.camera_alt, size: 17),
                        label: const Text('Take Photo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
