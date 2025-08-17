// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción: Este widget construye una cuadrícula de calendario para un mes específico,
// permitiendo seleccionar días, marcar días no disponibles y mostrar el estado de los días seleccionados.
// Es útil para interfaces de usuario donde se necesita interactuar con un calendario,
// como en una aplicación para la gestión de eventos, reservas o citas.
//
// Recomendaciones:
// - Asegúrate de que las fechas no disponibles y seleccionadas estén correctamente formateadas
//   para evitar posibles errores de comparación.
// - El modo de selección múltiple puede ser útil si se desea que el usuario seleccione más de un día a la vez.
// - Este widget es ideal para aplicaciones de gestión de agenda, reservas o planificación de eventos.
//
// Características:
// - Muestra un calendario mensual con los días organizados por semanas.
// - Permite seleccionar días con un solo toque (o múltiples, si el `multiSelectMode` está activado).
// - Muestra días no disponibles con un estilo diferenciado y evita que se seleccionen.
// - Los días seleccionados se resaltan con un color diferente y un ícono de marca de verificación.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/resources/colors.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime month; // Mes y año del calendario
  final List<DateTime>
  unavailableDays; // Días que no están disponibles para selección
  final Set<DateTime> selectedDays; // Días seleccionados
  final bool multiSelectMode; // Modo de selección múltiple
  final Function(DateTime)
  onDaySelected; // Función que maneja el evento de selección de un día
  final DateTime currentDate; // Fecha actual para gestionar días pasados

  CalendarGrid({
    required this.month,
    required this.unavailableDays,
    required this.selectedDays,
    required this.multiSelectMode,
    required this.onDaySelected,
    required this.currentDate,
  });

  @override
  Widget build(BuildContext context) {
    // Se obtiene el esquema de colores configurado en la aplicación
    final colorScheme = ColorPalette.getPalette(context);

    // Se obtiene la cantidad de días del mes
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    // Se calcula el primer día del mes para alinear la cuadrícula correctamente
    final firstDayOfMonth = DateTime(month.year, month.month, 1).weekday % 7;

    return Column(
      children: [
        // Encabezado con los días de la semana
        Row(
          children:
              AppStrings.weekdayShortNames.map((day) {
                return Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                );
              }).toList(),
        ),

        // Generación de las semanas del mes
        ...List.generate((daysInMonth + firstDayOfMonth + 6) ~/ 7, (week) {
          return Row(
            children: List.generate(7, (weekday) {
              // Cálculo del día específico dentro de la semana
              final day = (week * 7) + weekday - firstDayOfMonth + 1;

              // Si el día está fuera del rango válido, se retorna un espacio vacío
              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox());
              }

              final currentDay = DateTime(month.year, month.month, day);

              // Comprobación si el día está marcado como no disponible
              final isUnavailable = unavailableDays.any(
                (d) =>
                    d.year == currentDay.year &&
                    d.month == currentDay.month &&
                    d.day == currentDay.day,
              );

              // Comprobación si el día está seleccionado
              final isSelected = selectedDays.any(
                (d) =>
                    d.year == currentDay.year &&
                    d.month == currentDay.month &&
                    d.day == currentDay.day,
              );

              // Comprobación si el día ya ha pasado
              final isPast = currentDay.isBefore(currentDate);

              return Expanded(
                child: AspectRatio(
                  aspectRatio: 1, // Mantiene el aspecto cuadrado
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: InkWell(
                      // Si el día es pasado, se desactiva la selección
                      onTap: isPast ? null : () => onDaySelected(currentDay),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isPast
                                  ? Colors.grey.withOpacity(0.5)
                                  : (isUnavailable || isSelected
                                      ? colorScheme[AppStrings.essentialColor]
                                      : colorScheme[AppStrings.primaryColor]
                                              ?.withOpacity(0.1) ??
                                          Colors.grey[200]),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                colorScheme[AppStrings.secondaryColor]
                                    ?.withOpacity(0.3) ??
                                Colors.grey,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Mostrar el número del día
                            Text(
                              day.toString(),
                              style: TextStyle(
                                color:
                                    isPast
                                        ? Colors.grey[700]
                                        : (isUnavailable || isSelected
                                            ? colorScheme[AppStrings
                                                .primaryColor]
                                            : colorScheme[AppStrings
                                                .secondaryColor]),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Si el día está seleccionado, mostrar un ícono de verificación
                            if (isSelected)
                              Icon(
                                Icons.check,
                                color: colorScheme[AppStrings.primaryColor],
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
