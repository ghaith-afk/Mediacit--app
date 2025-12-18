import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/auth_controller.dart';


class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final emailController = TextEditingController();
  final displayNameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFfe4c50);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101010) : Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---- Logo / App Branding ----
              Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, Colors.deepOrangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_circle_outlined,
                        color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rejoignez MediaTech en quelques secondes',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // ---- Registration Card ----
              Card(
                elevation: 8,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      TextField(
                        controller: displayNameController,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.white70 : Colors.grey[700]),
                          prefixIcon: const Icon(Icons.person_outline),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextField(
                        controller: emailController,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.white70 : Colors.grey[700]),
                          prefixIcon: const Icon(Icons.email_outlined),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.white70 : Colors.grey[700]),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            onPressed: () {
                              setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible);
                            },
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ---- Register button ----
                      authState.when(
                        data: (_) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 8,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            onPressed: () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .register(
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                    displayNameController.text.trim(),
                                  );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Inscription réussie ! Bienvenue 👋')),
                                );
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              }
                            },
                            child: const Text('S’inscrire',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(
                            color: primaryColor),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Erreur : ${e.toString()}',
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ---- Back to login ----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Déjà un compte ? ",
                            style: TextStyle(
                              color:
                                  isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
