import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../application/auth_controller.dart';
import '../../application/auth_state.dart';

/// Halaman login. Fokus pada autentikasi dasar yang aman sesuai kontrak
/// backend (`POST /auth/login`). Role ditentukan backend, bukan pengguna.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authStateProvider.notifier)
        .login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fieldErrors = _mergedFieldErrors(auth);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.school_rounded, size: 64, color: scheme.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (auth.notice != null) ...[
                      _Banner(
                        message: auth.notice!,
                        color: scheme.primaryContainer,
                        onColor: scheme.onPrimaryContainer,
                        onDismiss: () =>
                            ref.read(authStateProvider.notifier).clearNotice(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (auth.errorMessage != null) ...[
                      _Banner(
                        message: _errorWithFields(
                          auth.errorMessage!,
                          fieldErrors,
                        ),
                        color: scheme.errorContainer,
                        onColor: scheme.onErrorContainer,
                        onDismiss: () =>
                            ref.read(authStateProvider.notifier).clearError(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'Username wajib diisi.';
                        if (v.length > 30) {
                          return 'Username maksimal 30 karakter.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => (value ?? '').isEmpty
                          ? 'Password wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: auth.isSubmitting ? null : _submit,
                      child: auth.isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Hanya untuk siswa, guru, dan wali murid.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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

  Map<String, List<String>> _mergedFieldErrors(AuthState auth) =>
      auth.fieldErrors;

  String _errorWithFields(String message, Map<String, List<String>> fields) {
    if (fields.isEmpty) return message;
    final buffer = StringBuffer(message);
    for (final entry in fields.entries) {
      buffer.writeln();
      buffer.write('• ${entry.key}: ${entry.value.join(', ')}');
    }
    return buffer.toString();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.color,
    required this.onColor,
    this.onDismiss,
  });

  final String message;
  final Color color;
  final Color onColor;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(message, style: TextStyle(color: onColor)),
          ),
          if (onDismiss != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 18, color: onColor),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
