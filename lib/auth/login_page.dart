import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _loading = false;

  Future<void> _login() async {
    print('🔵 Starting login...');
    setState(() => _loading = true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      print('✅ Login response received');
      print('Session: ${response.session != null}');
      print('User: ${response.user?.email}');
      
      setState(() => _loading = false);

      if (!mounted) return;

      if (response.session != null) {
        print('✅ Login successful, auth state should change');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Succesvol ingelogd ✅')),
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      setState(() => _loading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij inloggen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Wachtwoord'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              child: const Text('Geen account? Registreren'),
            ),
          ],
        ),
      ),
    );
  }
}
