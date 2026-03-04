// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/biometric_service.dart';
import '../services/calendar_service.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _noteService      = NoteService();
  final _authService      = AuthService();
  final _notifService     = NotificationService();
  final _biometricService = BiometricService();
  final _calendarService  = CalendarService();
  final String _userId    = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Set<String> _unlockedNotes = {};

  @override
  void initState() {
    super.initState();
    _notifService.init();
  }

  Future<void> _abrirNota(Note nota) async {
    if (nota.isPrivate && !_unlockedNotes.contains(nota.id)) {
      final disponible = await _biometricService.isBiometricAvailable();
      bool autenticado = false;

      if (disponible) {
        autenticado = await _biometricService.authenticate(
          reason: 'Usa tu huella para abrir "${nota.title}"',
        );
      } else {
        autenticado = await _mostrarDialogoPIN(nota.title);
      }

      if (!autenticado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Autenticación requerida para ver esta nota privada'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
      setState(() => _unlockedNotes.add(nota.id));
    }

    if (mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => NoteDetailScreen(nota: nota)));
    }
  }

  Future<bool> _mostrarDialogoPIN(String titulo) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.lock, color: Colors.amber),
          SizedBox(width: 8),
          Text('Nota privada'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Ingresa tu contraseña para abrir "$titulo"'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.password),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.isNotEmpty),
              child: const Text('Verificar')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _agregarAlCalendario(Note nota) async {
    if (nota.reminder == null) return;

    final exito = await _calendarService.agregarEventoAlCalendario(
      titulo:      nota.title,
      descripcion: nota.content,
      fechaInicio: nota.reminder!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(exito
            ? '📅 Agregado al calendario'
            : '⚠️ No disponible en esta plataforma'),
        backgroundColor: exito ? Colors.green : Colors.orange,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(children: [
          Icon(Icons.cloud_done, color: Color(0xFF4A90E2), size: 22),
          SizedBox(width: 8),
          Text('Mis Notas',
              style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF718096)),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNota(context),
        backgroundColor: const Color(0xFF4A90E2),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva nota',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Note>>(
        stream: _noteService.notasStream(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.note_add,
                      size: 48, color: Color(0xFF4A90E2)),
                ),
                const SizedBox(height: 16),
                const Text('No tienes notas aún',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748))),
                const SizedBox(height: 8),
                const Text('Toca el botón para crear tu primera nota',
                    style: TextStyle(color: Colors.grey)),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(
                note:       note,
                isUnlocked: _unlockedNotes.contains(note.id),
                onTap:      () => _abrirNota(note),
                onEdit:     () => _mostrarDialogoNota(context, nota: note),
                onDelete:   () => _confirmarEliminar(note),
                onCalendar: () => _agregarAlCalendario(note),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogoNota(BuildContext context, {Note? nota}) async {
    final titleController   = TextEditingController(text: nota?.title   ?? '');
    final contentController = TextEditingController(text: nota?.content ?? '');
    DateTime? reminder = nota?.reminder;
    bool isPrivate     = nota?.isPrivate ?? false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(nota == null ? 'Nueva Nota' : 'Editar Nota'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Título', border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Contenido', border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 12),

              // Toggle nota privada
              Container(
                decoration: BoxDecoration(
                  color: isPrivate
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isPrivate ? Colors.amber : Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  value: isPrivate,
                  onChanged: (v) => setDs(() => isPrivate = v),
                  activeColor: Colors.amber,
                  title: const Text('Nota privada',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    isPrivate
                        ? 'Requiere huella digital para abrir'
                        : 'Visible sin autenticación',
                    style: TextStyle(
                        fontSize: 12,
                        color: isPrivate ? Colors.amber.shade700 : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Recordatorio
              OutlinedButton.icon(
                icon: const Icon(Icons.alarm_add),
                label: Text(reminder != null
                    ? '${reminder!.day}/${reminder!.month} ${reminder!.hour}:${reminder!.minute.toString().padLeft(2, '0')}'
                    : 'Agregar recordatorio'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                  );
                  if (date == null) return;
                  if (!ctx.mounted) return;
                  final time = await showTimePicker(
                      context: ctx, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  setDs(() => reminder = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload, size: 18),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final nuevaNota = Note(
                  id: nota?.id ?? '', title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  reminder: reminder, userId: _userId, isPrivate: isPrivate,
                );
                if (nota == null) {
                  await _noteService.crearNota(nuevaNota);
                } else {
                  await _noteService.actualizarNota(nuevaNota);
                  setState(() => _unlockedNotes.remove(nota.id));
                }
                await _notifService.notificarNotaGuardada(nuevaNota.title);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(Note nota) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text('¿Eliminar "${nota.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await _noteService.eliminarNota(nota.id);
  }

  Future<void> _cerrarSesion() async {
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }
}

// ── Tarjeta de nota ─────────────────────────────
class _NoteCard extends StatelessWidget {
  final Note note;
  final bool isUnlocked;
  final VoidCallback onTap, onEdit, onDelete, onCalendar;

  const _NoteCard({
    required this.note,
    required this.isUnlocked,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = note.isPrivate && !isUnlocked;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  note.isPrivate
                      ? (isLocked ? Icons.lock : Icons.lock_open)
                      : Icons.note,
                  color: note.isPrivate
                      ? (isLocked ? Colors.amber : Colors.green)
                      : const Color(0xFF4A90E2),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(note.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16,
                          color: Color(0xFF2D3748))),
                ),
                if (note.isPrivate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLocked ? '🔒 Privada' : '🔓 Abierta',
                      style: TextStyle(
                          fontSize: 11, color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),

              if (isLocked)
                Row(children: [
                  const Icon(Icons.fingerprint, color: Colors.grey, size: 16),
                  const SizedBox(width: 6),
                  Text('Toca para autenticar con huella',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13,
                          fontStyle: FontStyle.italic)),
                ])
              else if (note.content.isNotEmpty)
                Text(note.content,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14, height: 1.4)),

              if (note.reminder != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.alarm, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    '${note.reminder!.day}/${note.reminder!.month}/${note.reminder!.year} '
                    '${note.reminder!.hour}:${note.reminder!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ]),
              ],

              const Divider(height: 16),

              // Botones de acción
              Wrap(
                spacing: 4,
                children: [
                  // Botón calendario (solo si tiene recordatorio)
                  if (note.reminder != null)
                    TextButton.icon(
                      onPressed: onCalendar,
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Calendario'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.green),
                    ),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4A90E2)),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Eliminar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}