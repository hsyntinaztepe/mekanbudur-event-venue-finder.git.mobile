import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../data/models/listing_model.dart';
import '../../providers/bid_provider.dart';

class ListingDetailsScreen extends StatefulWidget {
  final Listing listing;
  const ListingDetailsScreen({super.key, required this.listing});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<BidProvider>().fetchBidsForListing(widget.listing.id));
  }

  Future<void> _acceptBid(String bidId) async {
    final success = await context.read<BidProvider>().acceptBid(bidId);
    if (success && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Teklif kabul edildi')));
      // Refresh bids or listing status
      context.read<BidProvider>().fetchBidsForListing(widget.listing.id);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                context.read<BidProvider>().error ?? 'Teklif kabul edilemedi')),
      );
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
        title: Text(widget.listing.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Etkinlik Tarihi: ${DateFormat('yyyy-MM-dd').format(widget.listing.eventDate)}'),
            const SizedBox(height: 8),
            Text('Konum: ${widget.listing.location ?? '-'}'),
            const SizedBox(height: 8),
            Text('Açıklama: ${widget.listing.description ?? "Bilgi yok"}'),
            if (widget.listing.latitude != null &&
                widget.listing.longitude != null) ...[
              const SizedBox(height: 16),
              Text('Harita', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _ListingMapView(listing: widget.listing),
              if (widget.listing.addressLabel != null) ...[
                const SizedBox(height: 8),
                Text(widget.listing.addressLabel!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey.shade400)),
              ],
            ],
            const SizedBox(height: 16),
            Text('Kalemler:', style: Theme.of(context).textTheme.titleMedium),
            ...widget.listing.items.map((item) => ListTile(
                  title: Text(item.categoryName),
                  subtitle:
                      Text('Bütçe: ${item.budget} - Durum: ${item.status}'),
                )),
            const SizedBox(height: 24),
            Text('Alınan Teklifler:',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Consumer<BidProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.listingBids.isEmpty) {
                  return const Text('Henüz teklif yok.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.listingBids.length,
                  itemBuilder: (context, index) {
                    final bid = provider.listingBids[index];
                    return Card(
                      child: ListTile(
                        title: Text('Tutar: \$${bid.amount}'),
                        subtitle: Text(
                            'Durum: ${bid.status}\nMesaj: ${bid.message ?? ""}'),
                        trailing: bid.status == 'Pending'
                            ? ElevatedButton(
                                onPressed: () => _acceptBid(bid.id),
                                child: const Text('Kabul Et'),
                              )
                            : Text(bid.status,
                                style: TextStyle(
                                  color: bid.status == 'Accepted'
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                )),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingMapView extends StatelessWidget {
  final Listing listing;
  const _ListingMapView({required this.listing});

  @override
  Widget build(BuildContext context) {
    final lat = listing.latitude;
    final lng = listing.longitude;
    if (lat == null || lng == null) {
      return const SizedBox.shrink();
    }
    final point = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile',
            ),
            CircleLayer(
              circles: [
                if ((listing.radius ?? 0) > 0)
                  CircleMarker(
                    point: point,
                    radius: listing.radius!,
                    useRadiusInMeter: true,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    borderStrokeWidth: 2,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
