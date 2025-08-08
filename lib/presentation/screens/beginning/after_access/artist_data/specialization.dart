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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:go_router/go_router.dart';

// Pantalla donde el usuario selecciona el tipo de evento en el que se especializa
class EventSpecializationScreen extends StatelessWidget {
  final GoRouter goRouter;

  // Lista de tipos de eventos disponibles
  final List<String> eventTypes = [
    AppStrings.weddings, // Bodas
    AppStrings.quinceaneras, // Quinceañeras
    AppStrings.casualParties, // Fiestas casuales
    AppStrings.publicEvents, // Eventos públicos
    AppStrings.noParticularEvent, // Ningún evento en particular
  ];

  EventSpecializationScreen({Key? key, required this.goRouter})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se obtiene la paleta de colores para aplicar estilo según el tema
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
                // Pregunta principal de la pantalla
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

                // Contenedor principal con Grid de botones
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2, // 2 columnas
                    mainAxisSpacing: 16, // Espacio vertical entre ítems
                    crossAxisSpacing: 16, // Espacio horizontal entre ítems
                    childAspectRatio: 1.5, // Relación de aspecto del botón
                    // Genera una lista de botones por cada tipo de evento
                    children:
                        eventTypes.map((event) {
                          final isSelected = provider.selectedEvent == event;

                          return GestureDetector(
                            onTap:
                                () => provider.selectEvent(
                                  event,
                                ), // Selecciona el evento
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? colorScheme[AppStrings
                                            .essentialColor] // Color si está seleccionado
                                        : colorScheme[AppStrings
                                            .primaryColor], // Color normal
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
                                            offset: Offset(0, 4),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    event, // Nombre del evento
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected
                                              ? colorScheme[AppStrings
                                                  .primaryColor]
                                              : colorScheme[AppStrings
                                                  .secondaryColor],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón de continuar que solo aparece si hay un evento seleccionado
                if (provider.selectedEvent != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => provider.saveSpecialty(context, goRouter),
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
