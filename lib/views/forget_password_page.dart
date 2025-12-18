import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  static const accent = Color(0xFFfe4c50);

  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer votre adresse email.")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📩 Lien envoyé à $email.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 14,
              shadowColor: accent.withOpacity(0.3),
              color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---- Icon / Logo ----
                    const Icon(Icons.lock_reset_rounded,
                        color: accent, size: 46),
                    const SizedBox(height: 18),
                    Text(
                      "Mot de passe oublié",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Entrez votre adresse email pour recevoir un lien de réinitialisation.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // ---- Email Input ----
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: "Adresse email",
                        hintText: "exemple@mail.com",
                        prefixIcon: const Icon(Icons.email_outlined),
                        labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700]),
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400]),
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

                    const SizedBox(height: 28),

                    // ---- Send Button ----
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                color: accent,
                                strokeWidth: 2.5,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                                label: const Text(
                                  "Envoyer le lien",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 6,
                                ),
                                onPressed: _sendResetEmail,
                              ),
                            ),
                    ),

                    const SizedBox(height: 22),

                    // ---- Back to Login ----
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "← Retour à la connexion",
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ---- Footer ----
                    Text(
                      "© 2025 Mediacité",
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
