/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * Descripción:
 *  La clase `CalendarGrid` es un widget que presenta un calendario interactivo con la posibilidad de seleccionar días. Permite navegar entre meses y resaltar días seleccionados, pasados y no disponibles. Este calendario es útil para aplicaciones que requieren seleccionar fechas, como la reserva de eventos, citas, o cualquier otra funcionalidad relacionada con fechas.
 *  
 * Recomendaciones:
 *  - Utiliza este widget cuando necesites un calendario interactivo que permita a los usuarios seleccionar días.
 *  - Considera deshabilitar la selección de días pasados y no disponibles para evitar errores de selección.
 *  - Asegúrate de pasar los valores correctos para las listas de días no disponibles y seleccionados, ya que el comportamiento del calendario depende de ellos.
 *  
 * Características:
 *  - Navegación entre meses con botones para avanzar y retroceder.
 *  - Días pasados deshabilitados con estilo "cristalizado".
 *  - Días seleccionados marcados con un icono de "check".
 *  - Días no disponibles marcados con un color de error.
 *  - Soporte para múltiples días seleccionados en modo de selección múltiple.
 *  - Personalización del estilo mediante un esquema de colores.
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/resources/colors.dart';

class CalendarGrid extends StatefulWidget {
  final DateTime month; // Mes actual que se está mostrando en el calendario.
  final List<DateTime> unavailableDays; // Días no disponibles en el calendario.
  final Set<DateTime> selectedDays; // Días seleccionados por el usuario.
  final bool
  multiSelectMode; // Indica si el modo de selección múltiple está habilitado.
  final Function(DateTime)
  onDaySelected; // Acción a ejecutar cuando un día es seleccionado.
  final DateTime currentDate; // Fecha actual para determinar días pasados.

  const CalendarGrid({
    required this.month,
    required this.unavailableDays,
    required this.selectedDays,
    required this.multiSelectMode,
    required this.onDaySelected,
    required this.currentDate,
    Key? key,
  }) : super(key: key);

  @override
  _CalendarGridState createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.month; // Inicializa el mes seleccionado.
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene el esquema de colores.
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    ); // Obtiene el número de días del mes.
    final firstDayOfMonth =
        DateTime(selectedMonth.year, selectedMonth.month, 1).weekday %
        7; // Calcula el día de la semana del primer día del mes.
    final totalCells =
        daysInMonth +
        firstDayOfMonth; // Total de celdas necesarias en el calendario.
    final rows =
        (totalCells / 7).ceil(); // Calcula la cantidad de filas necesarias.

    return Column(
      children: [
        // Encabezado con los botones de navegación de mes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed:
                  selectedMonth.isAfter(
                        DateTime(
                          widget.currentDate.year,
                          widget.currentDate.month,
                        ),
                      )
                      ? () {
                        setState(() {
                          selectedMonth = DateTime(
                            selectedMonth.year,
                            selectedMonth.month - 1,
                          ); // Retrocede un mes si es posible.
                        });
                      }
                      : null, // Deshabilita el botón si no es posible retroceder.
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme[AppStrings.secondaryColor],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat.yMMMM(
                    'es',
                  ).format(selectedMonth), // Muestra el nombre del mes.
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  selectedMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month + 1,
                  ); // Avanza un mes.
                });
              },
              icon: Icon(
                Icons.arrow_forward,
                color: colorScheme[AppStrings.secondaryColor],
              ),
            ),
          ],
        ),

        // Encabezado con los días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              AppStrings.weekdayShortNames
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day, // Muestra las abreviaturas de los días de la semana.
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),

        const SizedBox(height: 8),

        // Muestra la cuadrícula de días del mes
        Column(
          children: List.generate(rows, (i) {
            return Row(
              children: List.generate(7, (j) {
                final cellIndex = i * 7 + j;
                if (cellIndex < firstDayOfMonth ||
                    cellIndex >= daysInMonth + firstDayOfMonth) {
                  return Expanded(
                    child: SizedBox(height: 40),
                  ); // Celdas vacías si no hay día.
                } else {
                  final day =
                      cellIndex -
                      firstDayOfMonth +
                      1; // Calcula el número del día.
                  final currentDay = DateTime(
                    selectedMonth.year,
                    selectedMonth.month,
                    day,
                  );
                  final isPast = currentDay.isBefore(
                    DateTime(
                      widget.currentDate.year,
                      widget.currentDate.month,
                      widget.currentDate.day,
                    ),
                  ); // Verifica si el día es pasado.
                  final isSelected = widget.selectedDays.contains(
                    currentDay,
                  ); // Verifica si el día está seleccionado.
                  final isUnavailable = widget.unavailableDays.any(
                    (d) =>
                        d.year == currentDay.year &&
                        d.month == currentDay.month &&
                        d.day == currentDay.day,
                  ); // Verifica si el día no está disponible.

                  Color? bgColor;
                  Color textColor = Colors.white;

                  // Determina el color de fondo y el texto según el estado del día.
                  if (isSelected) {
                    bgColor = colorScheme[AppStrings.essentialColor];
                  } else if (isPast) {
                    bgColor = Colors.grey.withOpacity(
                      0.2,
                    ); // Días pasados tienen color "cristalizado".
                    textColor = Colors.grey.withOpacity(0.6);
                  } else if (isUnavailable) {
                    bgColor =
                        Theme.of(context)
                            .colorScheme
                            .error; // Días no disponibles en color de error.
                  } else {
                    bgColor = colorScheme[AppStrings.primaryColorLight];
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap:
                          !isPast && !isUnavailable
                              ? () {
                                widget.onDaySelected(
                                  currentDay,
                                ); // Ejecuta la acción si el día es válido.
                              }
                              : null,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4),
                          border:
                              isPast
                                  ? Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  )
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '$day', // Muestra el número del día.
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight:
                                      isPast
                                          ? FontWeight.normal
                                          : FontWeight.w500,
                                ),
                              ),
                            ),           
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }),
            );
          }),
        ),
      ],
    );
  }
}
