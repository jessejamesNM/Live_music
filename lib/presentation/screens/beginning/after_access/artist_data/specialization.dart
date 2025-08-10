/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla que permite al usuario seleccionar el tipo de evento en el que se
/// especializa como artista o proveedor de servicios. La selección se muestra
/// visualmente mediante tarjetas en una cuadrícula, con un botón para continuar
/// una vez que se ha hecho una elección.
///
/// Recomendaciones:
/// - Añadir animaciones suaves para mejorar la experiencia al seleccionar una opción.
/// - Incluir una opción de deshacer la selección o marcar varias especialidades.
/// - Agregar descripciones o íconos para cada tipo de evento para mayor claridad.
///
/// Características:
/// - Usa `GridView.count` para mostrar las opciones de forma compacta y visual.
/// - Permite seleccionar un solo tipo de evento con retroalimentación visual.
/// - Integra `BeginningProvider` para almacenar y recuperar la selección.
/// - Muestra un botón de "Continuar" solo cuando se ha seleccionado un evento.
/// - Navega a la siguiente pantalla utilizando `GoRouter`.
/// - Compatible con temas personalizados mediante `ColorPalette`.
/// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:go_router/go_router.dart';

class EventSpecializationScreen extends StatelessWidget {
  final GoRouter goRouter;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  final List<MapEntry<String, String?>> eventTypeEntries = [
    MapEntry(AppStrings.weddings, 'assets/svg/ic_marriage.svg'),
    MapEntry(AppStrings.quinceaneras, 'assets/svg/ic_quinceanera.svg'),
    MapEntry(AppStrings.casualParties, 'assets/svg/ic_party.svg'),
    MapEntry(AppStrings.publicEvents, 'assets/svg/ic_public_event.svg'),
    MapEntry('Cumpleaños', 'assets/svg/ic_birthday.svg'),
    MapEntry('Conferencia', 'assets/svg/ic_conferencia.svg'),
    MapEntry('Posada', 'assets/svg/ic_piñata.svg'),
    MapEntry('Graduación', 'assets/svg/ic_graduaciones.svg'),
    MapEntry(AppStrings.noParticularEvent, null), // Sin ícono y va al final
  ];

  EventSpecializationScreen({
    Key? key,
    required this.goRouter,
    required this.firestore,
    required this.auth,
  }) : super(key: key);

  Future<List<String>> _getCurrentSpecialties() async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) return [];

      final doc =
          await firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final specialties = data[AppStrings.specialtyField] as List<dynamic>?;
        return specialties?.cast<String>() ?? [];
      }
      return [];
    } catch (e) {
      print("Error obteniendo especialidades: $e");
      return [];
    }
  }

  Future<void> _updateSpecialty(String event, bool isCurrentlySelected) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) return;

      if (isCurrentlySelected) {
        await firestore.collection('users').doc(currentUser.uid).update({
          AppStrings.specialtyField: FieldValue.arrayRemove([event]),
        });
      } else {
        await firestore.collection('users').doc(currentUser.uid).update({
          AppStrings.specialtyField: FieldValue.arrayUnion([event]),
        });
      }
    } catch (e) {
      print("Error actualizando especialidad: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      appBar: AppBar(
        backgroundColor: colorScheme[AppStrings.primaryColor],
        iconTheme: IconThemeData(color: colorScheme[AppStrings.secondaryColor]),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<BeginningProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Text(
                  AppStrings.eventSpecializationQuestion,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children:
                        eventTypeEntries.map((entry) {
                          final event = entry.key;
                          final iconPath = entry.value;

                          return FutureBuilder<List<String>>(
                            future: _getCurrentSpecialties(),
                            builder: (context, snapshot) {
                              final isSelected =
                                  snapshot.hasData
                                      ? snapshot.data!.contains(event)
                                      : provider.selectedEvents.contains(event);

                              return GestureDetector(
                                onTap: () async {
                                  final currentSpecialties =
                                      await _getCurrentSpecialties();
                                  final isCurrentlySelected = currentSpecialties
                                      .contains(event);
                                  await _updateSpecialty(
                                    event,
                                    isCurrentlySelected,
                                  );
                                  provider.toggleEventSelection(event);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? colorScheme[AppStrings
                                                .essentialColor]
                                            : colorScheme[AppStrings
                                                .primaryColor],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? colorScheme[AppStrings
                                                  .essentialColor]!
                                              : colorScheme[AppStrings
                                                      .secondaryColor]!
                                                  .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                color: colorScheme[AppStrings
                                                        .essentialColor]!
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (iconPath != null) ...[
                                        SvgPicture.asset(
                                          iconPath,
                                          height: 40,
                                          colorFilter: ColorFilter.mode(
                                            isSelected
                                                ? colorScheme[AppStrings
                                                    .primaryColor]!
                                                : colorScheme[AppStrings
                                                    .secondaryColor]!,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      Text(
                                        event,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? colorScheme[AppStrings
                                                      .primaryColor]
                                                  : colorScheme[AppStrings
                                                      .secondaryColor],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final currentSpecialties = await _getCurrentSpecialties();
                      if (currentSpecialties.isNotEmpty) {
                        goRouter.go(AppStrings.priceScreenRoute);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona al menos un evento'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme[AppStrings.essentialColor],
                      foregroundColor: colorScheme[AppStrings.primaryColor],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    child: Text(
                      AppStrings.myContinue,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme[AppStrings.primaryColor],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
