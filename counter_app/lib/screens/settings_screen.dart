import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/supabase_config.dart';
import '../providers/billing_provider.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _anonKeyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSupabaseUnlocked = false;

  static const String _adminPin = '9599';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url = await SupabaseConfig.getUrl();
    final anonKey = await SupabaseConfig.getAnonKey();
    final name = await SupabaseConfig.getRestaurantName();
    final address = await SupabaseConfig.getRestaurantAddress();
    final phone = await SupabaseConfig.getRestaurantPhone();

    setState(() {
      _urlController.text = url;
      _anonKeyController.text = anonKey;
      _nameController.text = name;
      _addressController.text = address;
      _phoneController.text = phone;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _promptForAdminPassword() {
    final pinController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF0F172A), size: 24),
              SizedBox(width: 8),
              Text('Admin Security PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Admin PIN to reveal and edit Supabase backend credentials:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  errorText: errorText,
                  counterText: '',
                  prefixIcon: const Icon(Icons.key),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (val) {
                  if (val == _adminPin) {
                    setState(() => _isSupabaseUnlocked = true);
                    Navigator.pop(ctx);
                  } else {
                    setDialogState(() => errorText = 'Incorrect PIN');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (pinController.text.trim() == _adminPin) {
                  setState(() => _isSupabaseUnlocked = true);
                  Navigator.pop(ctx);
                } else {
                  setDialogState(() => errorText = 'Incorrect PIN');
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Counter Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Supabase Backend Settings (Protected by PIN 9599)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Supabase Backend Credentials',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  if (_isSupabaseUnlocked)
                    TextButton.icon(
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text('Lock'),
                      onPressed: () => setState(() => _isSupabaseUnlocked = false),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isSupabaseUnlocked
                    ? 'Credentials unlocked for editing.'
                    : '🔒 Protected section. Enter Admin PIN to view and modify.',
                style: TextStyle(
                  fontSize: 12,
                  color: _isSupabaseUnlocked ? const Color(0xFF059669) : Colors.grey,
                  fontWeight: _isSupabaseUnlocked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 12),

              if (!_isSupabaseUnlocked)
                // Locked Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.lock_person_outlined, size: 40, color: Colors.grey.shade500),
                      const SizedBox(height: 10),
                      const Text(
                        'Credentials Locked',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Project URL and Anon API Key are hidden.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _promptForAdminPassword,
                        icon: const Icon(Icons.key, size: 18),
                        label: const Text('Unlock with PIN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Unlocked Inputs
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Supabase Project URL',
                          hintText: 'https://xyzcompany.supabase.co',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cloud_outlined),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'URL is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _anonKeyController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Supabase Anon Public Key',
                          hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Anon Key is required' : null,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // 2. Receipt Header Customization
              const Text(
                'Receipt Header & Business Info',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Information printed at the top of every customer thermal receipt',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name',
                        hintText: 'Delicious Bites Cafe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Address / Branch',
                        hintText: '123 Food Street, Downtown',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number',
                        hintText: '+91 98765 43210',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: const Icon(Icons.save),
                  label: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final url = _urlController.text.trim();
    final anonKey = _anonKeyController.text.trim();

    await SupabaseConfig.saveConfig(
      url: url,
      anonKey: anonKey,
      restaurantName: _nameController.text.trim(),
      restaurantAddress: _addressController.text.trim(),
      restaurantPhone: _phoneController.text.trim(),
    );

    if (_isSupabaseUnlocked) {
      final success = await SupabaseService().reinitialize(url, anonKey);
      final billing = context.read<BillingProvider>();
      await billing.fetchMenu();
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }
}
