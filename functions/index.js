// functions/index.js
// Cloud Functions para MyNotes
// Concepto: FaaS - Function as a Service (Serverless)

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp }     = require("firebase-admin/app");
const { getFirestore }      = require("firebase-admin/firestore");
const { getMessaging }      = require("firebase-admin/messaging");

initializeApp();

// ── FUNCIÓN 1: Notificar cuando se crea una nota nueva ──
// Se activa automáticamente cada vez que se guarda una nota en Firestore
exports.notificarNuevaNota = onDocumentCreated(
  "notas/{notaId}",
  async (event) => {
    const nota   = event.data.data();
    const userId = nota.userId;

    console.log(`☁️ Nueva nota creada por: ${userId}`);

    try {
      // Obtener token FCM del usuario desde Firestore
      const tokenDoc = await getFirestore()
        .collection("fcm_tokens")
        .doc(userId)
        .get();

      if (!tokenDoc.exists) {
        console.log("No hay token FCM para este usuario");
        return null;
      }

      const token = tokenDoc.data().token;

      // Construir notificación push
      const mensaje = {
        notification: {
          title: "📝 Nota guardada en la nube",
          body:  `"${nota.title}" fue sincronizada exitosamente.`,
        },
        data: {
          notaId:    event.params.notaId,
          tipo:      "nueva_nota",
          isPrivate: nota.isPrivate ? "true" : "false",
        },
        token: token,
      };

      // Enviar notificación push via FCM
      const response = await getMessaging().send(mensaje);
      console.log("✅ Notificación enviada:", response);
      return response;

    } catch (error) {
      console.error("❌ Error al enviar notificación:", error);
      return null;
    }
  }
);

// ── FUNCIÓN 2: Limpiar tokens FCM inválidos ──
// Se ejecuta cada 7 días automáticamente (Cron Job serverless)
const { onSchedule } = require("firebase-functions/v2/scheduler");

exports.limpiarTokensInvalidos = onSchedule("every 7 days", async () => {
  console.log("🧹 Limpiando tokens FCM inválidos...");
  // Aquí podrías agregar lógica para limpiar tokens expirados
  console.log("✅ Limpieza completada");
});