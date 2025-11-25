import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ListingProvider>().fetchMyListings());
  }

  Future<void> _changeVisibility(
      Listing listing, ListingVisibility target) async {
    final success =
        await context.read<ListingProvider>().updateListingVisibility(
              listing.id,
              target,
            );
    if (!mounted) return;
    final message = success
        ? (target == ListingVisibility.active
            ? 'İlan yayına alındı'
            : 'İlan gizlendi')
        : context.read<ListingProvider>().error ?? 'İşlem başarısız';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete(Listing listing) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlanı Kaldır'),
        content: const Text(
            'Bu ilanı kaldırmak istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _changeVisibility(listing, ListingVisibility.deleted);
    }
  }

  String _visibilityLabel(ListingVisibility visibility) {
    switch (visibility) {
      case ListingVisibility.passive:
        return 'Gizli';
      case ListingVisibility.active:
        return 'Yayında';
      case ListingVisibility.deleted:
        return 'Silindi';
    }
  }

  Color _visibilityColor(ListingVisibility visibility, ThemeData theme) {
    switch (visibility) {
      case ListingVisibility.passive:
        return Colors.orange;
      case ListingVisibility.active:
        return theme.colorScheme.primary;
      case ListingVisibility.deleted:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('İlanlarım'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-listing'),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ListingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.myListings.isEmpty) {
            return const Center(
                child: Text('Henüz ilanınız yok. Bir tane oluşturun!'));
          }
          final theme = Theme.of(context);
          return ListView.builder(
            itemCount: provider.myListings.length,
            itemBuilder: (context, index) {
              final listing = provider.myListings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(listing.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          '${DateFormat('yyyy-MM-dd').format(listing.eventDate)} - ${listing.status}'),
                      const SizedBox(height: 4),
                      Text('Bütçe: ₺${listing.totalBudget.toStringAsFixed(0)}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.circle,
                              size: 10,
                              color:
                                  _visibilityColor(listing.visibility, theme)),
                          const SizedBox(width: 6),
                          Text(
                            _visibilityLabel(listing.visibility),
                            style: TextStyle(
                              color:
                                  _visibilityColor(listing.visibility, theme),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<_ListingMenuAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _ListingMenuAction.hide:
                          _changeVisibility(listing, ListingVisibility.passive);
                          break;
                        case _ListingMenuAction.show:
                          _changeVisibility(listing, ListingVisibility.active);
                          break;
                        case _ListingMenuAction.delete:
                          _confirmDelete(listing);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (listing.visibility == ListingVisibility.active)
                        const PopupMenuItem(
                          value: _ListingMenuAction.hide,
                          child: Text('Gizle'),
                        ),
                      if (listing.visibility == ListingVisibility.passive)
                        const PopupMenuItem(
                          value: _ListingMenuAction.show,
                          child: Text('Yayına Al'),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: _ListingMenuAction.delete,
                        child: Text('Kaldır'),
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/listing/${listing.id}', extra: listing);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _ListingMenuAction { hide, show, delete }
