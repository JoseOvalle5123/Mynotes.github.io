// lib/services/calendar_service.dart
// API de Calendario - Agrega recordatorios al calendario del dispositivo

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';

class CalendarService {

  /// Agrega un evento al calendario nativo del dispositivo
  Future<bool> agregarEventoAlCalendario({
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    Duration duracion = const Duration(hours: 1),
  }) async {
    if (kIsWeb) {
      debugPrint('Calendario no disponible en Web');
      return false;
    }

    try {
      final event = Event(
        title:       titulo,
        description: descripcion,
        location:    'MyNotes App',
        startDate:   fechaInicio,
        endDate:     fechaInicio.add(duracion),
      );

      await Add2Calendar.addEvent2Cal(event);
      debugPrint('Evento agregado al calendario: $titulo');
      return true;
    } catch (e) {
      debugPrint('Error al agregar evento: $e');
      return false;
    }
  }
}