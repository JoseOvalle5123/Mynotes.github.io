// lib/screens/home_screen.dart
// HomeScreen actualizado con sincronización en tiempo real (Firestore)
// Conceptos: Almacenamiento en la Nube + APIs de Sincronización

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteService       _noteService  = NoteService();
  final AuthService       _authService  = AuthService();
  final NotificationService _notifService = NotificationService();

  // Usuario autenticado actualmente
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // Inicializar notificaciones push al entrar a la pantalla
    _notifService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notas ☁️'),
        actions: [
          // Indicador de sincronización
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.cloud_done, color: Colors.green, size: 20),
          ),
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNota(context),
        child: const Icon(Icons.add),
      ),

      // ── StreamBuilder: escucha Firestore en tiempo real ──
      // Concepto: APIs de Conectividad y Sincronización
      body: StreamBuilder<List<Note>>(
        stream: _noteService.notasStream(_userId),
        builder: (context, snapshot) {

          // Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Conectando con la nube...'),
                ],
              ),
            );
          }

          // Error de conexión
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notes = snapshot.data ?? [];

          // Sin notas
          if (notes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No tienes notas aún. ¡Agrega una!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Se sincronizarán automáticamente en la nube',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Lista de notas desde Firestore
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: const Icon(Icons.cloud, color: Colors.blue),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.content.isNotEmpty)
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (note.reminder != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                'Recordatorio: ${_formatDateTime(note.reminder!)}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón editar
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _mostrarDialogoNota(context, nota: note),
                      ),
                      // Botón eliminar
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmarEliminar(note),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── DIÁLOGO CREAR / EDITAR NOTA ─────────────
  void _mostrarDialogoNota(BuildContext context, {Note? nota}) async {
    final titleController =
        TextEditingController(text: nota?.title ?? '');
    final contentController =
        TextEditingController(text: nota?.content ?? '');
    DateTime? reminder = nota?.reminder;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(nota == null ? 'Nueva Nota' : 'Editar Nota'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration:
                          const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      decoration:
                          const InputDecoration(labelText: 'Contenido'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    // Recordatorio
                    ElevatedButton.icon(
                      icon: const Icon(Icons.alarm_add),
                      label: Text(reminder != null
                          ? _formatDateTime(reminder!)
                          : 'Agregar recordatorio'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (date == null) return;

                        // Verificar mounted tras primer await
                        if (!ctx.mounted) return;

                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time == null) return;

                        setDialogState(() {
                          reminder = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Guardar en la nube'),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;

                    final nuevaNota = Note(
                      id:       nota?.id ?? '',
                      title:    titleController.text.trim(),
                      content:  contentController.text.trim(),
                      reminder: reminder,
                      userId:   _userId,
                    );

                    // Guardar en Firestore (nube)
                    if (nota == null) {
                      await _noteService.crearNota(nuevaNota);
                    } else {
                      await _noteService.actualizarNota(nuevaNota);
                    }

                    // Notificación push local confirmando el guardado
                    await _notifService.notificarNotaGuardada(nuevaNota.title);

                    // Verificar mounted ANTES de usar context tras await
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── CONFIRMAR ELIMINAR ──────────────────────
  void _confirmarEliminar(Note nota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text('¿Eliminar "${nota.title}" de la nube?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _noteService.eliminarNota(nota.id);
    }
  }

  // ── CERRAR SESIÓN ───────────────────────────
  Future<void> _cerrarSesion() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ── HELPER: FORMATEAR FECHA ─────────────────
  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}