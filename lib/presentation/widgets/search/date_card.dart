import 'package:flutter/material.dart';

import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/search/calendar_grid.dart';
import 'package:live_music/presentation/resources/colors.dart';

class DateCard extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  DateCard({required this.selectedDate, required this.onDateSelected});

  @override
  _DateCardState createState() => _DateCardState();
}

class _DateCardState extends State<DateCard> {
  final DateTime _selectedMonth = DateTime.now();
  final DateTime _currentDate = DateTime.now();
  Set<DateTime> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      _selectedDays.add(
        DateTime(
          widget.selectedDate!.year,
          widget.selectedDate!.month,
          widget.selectedDate!.day,
        ),
      );
    }
  }

  void _handleDaySelected(DateTime day) {
    setState(() {
      _selectedDays = {DateTime(day.year, day.month, day.day)};
    });
    widget.onDateSelected(day);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.dateNeededQuestion, // Reemplazo de string aquí
          style: TextStyle(
            fontSize: 22,
            color: colorScheme[AppStrings.secondaryColor],
          ), // Reemplazo de color aquí
        ),
        SizedBox(height: 8),
        CalendarGrid(
          month: _selectedMonth,
          unavailableDays: [],
          selectedDays: _selectedDays,
          multiSelectMode: false,
          onDaySelected: _handleDaySelected,
          currentDate: _currentDate,
        ),
      ],
    );
  }
}
