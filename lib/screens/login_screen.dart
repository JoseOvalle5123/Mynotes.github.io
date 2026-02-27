// lib/screens/login_screen.dart
// Actualizado para ser compatible con Firebase Auth
// El AuthService ahora retorna User? en lugar de bool

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final authService        = AuthService();

  bool isLoading  = false;
  bool isRegister = false; // Alternar entre Login y Registro

  // ── LOGIN / REGISTRO ────────────────────────
  Future<void> _submit() async {
    final email    = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Completa todos los campos');
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = isRegister
          ? await authService.register(email, password)  // Registro Firebase
          : await authService.login(email, password);    // Login Firebase

      if (!mounted) return;

      if (user != null) {
        // Éxito: navegar a HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showSnack('Usuario o contraseña inválidos');
      }
    } catch (e) {
      // El AuthService lanza mensajes de error ya traducidos al español
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ── UI ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegister ? 'Crear cuenta' : 'Login')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 600 ? 400 : double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono de nube
                      const Icon(Icons.cloud, size: 72, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        isRegister ? 'Crear cuenta' : 'Bienvenido',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tus notas sincronizadas en la nube ☁️',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Campo Email
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo Contraseña
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón principal (Login o Registro)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _submit,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isRegister ? Icons.person_add : Icons.login),
                          label: Text(isRegister ? 'Crear cuenta' : 'Ingresar'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Alternar entre Login y Registro
                      TextButton(
                        onPressed: () =>
                            setState(() => isRegister = !isRegister),
                        child: Text(
                          isRegister
                              ? '¿Ya tienes cuenta? Inicia sesión'
                              : '¿No tienes cuenta? Regístrate',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}