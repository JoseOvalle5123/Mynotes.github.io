// lib/services/biometric_service.dart
// Autenticación biométrica para notas privadas
// Patrón: Service Layer

import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo soporta biometría
  Future<bool> isBiometricAvailable() async {
    // En web no hay soporte biométrico
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Obtiene los tipos de biometría disponibles
  Future<List<BiometricType>> getBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Autentica al usuario con huella/Face ID
  /// Retorna true si la autenticación fue exitosa
  Future<bool> authenticate({
    String reason = 'Verifica tu identidad para acceder a esta nota privada',
  }) async {
    // En web simulamos autenticación exitosa (para demostración)
    if (kIsWeb) return true;

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth:  true,   // Mantiene auth si app va a background
          biometricOnly: false, // Permite PIN como fallback
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Error biométrico: ${e.message}');
      return false;
    }
  }

  /// Cancela autenticación en curso
  Future<void> cancelAuthentication() async {
    if (kIsWeb) return;
    await _auth.stopAuthentication();
  }
}