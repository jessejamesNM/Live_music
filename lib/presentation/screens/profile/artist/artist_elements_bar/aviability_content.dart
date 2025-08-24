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

  Future<void> _loadBusyDays() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      final busyDays = List<String>.from(doc.data()?['busyDays'] ?? []);
      setState(() {
        unavailableDays = busyDays.map((day) => DateTime.parse(day)).toList();
      });
    }
  }

  Future<void> _saveBusyDays(List<DateTime> days) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final busyDaysToAdd = days.map((d) => d.toIso8601String()).toSet().toList();

    try {
      await userRef.update({'busyDays': FieldValue.arrayUnion(busyDaysToAdd)});
      setState(() {
        unavailableDays.addAll(days);
        unavailableDays = unavailableDays.toSet().toList();
        if (!multiSelectMode) selectedDay = null;
      });
    } catch (_) {}
  }

  Future<void> _removeBusyDays(List<DateTime> days) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final busyDaysToRemove = days.map((d) => d.toIso8601String()).toList();

    try {
      await userRef.update({'busyDays': FieldValue.arrayRemove(busyDaysToRemove)});
      setState(() {
        unavailableDays.removeWhere(
            (d) => days.any((day) => d.year == day.year && d.month == day.month && d.day == day.day));
        if (!multiSelectMode) selectedDay = null;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Tamaños adaptativos
    final padding = screenWidth * 0.04;
    final iconSize = screenWidth * 0.06;
    final textFontSize = screenWidth * 0.045;
    final titleFontSize = screenWidth * 0.05;
    final buttonHeight = screenHeight * 0.06;
    final spacing = screenHeight * 0.02;
    final checkBoxSize = screenWidth * 0.06;

    return Stack(
      children: [
        Container(
          color: colorScheme['primaryColor'],
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.selectBusyDaysTitle,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: colorScheme['secondaryColor'],
                    ),
                  ),
                ),
                SizedBox(height: spacing * 0.5),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      activeDialog = 'multiSelect';
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacing * 0.25),
                    child: Row(
                      children: [
                        Container(
                          width: checkBoxSize,
                          height: checkBoxSize,
                          decoration: BoxDecoration(
                            color: colorScheme['primaryColorLight'],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colorScheme['secondaryColor']!,
                              width: 2,
                            ),
                          ),
                          child: multiSelectMode
                              ? Icon(Icons.check,
                                  size: checkBoxSize * 0.7,
                                  color: colorScheme['essentialColor'])
                              : null,
                        ),
                        SizedBox(width: spacing * 0.25),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.selectMultipleDays,
                            style: TextStyle(
                              color: colorScheme['secondaryColor'],
                              fontSize: textFontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                Expanded(
                  child: CalendarGrid(
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
                              (d) => d.year == day.year && d.month == day.month && d.day == day.day)) {
                            activeDialog = 'unmark';
                          } else {
                            activeDialog = 'mark';
                          }
                        }
                      });
                    },
                    currentDate: currentDate,
                  ),
                ),
                if (multiSelectMode)
                  Padding(
                    padding: EdgeInsets.only(top: spacing),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: spacing * 0.25),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme['primaryColorLight'],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, buttonHeight),
                              ),
                              onPressed: () {
                                setState(() {
                                  multiSelectMode = false;
                                  selectedDays.clear();
                                });
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppStrings.cancel,
                                  style: TextStyle(
                                    color: colorScheme['secondaryColor'],
                                    fontSize: textFontSize,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: spacing * 0.25),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme['primaryColorLight'],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, buttonHeight),
                              ),
                              onPressed: () {
                                if (selectedDays.isNotEmpty) {
                                  setState(() {
                                    activeDialog = 'mark';
                                  });
                                }
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppStrings.save,
                                  style: TextStyle(
                                    color: colorScheme['secondaryColor'],
                                    fontSize: textFontSize,
                                  ),
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
        if (activeDialog != null)
          _buildDialog(context, activeDialog!),
      ],
    );
  }

  Widget _buildDialog(BuildContext context, String dialogType) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final textFontSize = screenWidth * 0.045;

    String title = '';
    String content = '';
    VoidCallback? onAccept;

    switch (dialogType) {
      case 'multiSelect':
        title = multiSelectMode
            ? AppStrings.disableMultiSelectTitle
            : AppStrings.enableMultiSelectTitle;
        content = multiSelectMode
            ? AppStrings.disableMultiSelectQuestion
            : AppStrings.enableMultiSelectQuestion;
        onAccept = () {
          setState(() {
            multiSelectMode = !multiSelectMode;
            selectedDays.clear();
            activeDialog = null;
          });
        };
        break;
      case 'mark':
        title = multiSelectMode
            ? AppStrings.updateBusyDaysTitle
            : AppStrings.markAsBusyTitle;
        content = multiSelectMode
            ? AppStrings.updateDaysStatusQuestion.replaceFirst('%d', selectedDays.length.toString())
            : AppStrings.markDayAsBusyQuestion
                .replaceFirst('%d', selectedDay!.day.toString())
                .replaceFirst('%d', selectedDay!.month.toString());
        onAccept = () async {
          try {
            if (multiSelectMode) {
              final daysToUnmark = selectedDays
                  .where((day) => unavailableDays.any(
                      (d) => d.year == day.year && d.month == day.month && d.day == day.day))
                  .toList();
              final daysToMark = selectedDays
                  .where((day) => !unavailableDays.any(
                      (d) => d.year == day.year && d.month == day.month && d.day == day.day))
                  .toList();
              if (daysToUnmark.isNotEmpty) await _removeBusyDays(daysToUnmark);
              if (daysToMark.isNotEmpty) await _saveBusyDays(daysToMark);
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
        };
        break;
      case 'unmark':
        title = AppStrings.unmarkBusyDayTitle;
        content = AppStrings.unmarkDayQuestion
            .replaceFirst('%d', selectedDay!.day.toString())
            .replaceFirst('%d', selectedDay!.month.toString());
        onAccept = () async {
          try {
            await _removeBusyDays([selectedDay!]);
          } finally {
            setState(() {
              activeDialog = null;
            });
          }
        };
        break;
    }

    return Center(
      child: AlertDialog(
        backgroundColor: colorScheme['primaryColorLight'],
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(title, style: TextStyle(color: colorScheme['secondaryColor'], fontSize: textFontSize)),
        ),
        content: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(content, style: TextStyle(color: colorScheme['secondaryColor'], fontSize: textFontSize)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                activeDialog = null;
              });
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AppStrings.cancel, style: TextStyle(color: colorScheme['essentialColor'], fontSize: textFontSize)),
            ),
          ),
          TextButton(
            onPressed: onAccept,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(AppStrings.accept, style: TextStyle(color: colorScheme['essentialColor'], fontSize: textFontSize)),
            ),
          ),
        ],
      ),
    );
  }
}