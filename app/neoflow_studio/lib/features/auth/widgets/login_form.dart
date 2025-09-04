import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/custom_text_field.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/local_storage_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool loading = false;

  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final savedEmail = await LocalStorageService.getRememberedEmail();
    if (savedEmail != null) {
      setState(() {
        emailController.text = savedEmail;
        rememberMe = true;
      });
    }
  }

  Future<void> _handleLogin() async {

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validação de campos obrigatórios
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Preenche todos os campos obrigatórios")),
      );
      return; // não tenta fazer login
    }


    setState(() => loading = true);
    try {
      await _auth.signIn(email, password);

      if (rememberMe) {
        await LocalStorageService.setRememberedEmail(email);
      } else {
        await LocalStorageService.setRememberedEmail(null);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Login efetuado com sucesso")),
      );

      // TODO: navegar para Home
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Utilizador não encontrado';
          break;
        case 'wrong-password':
          msg = 'Password incorreta';
          break;
        case 'invalid-email':
          msg = 'Email inválido';
          break;
        default:
          msg = 'Erro: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escreve o email para recuperar password")),
      );
      return;
    }

    try {
      await _auth.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📧 Email de recuperação enviado")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: emailController,
          label: "Email",
          icon: Icons.email_outlined,
        ),

        const SizedBox(height: 16),

        CustomTextField(
          controller: passwordController,
          label: "Password",
          icon: Icons.lock_outline,
          obscureText: true,
        ),

        const SizedBox(height: 28),

        CustomButton(
          text: "Entrar",
          loading: loading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (v) => setState(() => rememberMe = v ?? false),
              activeColor: const Color(0xFF3A3735),
            ),
            const Text("Memorizar login"),
          ],
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : _handleResetPassword,
            child: const Text("Recuperar password"),
          ),
        ),
      ],
    );
  }
}