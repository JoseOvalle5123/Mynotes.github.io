// lib/models/note.dart
// Modelo actualizado con soporte para Firestore (Nube)

import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime? reminder;
  final String userId;          // Nuevo: dueño de la nota
  final DateTime? createdAt;    // Nuevo: fecha de creación en la nube
  final DateTime? updatedAt;    // Nuevo: última actualización

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.reminder,
    this.userId = '',
    this.createdAt,
    this.updatedAt,
  });

  // ── Convertir Firestore → Note ──────────────
  // Concepto: API de conectividad con la nube
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id:        doc.id,
      title:     data['title']   ?? '',
      content:   data['content'] ?? '',
      userId:    data['userId']  ?? '',
      reminder:  data['reminder'] != null
                   ? (data['reminder'] as Timestamp).toDate()
                   : null,
      createdAt: data['createdAt'] != null
                   ? (data['createdAt'] as Timestamp).toDate()
                   : null,
      updatedAt: data['updatedAt'] != null
                   ? (data['updatedAt'] as Timestamp).toDate()
                   : null,
    );
  }

  // ── Convertir Note → Firestore ──────────────
  Map<String, dynamic> toFirestore() {
    return {
      'title':     title,
      'content':   content,
      'userId':    userId,
      'reminder':  reminder  != null ? Timestamp.fromDate(reminder!)  : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copia con cambios (útil para editar)
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? reminder,
    String? userId,
  }) {
    return Note(
      id:       id       ?? this.id,
      title:    title    ?? this.title,
      content:  content  ?? this.content,
      reminder: reminder ?? this.reminder,
      userId:   userId   ?? this.userId,
    );
  }
}