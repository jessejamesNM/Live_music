// Fecha de creación: 2025-04-26
// Autor: KingdomOfJames
// Descripción: Pantalla de disponibilidad de un usuario donde se seleccionan los días ocupados en un calendario.
// El usuario puede marcar o desmarcar días como ocupados, tanto de forma individual como en modo de selección múltiple.
// Recomendaciones: Asegúrate de que la colección de usuarios en Firestore tenga un campo 'busyDays' que sea un array de fechas en formato ISO.
// Características: Permite al usuario gestionar su disponibilidad para ciertos eventos, con una interfaz amigable basada en un calendario.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/search/calendar_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_music/presentation/resources/colors.dart';

class AvailabilityContent extends StatefulWidget {
  final String userId;

  const AvailabilityContent({required this.userId, Key? key}) : super(key: key);

  @override
  _AvailabilityContentState createState() => _AvailabilityContentState();
}

class _AvailabilityContentState extends State<AvailabilityContent> {
  DateTime currentDate = DateTime.now();
  DateTime selectedMonth = DateTime.now();
  List<DateTime> unavailableDays = [];
  Set<DateTime> selectedDays = {};
  DateTime? selectedDay;
  bool multiSelectMode = false;

  String? activeDialog;

  @override
  void initState() {
    super.initState();
    _loadBusyDays();
  }

