import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/providers/auth_provider.dart';
import 'package:mediatech/controllers/auth_controller.dart';
import 'package:mediatech/models/role.dart';
import 'package:mediatech/views/forget_password_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  static const accent = Color(0xFFfe4c50);

Future<void> _handleLogin(WidgetRef ref, BuildContext context) async {
  try {
    final authNotifier = ref.read(authControllerProvider.notifier);
    await authNotifier.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    final appUser = await ref.read(appUserProvider.future);

    if (appUser == null) {
      throw Exception("Utilisateur introuvable.");
    }

    if (appUser.suspended) {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚫 Votre compte est suspendu. Contactez l'administrateur."),
        ),
      );
      return;
    }

    if (appUser.role == UserRole.admin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage = "Identifiants incorrects";
    
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        errorMessage = "Identifiants incorrects";
        break;
      case 'invalid-email':
        errorMessage = "Format d'email invalide";
        break;
      case 'user-disabled':
        errorMessage = "Ce compte a été désactivé";
        break;
      case 'too-many-requests':
        errorMessage = "Trop de tentatives. Réessayez plus tard";
        break;
      case 'network-request-failed':
        errorMessage = "Erreur de connexion réseau";
        break;
      default:
        errorMessage = "Erreur de connexion";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Erreur de connexion"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
              elevation: 14,
              shadowColor: accent.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: accent, size: 42),
                    const SizedBox(height: 14),
                    Text(
                      "Mediacité",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connexion à votre espace',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // ---- Email ----
                    TextField(
                      controller: emailController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700]),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF252525) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ---- Password ----
                    TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () {
                            setState(
                                () => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF252525) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
      );
    },
    child: const Text("Mot de passe oublié ?"),
  ),
),

                    const SizedBox(height: 5),

                    // ---- Login Button ----
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: authState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: accent,
                                strokeWidth: 2.5,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 6,
                                ),
                                onPressed: () async =>
                                    await _handleLogin(ref, context),
                                child: const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 25),

                    // ---- Register ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pas encore de compte ? ",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            "S'inscrire",
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ---- Footer ----
                    Text(
                      "© 2025 Mediacité. Tous droits réservés.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey[500],
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
}
