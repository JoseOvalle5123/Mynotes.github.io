// =============================================
// firebase-messaging-sw.js
// Service Worker para Notificaciones Push en Background
// IMPORTANTE: Este archivo debe estar en la RAÍZ del proyecto
// =============================================

importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// Inicializar Firebase en el Service Worker
// (Mismos valores que en firebase-config.js)
firebase.initializeApp({
  apiKey: "TU_API_KEY",
  authDomain: "TU_PROJECT_ID.firebaseapp.com",
  projectId: "TU_PROJECT_ID",
  storageBucket: "TU_PROJECT_ID.appspot.com",
  messagingSenderId: "TU_MESSAGING_SENDER_ID",
  appId: "TU_APP_ID"
});

const messaging = firebase.messaging();

// Manejar notificaciones cuando la app está en segundo plano o cerrada
messaging.onBackgroundMessage((payload) => {
  console.log("🔔 Notificación en background:", payload);

  const { title, body, icon } = payload.notification;

  // Mostrar la notificación al usuario aunque la app esté cerrada
  self.registration.showNotification(title, {
    body: body,
    icon: icon || "/icon.png",
    badge: "/badge.png",
    data: payload.data,
    actions: [
      { action: "abrir", title: "Abrir MyNotes" },
      { action: "cerrar", title: "Cerrar" }
    ]
  });
});

// Manejar clic en la notificación
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  if (event.action === "abrir" || !event.action) {
    event.waitUntil(
      clients.openWindow("/") // Abrir la app
    );
  }
});