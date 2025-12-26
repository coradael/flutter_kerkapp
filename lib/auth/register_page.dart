import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() => _loading = false);

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account aangemaakt ✅')),
        );
        Navigator.pop(context); // Terug naar login
      }
    } catch (e) {
      setState(() => _loading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij registreren: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registreren')),
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
                    onPressed: _register,
                    child: const Text('Registreren'),
                  ),
          ],
        ),
      ),
    );
  }
}
