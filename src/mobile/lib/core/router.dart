import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'public_url.dart';
import '../data/models/listing_model.dart';
import '../data/models/google_place_category.dart';
import '../data/models/embedded_place_model.dart';
import '../presentation/providers/listing_provider.dart';
import '../presentation/providers/vendor_provider.dart';
import '../presentation/providers/embedded_places_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/listing/create_listing_screen.dart';
import '../presentation/screens/listing/listing_details_screen.dart';
import '../presentation/screens/listing/my_listings_screen.dart';
import '../presentation/screens/listing/favorites_screen.dart';
import '../presentation/screens/listing/saved_places_screen.dart';
import '../presentation/screens/vendor/bid_screen.dart';
import '../presentation/screens/vendor/my_bids_screen.dart';
import '../presentation/screens/vendor/vendor_feed_screen.dart';
import '../presentation/screens/vendor/public_vendor_details_screen.dart';
import '../presentation/screens/vendor/vendor_profile_screen.dart';
import '../presentation/screens/vendor/vendor_questions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _role;
  String? _displayName;
  String? _token;
  String? _email;
  bool _sessionLoaded = false;

  final PageController _promoController =
      PageController(viewportFraction: 0.94);
  int _promoIndex = 0;
  Timer? _promoTimer;

  static const List<_PromoSlide> _promoSlides = <_PromoSlide>[
    _PromoSlide(
      title: 'Konumları kaydet',
      subtitle: 'Beğendiğiniz mekanları harita üzerinde takip edin.',
      icon: Icons.location_on_outlined,
      imageUrl: 'assets/promo/main.png',
    ),
    _PromoSlide(
      title: 'İlan ver, teklif al',
      subtitle: 'İhtiyacınızı paylaşın, tedarikçiler size teklif göndersin.',
      icon: Icons.handshake_outlined,
      imageUrl: 'assets/promo/2.png',
    ),
    _PromoSlide(
      title: 'MekanBudur ile keşfet',
      subtitle: 'Etkinliğinize uygun mekan ve hizmetleri tek yerde bulun.',
      icon: Icons.auto_awesome,
      imageUrl: 'assets/promo/1.png',
    ),
  ];

  bool get _isAuthenticated => (_token ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _promoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (!_promoController.hasClients) return;

      final next = (_promoIndex + 1) % _promoSlides.length;
      _promoController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
    Future.microtask(() async {
      final listingProvider = context.read<ListingProvider>();
      final vendorProvider = context.read<VendorProvider>();
      final embeddedPlacesProvider = context.read<EmbeddedPlacesProvider>();

      await _loadSession(listingProvider);
      if (!mounted) return;

      await listingProvider.fetchAllListings();
      await listingProvider.fetchCategories();

      // Public vendors for showcasing "Üye mekanlar"
      await vendorProvider.fetchPublicVendors(forceRefresh: true);

      await embeddedPlacesProvider.ensureLoaded();

      if (mounted) {
        setState(() {
          _sessionLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoTimer = null;
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadSession(ListingProvider listingProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final displayName = prefs.getString('displayName');
    final email = prefs.getString('email');

    if (!mounted) {
      return;
    }

    setState(() {
      _token = token;
      _role = role;
      _displayName = displayName;
      _email = email;
    });

    await listingProvider.fetchFavorites();
  }

  Future<void> _refreshListings() async {
    await context.read<ListingProvider>().fetchAllListings();
  }

  Future<void> _handleFavoriteTap(Listing listing) async {
    if (!_isAuthenticated) {
      _showLoginRequiredMessage();
      return;
    }

    final added = await context
        .read<ListingProvider>()
        .toggleFavorite(listing.id);

    if (!mounted) return;

    final message =
        added ? 'İlan favorilere eklendi' : 'İlan favorilerden kaldırıldı';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLoginRequiredMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorilere eklemek için giriş yapmalısınız.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listingProvider = context.watch<ListingProvider>();
    final vendorProvider = context.watch<VendorProvider>();
    final embeddedPlacesProvider = context.watch<EmbeddedPlacesProvider>();
    final greeting = (_displayName ?? '').isNotEmpty
        ? 'Merhaba, ${_displayName!}'
        : 'Merhaba!';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshListings,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildHeader(theme, greeting),
                      const SizedBox(height: 16),
                      _buildPromoSection(theme),
                      const SizedBox(height: 18),
                      _buildServicesSection(theme, context),
                      const SizedBox(height: 18),
                      _buildEmbeddedPlacesSection(
                        theme,
                        context,
                        embeddedPlacesProvider,
                      ),
                      const SizedBox(height: 18),
                      _buildPublicVendorsSection(theme, vendorProvider),
                      const SizedBox(height: 24),
                      if (_isAuthenticated) ...[
                        _buildQuickActions(theme, context),
                        const SizedBox(height: 24),
                      ],
                      ..._buildListingSection(listingProvider, theme, context),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, theme),
    );
  }

  Widget _buildServicesSection(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hizmetler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/saved-places'),
              child: const Text('Keşfet'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GooglePlaceCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = GooglePlaceCategory.values[index];
              final label = GooglePlaceCategory.labelFor(cat);
              final icon = _iconForGoogleCategory(cat);

              return InkWell(
                onTap: () => context.push(
                  '/saved-places?cat=${Uri.encodeComponent(cat)}',
                ),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 148,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _iconForGoogleCategory(String category) {
    switch (category) {
      case GooglePlaceCategory.weddingHalls:
        return Icons.celebration_rounded;
      case GooglePlaceCategory.photographers:
        return Icons.camera_alt_rounded;
      case GooglePlaceCategory.bakeries:
        return Icons.cake_rounded;
      case GooglePlaceCategory.florists:
        return Icons.local_florist_rounded;
      case GooglePlaceCategory.music:
        return Icons.music_note_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Widget _buildEmbeddedPlacesSection(
    ThemeData theme,
    BuildContext context,
    EmbeddedPlacesProvider embeddedProvider,
  ) {
    final places = embeddedProvider.places;
    final isLoading = embeddedProvider.isLoading && places.isEmpty;
    final hasData = places.isNotEmpty;
    final error = embeddedProvider.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Çevredeki Mekanlar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (embeddedProvider.isLoading)
              Text(
                hasData ? 'Güncelleniyor...' : 'Yükleniyor...',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (error != null && places.isEmpty)
          Text(
            'Mekanlar yüklenemedi: $error',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          )
        else
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: isLoading && places.isEmpty
                  ? 4
                  : (places.length > 12 ? 12 : places.length),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (isLoading && !hasData) {
                  return Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  );
                }

                final place = places[index];
                final googleCat =
                    _mapEmbeddedCategoryToGoogleCategory(place.category);

                return InkWell(
                  onTap: googleCat == null
                      ? null
                      : () => context.push(
                            '/saved-places?cat=${Uri.encodeComponent(googleCat)}',
                          ),
                  borderRadius: BorderRadius.circular(18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Image.asset(
                          place.assetPath,
                          width: 220,
                          height: 168,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 220,
                            height: 168,
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.05),
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _embeddedCategoryLabel(place.category),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _embeddedCategoryLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'wedding':
        return 'Düğün Salonu';
      case 'photographer':
        return 'Fotoğrafçı';
      case 'bakery':
        return 'Pastane';
      case 'florist':
        return 'Çiçekçi';
      default:
        return raw;
    }
  }

  String? _mapEmbeddedCategoryToGoogleCategory(String raw) {
    switch (raw.toLowerCase()) {
      case 'wedding':
        return GooglePlaceCategory.weddingHalls;
      case 'photographer':
        return GooglePlaceCategory.photographers;
      case 'bakery':
        return GooglePlaceCategory.bakeries;
      case 'florist':
        return GooglePlaceCategory.florists;
      default:
        return null;
    }
  }

  Widget _buildPublicVendorsSection(
      ThemeData theme, VendorProvider vendorProvider) {
    final vendors = vendorProvider.publicVendorsById.values
        .toList(growable: false)
      ..sort((a, b) => a.companyName.compareTo(b.companyName));

    if (vendors.isEmpty && vendorProvider.isPublicVendorsLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Üye Mekanlar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (vendors.isEmpty) {
      final err = vendorProvider.publicVendorsError;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Üye Mekanlar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              err == null || err.trim().isEmpty
                  ? 'Henüz gösterilecek üye mekan yok.'
                  : 'Yüklenemedi. Sunucuya bağlanılamadı.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (err != null && err.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: () => vendorProvider.fetchPublicVendors(
                    forceRefresh: true,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.10),
            theme.colorScheme.surface,
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Üye Mekanlar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'Öne çıkanlar',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vendors.length > 10 ? 10 : vendors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final v = vendors[index];
                final title = v.companyName.trim();
                final subtitle = v.categoryList.take(2).join(' • ');
                final hasPhoto = v.photoUrlList.isNotEmpty;
                final borderColor = v.isVerified
                    ? theme.colorScheme.primary.withOpacity(0.35)
                    : theme.colorScheme.outline.withOpacity(0.18);

                return Container(
                  width: 292,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: hasPhoto
                            ? Image.network(
                                normalizePublicUrl(v.photoUrlList.first),
                                width: 66,
                                height: 66,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _vendorFallbackAvatar(theme, title),
                              )
                            : _vendorFallbackAvatar(theme, title),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (v.isVerified)
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle.isEmpty
                                  ? 'Kategori belirtilmemiş'
                                  : subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 34,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  textStyle:
                                      theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  minimumSize: const Size(0, 34),
                                ),
                                onPressed: () =>
                                    context.push('/vendor/${v.userId}'),
                                child: const Text(
                                  'Ziyaret et',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendorFallbackAvatar(ThemeData theme, String title) {
    final letter = title.isNotEmpty ? title.characters.first : 'M';
    return Container(
      width: 66,
      height: 66,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPromoSection(ThemeData theme) {
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.22);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tanıtım',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${_promoIndex + 1}/${_promoSlides.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 276,
          child: PageView.builder(
            controller: _promoController,
            itemCount: _promoSlides.length,
            onPageChanged: (index) {
              setState(() {
                _promoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = _promoSlides[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.18),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.18),
                              theme.colorScheme.secondary.withOpacity(0.10),
                              theme.colorScheme.surfaceContainerHighest,
                            ],
                          ),
                        ),
                      ),
                      if (slide.imageUrl != null)
                        (slide.imageUrl!.startsWith('assets/')
                            ? Image.asset(
                                slide.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              )
                            : Image.network(
                                slide.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promoSlides.length, (index) {
            final isActive = index == _promoIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 18 : 6,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, String greeting) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              if (_isAuthenticated)
                InkWell(
                  onTap: () => context.push('/favorites'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text('Favorilerim', style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.4),
                  theme.colorScheme.secondary.withOpacity(0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(18),
            child: Text(
              'Etkinliğiniz için en uygun hizmet sağlayıcıyı bulun, yeni ilanları takip edin ve teklifleri yönetin.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListingSection(
    ListingProvider provider,
    ThemeData theme,
    BuildContext context,
  ) {
    if (!_sessionLoaded) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (provider.error != null) {
      return [_buildErrorState(provider.error!, theme)];
    }

    if (provider.isLoading && provider.allListings.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (provider.allListings.isEmpty) {
      return [_buildEmptyState(theme, context)];
    }

    return provider.allListings
        .map((listing) => _buildListingCard(listing, theme, context, provider))
        .toList();
  }

  Widget _buildQuickActions(ThemeData theme, BuildContext context) {
    final buttons = <Widget>[];

    if (_role == 'User') {
      buttons.addAll([
        FilledButton.icon(
          onPressed: () => context.push('/create-listing'),
          icon: const Icon(Icons.add),
          label: const Text('Yeni İlan'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/my-listings'),
          icon: const Icon(Icons.list_alt),
          label: const Text('İlanlarım'),
        ),
      ]);
    } else if (_role == 'Vendor') {
      buttons.addAll([
        FilledButton.icon(
          onPressed: () => context.push('/vendor-feed'),
          icon: const Icon(Icons.search),
          label: const Text('İlanları İncele'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/my-bids'),
          icon: const Icon(Icons.work_outline),
          label: const Text('Tekliflerim'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/vendor-profile'),
          icon: const Icon(Icons.person_outline),
          label: const Text('Profilim'),
        ),
      ]);
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        children: buttons,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, ThemeData theme) {
    String profileTarget;
    if (_role == 'Vendor') {
      profileTarget = '/vendor-profile';
    } else if (_role == 'User') {
      profileTarget = '/my-listings';
    } else {
      profileTarget = '/login';
    }

    final location = GoRouterState.of(context).uri.toString();
    final bool isHome = location == '/';
    final bool isMarket = location.startsWith('/vendor-feed');
    final bool isPlaces = location.startsWith('/saved-places');
    final bool isProfile = location.startsWith('/vendor-profile') ||
        location.startsWith('/my-listings') ||
        location.startsWith('/login');

    void navigate(String path, {bool requireAuth = false}) {
      if (requireAuth && !_isAuthenticated) {
        context.go('/login');
        return;
      }
      context.go(path);
    }

    Widget buildNavItem({
      required String label,
      required VoidCallback onTap,
      required bool isActive,
      required IconData icon,
      required IconData activeIcon,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: theme.colorScheme.primary.withOpacity(0.15),
            highlightColor: theme.colorScheme.primary.withOpacity(0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 56 : 40,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 22,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.55),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.7),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavItem(
                label: 'Ana Sayfa',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isActive: isHome,
                onTap: () => navigate('/'),
              ),
              buildNavItem(
                label: 'Pazar Alanı',
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                isActive: isMarket,
                onTap: () => navigate('/vendor-feed', requireAuth: true),
              ),
              buildNavItem(
                label: 'Mekanlar',
                icon: Icons.location_city_outlined,
                activeIcon: Icons.location_city_rounded,
                isActive: isPlaces,
                onTap: () => navigate('/saved-places', requireAuth: true),
              ),
              buildNavItem(
                label: 'Profil',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                isActive: isProfile,
                onTap: () => navigate(
                  profileTarget,
                  requireAuth: profileTarget != '/login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(
    Listing listing,
    ThemeData theme,
    BuildContext context,
    ListingProvider provider,
  ) {
    final dateFormatter = DateFormat('dd MMM yyyy');
    final currencyFormatter =
        NumberFormat.currency(symbol: 'TRY', decimalDigits: 0);
    final dateLabel = dateFormatter.format(listing.eventDate);
    final budgetLabel = currencyFormatter.format(listing.totalBudget);
    final isFavorite = provider.isFavorite(listing.id);
    final canFavorite = _isAuthenticated;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Icon(Icons.event, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    listing.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: canFavorite
                      ? (isFavorite ? 'Favorilerden kaldır' : 'Favorilere ekle')
                      : 'Giriş yapmanız gerekiyor',
                  onPressed: () {
                    if (canFavorite) {
                      _handleFavoriteTap(listing);
                    } else {
                      _showLoginRequiredMessage();
                    }
                  },
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? Colors.pinkAccent
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            if (listing.description != null && listing.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  listing.description!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                    height: 1.45,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildInfoChip(
                  theme,
                  icon: Icons.calendar_month,
                  label: dateLabel,
                ),
                _buildInfoChip(
                  theme,
                  icon: Icons.location_on,
                  label: listing.location ?? 'Belirtilmemiş',
                ),
                _buildInfoChip(
                  theme,
                  icon: Icons.paid_outlined,
                  label: 'Toplam Bütçe: $budgetLabel',
                ),
                _buildInfoChip(
                  theme,
                  icon: Icons.flag_outlined,
                  label: listing.status,
                ),
              ],
            ),
            if (listing.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İhtiyaç Listesi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...listing.items.map((item) {
                      final itemBudget = currencyFormatter.format(item.budget);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.black54,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.categoryName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              itemBudget,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () =>
                      context.push('/listing/${listing.id}', extra: listing),
                  child: const Text('Detayları Gör'),
                ),
                if (_isAuthenticated && _role == 'Vendor')
                  OutlinedButton(
                    onPressed: () =>
                        context.push('/bid/${listing.id}', extra: listing),
                    child: const Text('Teklif Ver'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text('Şu anda yayınlanan ilan bulunmuyor.'),
          const SizedBox(height: 8),
          if (_isAuthenticated && _role == 'User')
            TextButton(
              onPressed: () => context.push('/create-listing'),
              child: const Text('İlk ilanı siz oluşturun'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('İlanlar yüklenirken hata oluştu: $message'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _refreshListings,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _PromoSlide {
  const _PromoSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageUrl;
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/my-listings',
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/create-listing',
      builder: (context, state) => const CreateListingScreen(),
    ),
    GoRoute(
      path: '/saved-places',
      builder: (context, state) {
        final qp = state.uri.queryParameters;
        return SavedPlacesScreen(
          initialGoogleCategory: qp['cat'],
          initialRefType: qp['type'],
        );
      },
    ),
    GoRoute(
      path: '/places',
      redirect: (context, state) => '/saved-places',
    ),
    GoRoute(
      path: '/place',
      redirect: (context, state) => '/saved-places',
    ),
    GoRoute(
      path: '/vendor-feed',
      builder: (context, state) => const VendorFeedScreen(),
    ),
    GoRoute(
      path: '/bid/:id',
      builder: (context, state) {
        final listing = state.extra as Listing;
        return BidScreen(listing: listing);
      },
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (context, state) {
        final listing = state.extra as Listing;
        return ListingDetailsScreen(listing: listing);
      },
    ),
    GoRoute(
      path: '/vendor-profile',
      builder: (context, state) => const VendorProfileScreen(),
    ),
    GoRoute(
      path: '/vendor/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return PublicVendorDetailsScreen(vendorUserId: id);
      },
    ),
    GoRoute(
      path: '/my-bids',
      builder: (context, state) => const MyBidsScreen(),
    ),
    GoRoute(
      path: '/vendor-questions',
      builder: (context, state) => const VendorQuestionsScreen(),
    ),
  ],
);
