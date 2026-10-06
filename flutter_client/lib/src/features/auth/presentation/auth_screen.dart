import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/backend_status_pill.dart';
import '../../../theme/app_theme.dart';
import '../application/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.controller,
    super.key,
    this.startupError,
  });

  final AuthController controller;
  final String? startupError;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _requestMessageController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _isRegistering = false;
  bool _registerAsEmployee = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool? _isBackendConnected;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_checkBackendConnection());
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _companyCodeController.dispose();
    _requestMessageController.dispose();
    _companyNameController.dispose();
    _gstinController.dispose();
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      if (_isRegistering) {
        if (_registerAsEmployee) {
          await widget.controller.registerEmployee(
            fullName: _fullNameController.text.trim(),
            email: _identifierController.text.trim(),
            mobile: _mobileController.text.trim(),
            password: _passwordController.text,
            companyCode: _companyCodeController.text.trim(),
            message: _requestMessageController.text.trim(),
          );
          if (mounted) {
            setState(() {
              _isRegistering = false;
              _successMessage =
                  'Your team join request was submitted. Sign in after a company admin approves it.';
            });
          }
        } else {
          await widget.controller.registerCompany(
            fullName: _fullNameController.text.trim(),
            email: _identifierController.text.trim(),
            mobile: _mobileController.text.trim(),
            password: _passwordController.text,
            companyName: _companyNameController.text.trim(),
            gstin: _gstinController.text.trim(),
            location: _locationController.text.trim(),
            details: _detailsController.text.trim(),
          );
        }
      } else {
        await widget.controller.login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _checkBackendConnection() async {
    await widget.controller.checkBackendConnection();
    if (mounted) {
      setState(
        () => _isBackendConnected = widget.controller.isBackendConnected,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              AppColors.blue.withValues(alpha: 0.06),
              AppColors.teal.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AppCard(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1D4ED8),
                                  Color(0xFF4F46E5),
                                  Color(0xFF7C3AED),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Invoicely AI',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Cloud invoicing and business management',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: BackendStatusPill(
                            isConnected: _isBackendConnected,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Sign in'),
                              icon: Icon(Icons.login),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Create company'),
                              icon: Icon(Icons.business),
                            ),
                          ],
                          selected: {_isRegistering},
                          onSelectionChanged: _isSubmitting
                              ? null
                              : (selection) {
                                  setState(() {
                                    _isRegistering = selection.first;
                                    _errorMessage = null;
                                    _successMessage = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 20),
                        if (_isRegistering) ...[
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Company admin'),
                                icon: Icon(Icons.business),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Join a team'),
                                icon: Icon(Icons.groups_outlined),
                              ),
                            ],
                            selected: {_registerAsEmployee},
                            onSelectionChanged: _isSubmitting
                                ? null
                                : (selection) {
                                    setState(() {
                                      _registerAsEmployee = selection.first;
                                      _errorMessage = null;
                                    });
                                  },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_isRegistering) ...[
                          _textField(
                            controller: _fullNameController,
                            label: 'Full name',
                            icon: Icons.person_outline,
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _textField(
                          controller: _identifierController,
                          label: _isRegistering
                              ? 'Email address'
                              : 'Email or mobile number',
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _isRegistering ? _emailRequired : _required,
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 14),
                          _textField(
                            controller: _mobileController,
                            label: 'Mobile number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: _registeringRequired,
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (_isRegistering && value.length < 6) {
                              return 'Enter at least 6 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (_isRegistering && _registerAsEmployee) ...[
                          const SizedBox(height: 14),
                          _textField(
                            controller: _companyCodeController,
                            label: 'Company join code',
                            icon: Icons.key_outlined,
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            controller: _requestMessageController,
                            label: 'Message to company admin (optional)',
                            icon: Icons.message_outlined,
                            maxLines: 2,
                          ),
                        ],
                        if (_isRegistering && !_registerAsEmployee) ...[
                          const SizedBox(height: 14),
                          _textField(
                            controller: _companyNameController,
                            label: 'Company name',
                            icon: Icons.business_outlined,
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            controller: _gstinController,
                            label: 'GSTIN (optional)',
                            icon: Icons.receipt_outlined,
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            controller: _locationController,
                            label: 'Location (optional)',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          _textField(
                            controller: _detailsController,
                            label: 'Company details (optional)',
                            icon: Icons.notes_outlined,
                            maxLines: 2,
                          ),
                        ],
                        if (widget.startupError != null) ...[
                          const SizedBox(height: 14),
                          _messageBanner(widget.startupError!),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _messageBanner(_errorMessage!),
                        ],
                        if (_successMessage != null) ...[
                          const SizedBox(height: 14),
                          _successBanner(_successMessage!),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRegistering
                                      ? 'Create company account'
                                      : 'Sign in',
                                ),
                        ),
                        if (!_isRegistering) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showPasswordResetDialog,
                            child: const Text('Forgot or reset password?'),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          'Your account is securely connected to the Invoicely service.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This field is required' : null;

  String? _registeringRequired(String? value) {
    if (!_isRegistering) return null;
    return _required(value);
  }

  String? _emailRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    if (_isRegistering &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Widget _messageBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.overdue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.overdue.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.overdue),
      ),
    );
  }

  Widget _successBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paid.withValues(alpha: 0.25)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.paid)),
    );
  }

  Future<void> _showPasswordResetDialog() async {
    final identifierController = TextEditingController(
      text: _identifierController.text.trim(),
    );
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Email or mobile number',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.overdue),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final identifier = identifierController.text.trim();
                      final password = passwordController.text;
                      if (identifier.isEmpty) {
                        setDialogState(
                          () => errorMessage =
                              'Enter your email or mobile number.',
                        );
                      } else if (password.length < 6) {
                        setDialogState(
                          () => errorMessage =
                              'Password must be at least 6 characters.',
                        );
                      } else if (password != confirmController.text) {
                        setDialogState(
                          () => errorMessage = 'Passwords do not match.',
                        );
                      } else {
                        setDialogState(() {
                          errorMessage = null;
                          isSubmitting = true;
                        });
                        try {
                          await widget.controller.resetPassword(
                            identifier: identifier,
                            newPassword: password,
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated. Sign in now.'),
                              ),
                            );
                          }
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              errorMessage = error.toString();
                              isSubmitting = false;
                            });
                          }
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );
    identifierController.dispose();
    passwordController.dispose();
    confirmController.dispose();
  }
}
