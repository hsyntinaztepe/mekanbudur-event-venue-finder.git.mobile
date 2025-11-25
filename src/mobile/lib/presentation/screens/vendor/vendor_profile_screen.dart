import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadProfile());
  }

  Future<void> _loadProfile() async {
    await context.read<VendorProvider>().fetchProfile();
    if (!mounted) {
      return;
    }
    final profile = context.read<VendorProvider>().profile;
    if (profile != null) {
      _companyNameController.text = profile.companyName;
      _descriptionController.text = profile.description ?? '';
      _phoneNumberController.text = profile.phoneNumber ?? '';
      _websiteController.text = profile.website ?? '';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _phoneNumberController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<VendorProvider>().updateProfile({
        'companyName': _companyNameController.text,
        'description': _descriptionController.text,
        'phoneNumber': _phoneNumberController.text,
        'website': _websiteController.text,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil güncellendi')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.read<VendorProvider>().error ??
                  'Güncelleme başarısız')),
        );
      }
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
        title: const Text('Tedarikçi Profili'),
        centerTitle: true,
      ),
      body: Consumer<VendorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(labelText: 'Şirket Adı'),
                    validator: (v) => v?.isEmpty == true ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Telefon Numarası'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(labelText: 'Web Sitesi'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Kaydet'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