  // Carga los días ocupados desde Firestore
  Future<void> _loadBusyDays() async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);
    final doc = await userRef.get();
    if (doc.exists) {
      final busyDays = List<String>.from(doc.data()?['busyDays'] ?? []);
      setState(() {
        unavailableDays = busyDays.map((day) => DateTime.parse(day)).toList();
      });
    }
  }

  // Guarda los días ocupados en Firestore
  Future<void> _saveBusyDays(List<DateTime> days) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    final busyDaysToAdd =
        days.map((day) => day.toIso8601String()).toSet().toList();

    try {
      await userRef.update({'busyDays': FieldValue.arrayUnion(busyDaysToAdd)});
      setState(() {
        unavailableDays.addAll(days);
        unavailableDays = unavailableDays.toSet().toList();
        if (!multiSelectMode) {
          selectedDay = null;
        }
      });
    } catch (e) {
      // Se ha omitido el log sensible
    }
  }

  // Elimina los días ocupados de Firestore
  Future<void> _removeBusyDays(List<DateTime> days) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    final busyDaysToRemove = days.map((day) => day.toIso8601String()).toList();

    try {
      await userRef.update({
        'busyDays': FieldValue.arrayRemove(busyDaysToRemove),
      });

      setState(() {
        unavailableDays.removeWhere(
          (d) => days.any(
            (day) =>
                d.year == day.year && d.month == day.month && d.day == day.day,
          ),
        );
        if (!multiSelectMode) {
          selectedDay = null;
        }
      });
    } catch (e) {
      // Se ha omitido el log sensible
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Stack(
      children: [
        Container(
          color: colorScheme['primaryColor'],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.selectBusyDaysTitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme['secondaryColor'],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      activeDialog = 'multiSelect';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colorScheme['primaryColorLight'],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colorScheme['secondaryColor']!,
                              width: 2,
                            ),
                          ),
                          child:
                              multiSelectMode
                                  ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: colorScheme['essentialColor'],
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.selectMultipleDays,
                          style: TextStyle(
                            color: colorScheme['secondaryColor'],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CalendarGrid(
                  month: selectedMonth,
                  unavailableDays: unavailableDays,
                  selectedDays: selectedDays,
                  multiSelectMode: multiSelectMode,
                  onDaySelected: (day) {
                    setState(() {
                      if (multiSelectMode) {
                        if (selectedDays.contains(day)) {
                          selectedDays.remove(day);
                        } else {
                          selectedDays.add(day);
                        }
                      } else {
                        selectedDay = day;
                        if (unavailableDays.any(
                          (d) =>
                              d.year == day.year &&
                              d.month == day.month &&
                              d.day == day.day,
                        )) {
                          activeDialog = 'unmark';
                        } else {
                          activeDialog = 'mark';
                        }
                      }
                    });
                  },
                  currentDate: currentDate,
                ),
                if (multiSelectMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    colorScheme['primaryColorLight'],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 36),
                              ),
                              onPressed: () {
                                setState(() {
                                  multiSelectMode = false;
                                  selectedDays.clear();
                                });
                              },
                              child: Text(
                                AppStrings.cancel,
                                style: TextStyle(
                                  color: colorScheme['secondaryColor'],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    colorScheme['primaryColorLight'],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 36),
                              ),
                              onPressed: () {
                                if (selectedDays.isNotEmpty) {
                                  setState(() {
                                    activeDialog = 'mark';
                                  });
                                }
                              },
                              child: Text(
                                AppStrings.save,
                                style: TextStyle(
                                  color: colorScheme['secondaryColor'],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (activeDialog == 'multiSelect')
          _buildDialog(
            context,
            title:
                multiSelectMode
                    ? AppStrings.disableMultiSelectTitle
                    : AppStrings.enableMultiSelectTitle,
            content:
                multiSelectMode
                    ? AppStrings.disableMultiSelectQuestion
                    : AppStrings.enableMultiSelectQuestion,
            onAccept: () {
              setState(() {
                multiSelectMode = !multiSelectMode;
                selectedDays.clear();
                activeDialog = null;
              });
            },
          ),
        if (activeDialog == 'mark')
          _buildDialog(
            context,
            title:
                multiSelectMode
                    ? AppStrings.updateBusyDaysTitle
                    : AppStrings.markAsBusyTitle,
            content:
                multiSelectMode
                    ? AppStrings.updateDaysStatusQuestion.replaceFirst(
                      '%d',
                      selectedDays.length.toString(),
                    )
                    : AppStrings.markDayAsBusyQuestion
                        .replaceFirst('%d', selectedDay!.day.toString())
                        .replaceFirst('%d', selectedDay!.month.toString()),
            onAccept: () async {
              try {
                if (multiSelectMode) {
                  final daysToUnmark =
                      selectedDays
                          .where(
                            (day) => unavailableDays.any(
                              (d) =>
                                  d.year == day.year &&
                                  d.month == day.month &&
                                  d.day == day.day,
                            ),
                          )
                          .toList();

                  final daysToMark =
                      selectedDays
                          .where(
                            (day) =>
                                !unavailableDays.any(
                                  (d) =>
                                      d.year == day.year &&
                                      d.month == day.month &&
                                      d.day == day.day,
                                ),
                          )
                          .toList();

                  if (daysToUnmark.isNotEmpty) {
                    await _removeBusyDays(daysToUnmark);
                  }
                  if (daysToMark.isNotEmpty) {
                    await _saveBusyDays(daysToMark);
                  }

                  setState(() {
                    selectedDays.clear();
                    multiSelectMode = false;
                  });
                } else {
                  await _saveBusyDays([selectedDay!]);
                }
              } finally {
                setState(() {
                  activeDialog = null;
                });
              }
            },
          ),
        if (activeDialog == 'unmark')
          _buildDialog(
            context,
            title: AppStrings.unmarkBusyDayTitle,
            content: AppStrings.unmarkDayQuestion
                .replaceFirst('%d', selectedDay!.day.toString())
                .replaceFirst('%d', selectedDay!.month.toString()),
            onAccept: () async {
              try {
                await _removeBusyDays([selectedDay!]);
              } finally {
                setState(() {
                  activeDialog = null;
                });
              }
            },
          ),
      ],
    );
  }

  // Construcción del cuadro de diálogo
  Widget _buildDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onAccept,
  }) {
    final colorScheme = ColorPalette.getPalette(context);

    return Center(
      child: AlertDialog(
        backgroundColor: colorScheme['primaryColorLight'],
        title: Text(
          title,
          style: TextStyle(color: colorScheme['secondaryColor']),
        ),
        content: Text(
          content,
          style: TextStyle(color: colorScheme['secondaryColor']),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                activeDialog = null;
              });
            },
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: colorScheme['essentialColor']),
            ),
          ),
          TextButton(
            onPressed: onAccept,
            child: Text(
              AppStrings.accept,
              style: TextStyle(color: colorScheme['essentialColor']),
            ),
          ),
        ],
      ),
    );
  }
}
