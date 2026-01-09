import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/public_url.dart';
import '../../../data/models/vendor_public_profile_model.dart';
import '../../../data/models/vendor_review_model.dart';
import '../../providers/vendor_provider.dart';

class PublicVendorDetailsScreen extends StatefulWidget {
  const PublicVendorDetailsScreen({
    super.key,
    required this.vendorUserId,
  });

  final String vendorUserId;

  @override
  State<PublicVendorDetailsScreen> createState() =>
      _PublicVendorDetailsScreenState();
}

class _PublicVendorDetailsScreenState extends State<PublicVendorDetailsScreen> {
  bool _loading = true;
  String? _error;

  VendorPublicProfile? _profile;
  List<VendorReview> _reviews = const <VendorReview>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final vendorProvider = context.read<VendorProvider>();
      final profile =
          await vendorProvider.fetchPublicVendorProfile(widget.vendorUserId);
      final reviews =
          await vendorProvider.fetchVendorReviews(widget.vendorUserId);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _reviews = reviews;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _askQuestion(
      BuildContext context, VendorPublicProfile profile) async {
    final vendorProvider = context.read<VendorProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Soru Sor',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                profile.companyName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Sorunu yaz…',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  child: const Text('Gönder'),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    final question = (result ?? '').trim();
    if (question.isEmpty) return;

    try {
      await vendorProvider.askQuestion(profile.vendorUserId, question);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Sorunuz gönderildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Soru gönderilemedi: $e')),
      );
    }
  }

  Widget _buildStars(ThemeData theme, double? averageRating, int ratingCount) {
    final hasRating = averageRating != null && ratingCount > 0;
    final double normalized = hasRating ? averageRating!.clamp(0, 5) : 0;
    final int full = hasRating ? normalized.floor() : 0;
    final bool half = hasRating && (normalized - full) >= 0.5 && full < 5;

    Widget buildIcon(int index) {
      IconData icon;
      if (!hasRating) {
        icon = Icons.star_border_rounded;
      } else if (index < full) {
        icon = Icons.star_rounded;
      } else if (half && index == full) {
        icon = Icons.star_half_rounded;
      } else {
        icon = Icons.star_border_rounded;
      }
      final color = hasRating
          ? Colors.amber.shade700
          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4);
      return Icon(icon, size: 18, color: color);
    }

    return Row(
      children: [
        for (var i = 0; i < 5; i++) buildIcon(i),
        const SizedBox(width: 6),
        Text(
          hasRating
              ? '${normalized.toStringAsFixed(1)} ($ratingCount)'
              : 'Henüz puan yok',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Üye Mekan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Yüklenemedi: $_error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Mekan bulunamadı.')),
      );
    }

    final photos = profile.photoUrlList;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profile.companyName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                child: photos.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : PageView.builder(
                        itemCount: photos.length > 10 ? 10 : photos.length,
                        itemBuilder: (context, index) {
                          final url = photos[index];
                          return Image.network(
                            normalizePublicUrl(url),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.companyName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      _buildStars(
                          theme, profile.averageRating, profile.ratingCount),
                      if ((profile.addressLabel ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          profile.addressLabel!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (profile.isVerified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Doğrulandı',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (profile.phoneNumber ?? '').trim().isEmpty
                        ? null
                        : () async {
                            final number = profile.phoneNumber!.trim();
                            await Clipboard.setData(
                                ClipboardData(text: number));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Numara kopyalandı: $number'),
                              ),
                            );
                          },
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Ara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _askQuestion(context, profile),
                    icon: const Icon(Icons.question_answer_rounded),
                    label: const Text('Soru Sor'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if ((profile.description ?? '').trim().isNotEmpty) ...[
              Text(
                'Hakkında',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                profile.description!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 16),
            ],
            if (profile.serviceCategories.isNotEmpty) ...[
              Text(
                'Hizmetler',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.serviceCategories.take(12).map((c) {
                  return Chip(label: Text(c));
                }).toList(growable: false),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Yorumlar',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (_reviews.isEmpty)
              Text(
                'Henüz yorum yok.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              ..._reviews.take(10).map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.userDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${r.createdAtUtc.toLocal().day}.${r.createdAtUtc.toLocal().month}.${r.createdAtUtc.toLocal().year}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.comment,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
