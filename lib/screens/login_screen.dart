import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/app_provider.dart';
import '../widgets/motion.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true; // Toggle between Login and Register
  bool _submitting = false;
  bool _pressed = false;
  String? _error; // Server-side errors only (duplicate phone, wrong password…)
  String? _notice; // One-shot notice (e.g. server data reset) from the provider

  static final _digitsOnly = RegExp(r'\D');

  @override
  void initState() {
    super.initState();
    // Show the pending provider notice (e.g. "Server data was reset…") once,
    // on the first build after a forced sign-out.
    _notice = context.read<AppProvider>().consumeNotice();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get cleanedPhone => _phoneController.text.replaceAll(_digitsOnly, '');

  bool get isValid {
    if (_passwordController.text.isEmpty) return false;
    if (cleanedPhone.length != 10) return false;
    if (!_isLoginMode && _nameController.text.trim().isEmpty) return false;
    return true;
  }

  // ── Per-field validation ────────────────────────────────────────────────
  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your full name';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 80) return 'Name must be 80 characters or fewer';
    return null;
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').replaceAll(_digitsOnly, '');
    if (v.isEmpty) return 'Enter your phone number';
    if (v.length != 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (!_isLoginMode && v.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      // Validation messages are rendered per field by the Form.
      setState(() {
        _error = null;
        _notice = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
    });

    final appProvider = context.read<AppProvider>();

    try {
      if (_isLoginMode) {
        await appProvider.login(cleanedPhone, _passwordController.text);
      } else {
        await appProvider.register(
          _nameController.text.trim(),
          cleanedPhone,
          _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/tabs');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                StaggerIn(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoginMode 
                            ? 'Welcome back. Log in to continue.'
                            : 'Report road issues. Earn points.\nHelp emergency vehicles reach faster.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form card
                StaggerIn(
                  delay: const Duration(milliseconds: 90),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppColors.radius),
                        border: Border.all(color: AppColors.border),
                      ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isLoginMode) ...[
                          const Text(
                            'Full Name',
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
                            child: TextFormField(
                              controller: _nameController,
                              onChanged: (_) => setState(() => _error = null),
                              textInputAction: TextInputAction.next,
                              validator: _validateName,
                              style: const TextStyle(
                                color: AppColors.foreground,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _inputDecoration('Naveen'),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
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
                          child: TextFormField(
                            controller: _phoneController,
                            onChanged: (_) => setState(() => _error = null),
                            keyboardType: TextInputType.phone,
                            maxLength: 14,
                            textInputAction: TextInputAction.next,
                            validator: _validatePhone,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _inputDecoration(
                              '98765 43210',
                              prefixText: '+91 ',
                            ).copyWith(counterText: ''),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        const Text(
                          'Password',
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
                          child: TextFormField(
                            controller: _passwordController,
                            onChanged: (_) => setState(() => _error = null),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _submitting ? null : _handleSubmit(),
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _inputDecoration('••••••••'),
                          ),
                        ),
                        
                        if (_notice != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.accent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _notice!,
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTapDown: (_) => setState(() => _pressed = true),
                          onTapUp: (_) => setState(() => _pressed = false),
                          onTapCancel: () => setState(() => _pressed = false),
                          onTap: _submitting ? null : _handleSubmit,
                          child: AnimatedScale(
                            scale: _pressed ? 0.97 : 1,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isValid
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_submitting)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  else ...[
                                    Icon(
                                      _isLoginMode ? Icons.login : Icons.person_add,
                                      color: isValid ? Colors.white : AppColors.mutedForeground,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLoginMode ? 'Log in' : 'Create account',
                                      style: TextStyle(
                                        color: isValid ? Colors.white : AppColors.mutedForeground,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                
                const SizedBox(height: 24),
                // Toggle between modes
                StaggerIn(
                  delay: const Duration(milliseconds: 180),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _error = null;
                      });
                      // Drop any validation messages from the previous mode.
                      _formKey.currentState?.reset();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: _isLoginMode ? "Don't have an account? " : "Already have an account? "),
                            TextSpan(
                              text: _isLoginMode ? "Sign up" : "Log in",
                              style: const TextStyle(
                                color: AppColors.primarySoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedForeground),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      errorStyle: const TextStyle(
        color: AppColors.danger,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
