// lib/services/note_service.dart
// Servicio de Notas con Firebase Firestore
// Conceptos: Almacenamiento en la Nube + APIs de Sincronización

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referencia a la colección de notas en Firestore (Nube)
  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection('notas');

  // ── STREAM EN TIEMPO REAL ───────────────────
  // Concepto: APIs de Conectividad y Sincronización
  // Cada vez que se guarda/edita/elimina una nota en la nube,
  // este stream notifica automáticamente a la app.
  Stream<List<Note>> notasStream(String userId) {
    return _notesRef
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  // ── CREAR NOTA ──────────────────────────────
  // Almacenamiento en la Nube: guarda en Firestore
  Future<void> crearNota(Note nota) async {
    await _notesRef.add(nota.toFirestore());
  }

  // ── ACTUALIZAR NOTA ─────────────────────────
  Future<void> actualizarNota(Note nota) async {
    await _notesRef.doc(nota.id).update(nota.toFirestore());
  }

  // ── ELIMINAR NOTA ───────────────────────────
  Future<void> eliminarNota(String notaId) async {
    await _notesRef.doc(notaId).delete();
  }
}