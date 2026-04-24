import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get cleanedPhone => _phoneController.text.replaceAll(RegExp(r'\D'), '');
  bool get isValid => cleanedPhone.length >= 10;

  Future<void> _handleSubmit() async {
    if (!isValid) {
      setState(() => _error = 'Please enter a valid 10-digit phone number');
      return;
    }
    
    setState(() {
      _submitting = true;
      _error = null;
    });

    final appProvider = context.read<AppProvider>();
    await appProvider.login(cleanedPhone);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/tabs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F12), Color(0xFF0D1A13), Color(0xFF0B0F12)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 40,
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                // Brand
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Roadly',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Report road issues. Earn points.\nHelp emergency vehicles reach faster.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 14,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Features
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _featureItem('alert_octagon', 'Report'),
                    _featureItem('award', 'Earn'),
                    _featureItem('favorite', 'Help'),
                  ],
                ),
                const SizedBox(height: 32),
                // Form card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phone number',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                '+91',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                onChanged: (_) => setState(() => _error = null),
                                keyboardType: TextInputType.phone,
                                maxLength: 14,
                                style: const TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: '98765 43210',
                                  hintStyle: TextStyle(color: AppColors.mutedForeground),
                                  border: InputBorder.none,
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _submitting ? null : _handleSubmit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isValid ? AppColors.primary : AppColors.secondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_circle_right,
                                color: isValid ? Colors.white : AppColors.mutedForeground,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: isValid ? Colors.white : AppColors.mutedForeground,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By continuing you agree to share your location to report and view nearby issues.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(String iconName, String label) {
    IconData iconData;
    switch (iconName) {
      case 'alert_octagon':
        iconData = Icons.warning;
        break;
      case 'award':
        iconData = Icons.emoji_events;
        break;
      case 'favorite':
        iconData = Icons.favorite;
        break;
      default:
        iconData = Icons.circle;
    }
    
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(iconData, size: 18, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
