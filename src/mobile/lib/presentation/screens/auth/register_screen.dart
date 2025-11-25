import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  // Vendor specific
  final _companyNameController = TextEditingController();
  final Set<int> _selectedCategoryIds = {};

  String _selectedRole = 'User';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ListingProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Build CSV from selected category names
      String? serviceCategoriesCsv;
      if (_selectedRole == 'Vendor' && _selectedCategoryIds.isNotEmpty) {
        final categories = context.read<ListingProvider>().categories;
        final selectedNames = categories
            .where((c) => _selectedCategoryIds.contains(c.id))
            .map((c) => c.name)
            .toList();
        serviceCategoriesCsv = selectedNames.join(',');
      }

      final success = await context.read<AuthProvider>().register(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _displayNameController.text,
            role: _selectedRole,
            companyName:
                _selectedRole == 'Vendor' ? _companyNameController.text : null,
            serviceCategoriesCsv: serviceCategoriesCsv,
          );

      if (success && mounted) {
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AuthProvider>().error ?? 'Kayıt başarısız oldu',
            ),
          ),
        );
      }
    }
  }

  void _showCategoryPicker() {
    final categories = context.read<ListingProvider>().categories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hizmet Kategorileri',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tamam'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected =
                              _selectedCategoryIds.contains(cat.id);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(cat.name),
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  _selectedCategoryIds.add(cat.id);
                                } else {
                                  _selectedCategoryIds.remove(cat.id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _buildSelectedCategoriesText() {
    if (_selectedCategoryIds.isEmpty) {
      return 'Kategori seçmek için dokunun';
    }
    final categories = context.read<ListingProvider>().categories;
    final names = categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Kayıt Ol'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Ad Soyad'),
                      validator: (v) =>
                          v?.isEmpty == true ? 'Bu alan zorunludur' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Bu alan zorunludur' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Şifre'),
                      obscureText: true,
                      validator: (v) => (v?.length ?? 0) < 6
                          ? 'En az 6 karakter olmalı'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration:
                          const InputDecoration(labelText: 'Hesap Türü'),
                      items: const [
                        DropdownMenuItem(
                          value: 'User',
                          child: Text('Kullanıcı (Etkinlik Sahibi)'),
                        ),
                        DropdownMenuItem(
                          value: 'Vendor',
                          child: Text('Tedarikçi (Hizmet Sağlayıcı)'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedRole = val!;
                          _selectedCategoryIds.clear();
                        });
                      },
                    ),
                    if (_selectedRole == 'Vendor') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyNameController,
                        decoration:
                            const InputDecoration(labelText: 'Şirket Adı'),
                        validator: (v) =>
                            _selectedRole == 'Vendor' && v?.isEmpty == true
                                ? 'Bu alan zorunludur'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Consumer<ListingProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return InkWell(
                            onTap: _showCategoryPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hizmet Kategorileri',
                                suffixIcon: const Icon(Icons.arrow_drop_down),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _buildSelectedCategoriesText(),
                                style: _selectedCategoryIds.isEmpty
                                    ? theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white54,
                                      )
                                    : theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return auth.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : FilledButton(
                                onPressed: _register,
                                child: const Text('Kayıt Ol'),
                              );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Zaten hesabınız var mı? Giriş yapın'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
