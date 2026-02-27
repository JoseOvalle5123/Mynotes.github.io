// lib/services/auth_service.dart
// Autenticación real con Firebase Auth
// Concepto: BaaS — Backend as a Service

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instancia del servicio de Auth en la nube (BaaS)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Usuario actual ──────────────────────────
  User? get currentUser => _auth.currentUser;
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Stream que emite cambios de sesión en tiempo real
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Login con Email y Contraseña ────────────
  // Antes: simulado con Future.delayed
  // Ahora: autenticación real en la nube (Firebase BaaS)
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _mensajeDeError(e.code);
    }
  }

  // ── Registro de nuevo usuario ───────────────
  Future<User?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _mensajeDeError(e.code);
    }
  }

  // ── Cerrar sesión ───────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Mensajes de error amigables ─────────────
  String _mensajeDeError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      default:
        return 'Error de autenticación: $code';
    }
  }
}