import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bid_provider.dart';
import '../../../data/models/listing_model.dart';

class BidScreen extends StatefulWidget {
  final Listing listing;
  const BidScreen({super.key, required this.listing});

  @override
  State<BidScreen> createState() => _BidScreenState();
}

class _BidScreenState extends State<BidScreen> {
  final _messageController = TextEditingController();
  final Map<int, TextEditingController> _amountControllers =
      {}; // categoryId -> controller

  @override
  void initState() {
    super.initState();
    for (var item in widget.listing.items) {
      _amountControllers[item.categoryId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    for (var c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitBid() async {
    final items = <Map<String, dynamic>>[];

    for (var item in widget.listing.items) {
      final controller = _amountControllers[item.categoryId];
      if (controller != null && controller.text.isNotEmpty) {
        items.add({
          'eventListingItemId': item.id,
          'amount': double.tryParse(controller.text) ?? 0,
        });
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lütfen en az bir kalem için teklif verin')));
      return;
    }

    final success = await context.read<BidProvider>().placeBid(
          listingId: widget.listing.id,
          items: items,
          message: _messageController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Teklifiniz gönderildi')));
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                context.read<BidProvider>().error ?? 'Teklif gönderilemedi')),
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
        title: Text('${widget.listing.title} için Teklif Ver'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Teklif Vereceğiniz Kalemler',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...widget.listing.items.map((item) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.categoryName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('Bütçe: ${item.budget}'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _amountControllers[item.categoryId],
                          decoration:
                              const InputDecoration(labelText: 'Teklifiniz'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Etkinlik sahibine mesaj (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Consumer<BidProvider>(
              builder: (context, provider, child) {
                return provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _submitBid,
                        child: const Text('Teklifi Gönder'),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
