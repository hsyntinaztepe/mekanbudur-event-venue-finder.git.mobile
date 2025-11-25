import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/bid_provider.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BidProvider>().fetchMyBids());
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
        title: const Text('Tekliflerim'),
        centerTitle: true,
      ),
      body: Consumer<BidProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.myBids.isEmpty) {
            return const Center(child: Text('Henüz bir teklif vermediniz.'));
          }
          return ListView.builder(
            itemCount: provider.myBids.length,
            itemBuilder: (context, index) {
              final bid = provider.myBids[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Teklif Tutarı: \$${bid.amount}'),
                  subtitle: Text(
                      'Durum: ${bid.status}\nTarih: ${DateFormat('yyyy-MM-dd HH:mm').format(bid.createdAt)}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
