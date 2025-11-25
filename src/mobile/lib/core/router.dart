import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/listing_model.dart';
import '../presentation/providers/listing_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/listing/create_listing_screen.dart';
import '../presentation/screens/listing/listing_details_screen.dart';
import '../presentation/screens/listing/my_listings_screen.dart';
import '../presentation/screens/vendor/bid_screen.dart';
import '../presentation/screens/vendor/my_bids_screen.dart';
import '../presentation/screens/vendor/vendor_feed_screen.dart';
import '../presentation/screens/vendor/vendor_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _role;
  String? _displayName;
  String? _token;
  bool _sessionLoaded = false;

  bool get _isAuthenticated => (_token ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadSession();
      if (mounted) {
        await context.read<ListingProvider>().fetchAllListings();
      }
      if (mounted) {
        setState(() {
          _sessionLoaded = true;
        });
      }
    });
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final displayName = prefs.getString('displayName');

    if (!mounted) {
      return;
    }

    setState(() {
      _token = token;
      _role = role;
      _displayName = displayName;
    });
  }

  Future<void> _refreshListings() async {
    await context.read<ListingProvider>().fetchAllListings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ListingProvider>();
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
                      const SizedBox(height: 24),
                      if (_isAuthenticated) ...[
                        _buildQuickActions(theme, context),
                        const SizedBox(height: 24),
                      ],
                      ..._buildListingSection(provider, theme, context),
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

  Widget _buildHeader(ThemeData theme, String greeting) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
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
                color: Colors.white,
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
        .map((listing) => _buildListingCard(listing, theme, context))
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
        color: const Color(0xFF1B2230),
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
                      color:
                          isActive ? theme.colorScheme.primary : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isActive ? theme.colorScheme.primary : Colors.white54,
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
        color: const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
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
  ) {
    final dateFormatter = DateFormat('dd MMM yyyy');
    final currencyFormatter =
        NumberFormat.currency(symbol: 'TRY', decimalDigits: 0);
    final dateLabel = dateFormatter.format(listing.eventDate);
    final budgetLabel = currencyFormatter.format(listing.totalBudget);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
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
              ],
            ),
            if (listing.description != null && listing.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  listing.description!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.85),
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
                        color: Colors.white,
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
                          color: const Color(0xFF232A39),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.categoryName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
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
        color: const Color(0xFF232A39),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
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
      path: '/create-listing',
      builder: (context, state) => const CreateListingScreen(),
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
      path: '/my-bids',
      builder: (context, state) => const MyBidsScreen(),
    ),
  ],
);
