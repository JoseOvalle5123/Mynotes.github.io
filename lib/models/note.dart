// lib/models/note.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String    id;
  final String    title;
  final String    content;
  final DateTime? reminder;
  final String    userId;
  final bool      isPrivate;
  final String?   imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.reminder,
    this.userId    = '',
    this.isPrivate = false,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id:        doc.id,
      title:     data['title']     ?? '',
      content:   data['content']   ?? '',
      userId:    data['userId']    ?? '',
      isPrivate: data['isPrivate'] ?? false,
      imageUrl:  data['imageUrl'],
      reminder:  data['reminder']  != null ? (data['reminder']  as Timestamp).toDate() : null,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title':     title,
      'content':   content,
      'userId':    userId,
      'isPrivate': isPrivate,
      'imageUrl':  imageUrl,
      'reminder':  reminder  != null ? Timestamp.fromDate(reminder!)  : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Note copyWith({String? id, String? title, String? content, DateTime? reminder,
      String? userId, bool? isPrivate, String? imageUrl}) {
    return Note(
      id: id ?? this.id, title: title ?? this.title,
      content: content ?? this.content, reminder: reminder ?? this.reminder,
      userId: userId ?? this.userId, isPrivate: isPrivate ?? this.isPrivate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}