import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/search/calendar_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_music/presentation/resources/colors.dart';

// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción:
// Esta pantalla permite gestionar los días en los que un usuario está ocupado
// dentro de una aplicación de música en vivo. Los usuarios pueden seleccionar
// o desmarcar días como ocupados, con la opción de seleccionar múltiples días
// a la vez en un calendario interactivo. Los días ocupados se sincronizan con Firestore,
// permitiendo que se almacenen o eliminen en la base de datos.
//
// Recomendaciones:
// - Asegúrate de tener configurada la colección 'users' en Firestore con un campo 'busyDays'.
// - Puedes personalizar el calendario para agregar más interactividad o validaciones si lo deseas.
// - La gestión de fechas puede ser compleja, ten cuidado con las zonas horarias y formatos de fecha.
//
// Características:
// - Selección de un solo día o múltiples días.
// - Sincronización con Firestore para almacenar y eliminar días ocupados.
// - Interfaz limpia y accesible para los usuarios.

class AvailabilityContentWS extends StatefulWidget {
  final String userId;

  const AvailabilityContentWS({required this.userId, Key? key})
    : super(key: key);

  @override
  _AvailabilityContentWSState createState() => _AvailabilityContentWSState();
}

class _AvailabilityContentWSState extends State<AvailabilityContentWS> {
  DateTime currentDate = DateTime.now(); // Fecha actual para mostrar en el calendario
  DateTime selectedMonth = DateTime.now(); // Mes seleccionado en el calendario
  List<DateTime> unavailableDays = []; // Días en los que el usuario está ocupado

  @override
  void initState() {
    super.initState();
    _loadBusyDays(); // Carga los días ocupados del usuario desde Firestore
  }

  // Cargar los días ocupados del usuario desde Firestore
  Future<void> _loadBusyDays() async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);
    final doc = await userRef.get();
    if (doc.exists) {
      final busyDays = List<String>.from(doc.data()?['busyDays'] ?? []);
      setState(() {
        // Convierte los días ocupados a objetos DateTime
        unavailableDays = busyDays.map((day) => DateTime.parse(day)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context); // Obtener paleta de colores

    return Container(
      color: colorScheme[AppStrings.primaryColor],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título de la sección
            Text(
              AppStrings.selectBusyDays,
              style: TextStyle(
                fontSize: 18,
                color: colorScheme[AppStrings.secondaryColor],
              ),
            ),
            const SizedBox(height: 16),
            // Calendario donde se muestran los días ocupados
            CalendarGrid(
              month: selectedMonth,
              unavailableDays: unavailableDays,
              selectedDays: const {}, // Vacío ya que no hay selección
              multiSelectMode: false, // Siempre falso
              onDaySelected: (day) {}, // No hace nada
              currentDate: currentDate,
            ),
          ],
        ),
      ),
    );
  }
}