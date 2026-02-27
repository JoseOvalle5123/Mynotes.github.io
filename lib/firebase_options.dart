// lib/firebase_options.dart
// Generado manualmente con los valores de Firebase Console
// NO compartas este archivo públicamente

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Web ─────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyBglswAPj8eKcNHUgzc942sxzBuBmRriu0',
    authDomain:        'mynotes-app-77b1c.firebaseapp.com',
    projectId:         'mynotes-app-77b1c',
    storageBucket:     'mynotes-app-77b1c.firebasestorage.app',
    messagingSenderId: '1052879213520',
    appId:             '1:1052879213520:web:f4554678aaf4cb9ad55fd5',
  );

  // ── Android ─────────────────────────────────
  // Si usas Android, registra la app en Firebase Console y reemplaza estos valores
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyBglswAPj8eKcNHUgzc942sxzBuBmRriu0',
    authDomain:        'mynotes-app-77b1c.firebaseapp.com',
    projectId:         'mynotes-app-77b1c',
    storageBucket:     'mynotes-app-77b1c.firebasestorage.app',
    messagingSenderId: '1052879213520',
    appId:             '1:1052879213520:web:f4554678aaf4cb9ad55fd5',
  );

  // ── iOS ─────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyBglswAPj8eKcNHUgzc942sxzBuBmRriu0',
    authDomain:        'mynotes-app-77b1c.firebaseapp.com',
    projectId:         'mynotes-app-77b1c',
    storageBucket:     'mynotes-app-77b1c.firebasestorage.app',
    messagingSenderId: '1052879213520',
    appId:             '1:1052879213520:web:f4554678aaf4cb9ad55fd5',
  );
}