import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';

class VendorFeedScreen extends StatefulWidget {
  const VendorFeedScreen({super.key});

  @override
  State<VendorFeedScreen> createState() => _VendorFeedScreenState();
}

class _VendorFeedScreenState extends State<VendorFeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ListingProvider>().fetchAllListings());
  }

  Future<bool> _isVendorAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    return (role ?? '').toLowerCase() == 'vendor';
  }

  Future<void> _handleBidTap(listing) async {
    final isVendor = await _isVendorAccount();
    if (!isVendor) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Teklif verebilmek için tedarikçi hesabı gerekli.'),
      ));
      return;
    }
    if (!mounted) return;
    context.push('/bid/${listing.id}', extra: listing);
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
        title: const Text('Tedarikçi Akışı'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Consumer<ListingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.allListings.isEmpty) {
            return const Center(child: Text('Açık ilan bulunamadı.'));
          }
          return ListView.builder(
            itemCount: provider.allListings.length,
            itemBuilder: (context, index) {
              final listing = provider.allListings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(listing.description ?? ''),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(DateFormat('yyyy-MM-dd')
                              .format(listing.eventDate)),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(listing.location ?? ''),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Gereken Kalemler:',
                          style: Theme.of(context).textTheme.titleMedium),
                      ...listing.items.map((item) => Text(
                          '• ${item.categoryName} (Bütçe: ${item.budget})')),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _handleBidTap(listing),
                          child: const Text('Teklif Ver'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
