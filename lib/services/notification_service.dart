// lib/services/notification_service.dart
// Notificaciones Push con Firebase Cloud Messaging (FCM)
// Concepto: Notificaciones Push en la Nube

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Handler para notificaciones en background (debe ser función top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Notificación en background: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // ── INICIALIZAR ─────────────────────────────
  Future<void> init() async {
    // 1. Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Pedir permiso al usuario (iOS y Android 13+)
    final settings = await _fcm.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permiso de notificaciones concedido');

      // 3. Obtener y guardar token FCM del dispositivo
      await _guardarToken();

      // 4. Configurar notificaciones locales (para primer plano)
      await _initLocalNotifications();

      // 5. Escuchar mensajes cuando la app está abierta
      FirebaseMessaging.onMessage.listen(_mostrarNotificacionLocal);

      // 6. Manejar tap en notificación (app en background)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('📲 Usuario abrió notificación: ${message.notification?.title}');
      });

    } else {
      debugPrint('❌ Permiso de notificaciones denegado');
    }
  }

  // ── GUARDAR TOKEN EN FIRESTORE ──────────────
  // Permite enviar notificaciones a este dispositivo desde Cloud Functions
  Future<void> _guardarToken() async {
    final token = await _fcm.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(user.uid)
          .set({
        'token':     token,
        'userId':    user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('📱 Token FCM guardado en la nube: $token');
    }

    // Actualizar token si se renueva
    _fcm.onTokenRefresh.listen((newToken) async {
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc(user.uid)
            .update({'token': newToken, 'updatedAt': FieldValue.serverTimestamp()});
      }
    });
  }

  // ── NOTIFICACIONES LOCALES (primer plano) ───
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotif.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _mostrarNotificacionLocal(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    const androidDetails = AndroidNotificationDetails(
      'mynotes_channel',
      'MyNotes Notificaciones',
      channelDescription: 'Notificaciones de MyNotes',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── NOTIFICACIÓN LOCAL AL GUARDAR UNA NOTA ──
  // Feedback inmediato al usuario sin necesidad de servidor
  Future<void> notificarNotaGuardada(String titulo) async {
    const androidDetails = AndroidNotificationDetails(
      'mynotes_channel',
      'MyNotes Notificaciones',
      channelDescription: 'Notificaciones de MyNotes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '☁️ Nota guardada en la nube',
      '"$titulo" fue sincronizada exitosamente.',
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}