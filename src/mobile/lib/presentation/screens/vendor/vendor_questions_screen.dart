import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/vendor_provider.dart';
import '../../../data/models/vendor_question_model.dart';
import '../../../data/models/vendor_review_model.dart';

class VendorQuestionsScreen extends StatefulWidget {
  const VendorQuestionsScreen({super.key});

  @override
  State<VendorQuestionsScreen> createState() => _VendorQuestionsScreenState();
}

class _VendorQuestionsScreenState extends State<VendorQuestionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<VendorProvider>();
      provider.fetchMyQuestions();
      provider.fetchMyReviews();
    });
  }

  Future<void> _handleAnswer(VendorQuestion question) async {
    final controller = TextEditingController(text: question.answer ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soruyu Yanıtla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Yanıtınız...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Yanıtla'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      if (!mounted) return;
      try {
        await context
            .read<VendorProvider>()
            .answerQuestion(question.id, result.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yanıt kaydedildi.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ')),
        );
      }
    }
  }

  Widget _buildQuestionsList(BuildContext context, VendorProvider provider) {
    if (provider.myQuestions.isEmpty) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Henüz soru yok.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.myQuestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final q = provider.myQuestions[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      q.userDisplayName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(q.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q.question,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                if (q.answer != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yanıtınız:',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(q.answer!),
                      ],
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleAnswer(q),
                      icon: const Icon(Icons.reply),
                      label: const Text('Yanıtla'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsList(BuildContext context, VendorProvider provider) {
    if (provider.myReviews.isEmpty) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Henüz değerlendirme yok.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.myReviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = provider.myReviews[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.userDisplayName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                        DateFormat('dd MMM yyyy').format(r.createdAtUtc),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r.comment),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sorular & Değerlendirmeler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sorular'),
              Tab(text: 'Değerlendirmeler'),
            ],
          ),
        ),
        body: Consumer<VendorProvider>(
          builder: (context, provider, _) {
            return TabBarView(
              children: [
                _buildQuestionsList(context, provider),
                _buildReviewsList(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }
}
