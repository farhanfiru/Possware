import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/supabase_config.dart';
import '../providers/billing_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: AppTheme.primaryBurgundy, size: 22),
              SizedBox(width: 8),
              Text('Admin Security PIN', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Admin PIN to reveal and edit Supabase backend credentials:',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
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
                  prefixIcon: const Icon(Icons.key, color: AppTheme.primaryBurgundy),
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
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBurgundy,
                foregroundColor: Colors.white,
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
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBurgundy)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Counter Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textDark)),
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.cardBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Supabase Backend Settings (PIN protected)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Supabase Backend Credentials',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  if (_isSupabaseUnlocked)
                    TextButton.icon(
                      icon: const Icon(Icons.lock, size: 15, color: AppTheme.primaryBurgundy),
                      label: const Text('Lock', style: TextStyle(color: AppTheme.primaryBurgundy, fontWeight: FontWeight.w700)),
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
                  color: _isSupabaseUnlocked ? AppTheme.cashGreen : AppTheme.textSecondary,
                  fontWeight: _isSupabaseUnlocked ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 12),

              if (!_isSupabaseUnlocked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_person_outlined, size: 36, color: AppTheme.textMuted),
                      const SizedBox(height: 10),
                      const Text(
                        'Credentials Locked',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Project URL and Anon API Key are hidden.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _promptForAdminPassword,
                        icon: const Icon(Icons.key, size: 16),
                        label: const Text('Unlock with PIN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBurgundy,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cashGreen, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Supabase Project URL',
                          hintText: 'https://xyzcompany.supabase.co',
                          prefixIcon: Icon(Icons.cloud_outlined, color: AppTheme.primaryBurgundy),
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
                          prefixIcon: Icon(Icons.key_outlined, color: AppTheme.primaryBurgundy),
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
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Information printed at the top of every customer thermal receipt',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name',
                        hintText: 'Neyco Cafe & Restro',
                        prefixIcon: Icon(Icons.storefront_outlined, color: AppTheme.primaryBurgundy),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Address / Branch',
                        hintText: '123 Food Street, Downtown',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryBurgundy),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number',
                        hintText: '+91 98765 43210',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryBurgundy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: const Icon(Icons.save, size: 18),
                  label: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBurgundy,
                    foregroundColor: Colors.white,
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
      await SupabaseService().reinitialize(url, anonKey);
      if (mounted) {
        final billing = context.read<BillingProvider>();
        await billing.fetchMenu();
      }
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppTheme.cashGreen,
        ),
      );
      Navigator.pop(context);
    }
  }
}
