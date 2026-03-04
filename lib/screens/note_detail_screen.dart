// lib/screens/note_detail_screen.dart
// Pantalla de detalle de nota (solo accesible tras autenticación si es privada)

import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note nota;
  const NoteDetailScreen({super.key, required this.nota});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Icon(
            nota.isPrivate ? Icons.lock_open : Icons.note,
            color: nota.isPrivate ? Colors.green : const Color(0xFF4A90E2),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(nota.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Badge privada
          if (nota.isPrivate)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_user, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text('Nota privada desbloqueada',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
            ),

          // Contenido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              nota.content.isNotEmpty ? nota.content : 'Sin contenido',
              style: const TextStyle(
                  fontSize: 16, height: 1.6, color: Color(0xFF2D3748)),
            ),
          ),

          // Recordatorio
          if (nota.reminder != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.alarm, color: Colors.red),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Recordatorio',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.red)),
                  Text(
                    '${nota.reminder!.day}/${nota.reminder!.month}/${nota.reminder!.year} '
                    '${nota.reminder!.hour}:${nota.reminder!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ]),
              ]),
            ),
          ],

          // Fechas
          const SizedBox(height: 16),
          if (nota.updatedAt != null)
            Text(
              'Última actualización: ${nota.updatedAt!.day}/${nota.updatedAt!.month}/${nota.updatedAt!.year}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
        ]),
      ),
    );
  }
}