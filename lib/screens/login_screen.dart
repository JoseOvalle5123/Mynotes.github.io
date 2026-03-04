// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final authService        = AuthService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool isLoading  = false;
  bool isRegister = false;
  bool _obscure   = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
          ? await authService.register(email, password)
          : await authService.login(email, password);
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _showSnack('Credenciales inválidas');
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A1A2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Fondo con gradiente y círculos decorativos
          Positioned(top: -80, right: -60,
            child: Container(width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF00C896).withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(bottom: -100, left: -80,
            child: Container(width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFD4AF37).withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),

                          // Logo
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C896), Color(0xFF00A67E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C896).withOpacity(0.4),
                                  blurRadius: 20, offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit_note,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 32),

                          Text(
                            isRegister ? 'Crear cuenta' : 'Bienvenido',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isRegister
                                ? 'Registra tu cuenta para empezar'
                                : 'Tus notas seguras en la nube',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 15),
                          ),
                          const SizedBox(height: 40),

                          // Campo email
                          _buildField(
                            controller: emailController,
                            label: 'Correo electrónico',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Campo contraseña
                          _buildField(
                            controller: passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined
                                         : Icons.visibility_outlined,
                                color: Colors.white38, size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00C896), Color(0xFF00A67E)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C896).withOpacity(0.35),
                                    blurRadius: 16, offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: isLoading
                                    ? const SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        isRegister ? 'Crear cuenta' : 'Ingresar',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Toggle login/registro
                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => isRegister = !isRegister),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: isRegister
                                          ? '¿Ya tienes cuenta? '
                                          : '¿No tienes cuenta? ',
                                    ),
                                    TextSpan(
                                      text: isRegister
                                          ? 'Inicia sesión'
                                          : 'Regístrate',
                                      style: const TextStyle(
                                        color: Color(0xFF00C896),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF16161F),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF00C896), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}