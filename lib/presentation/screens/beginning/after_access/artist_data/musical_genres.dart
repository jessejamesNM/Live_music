/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla que permite a los usuarios seleccionar los géneros musicales que su grupo toca.
/// Forma parte del flujo de onboarding y utiliza una grilla de tarjetas interactivas para cada género.
/// La selección se guarda en el estado del `BeginningProvider` y se puede continuar solo si hay al menos una opción seleccionada.
///
/// Recomendaciones:
/// - Mantener sincronizados los géneros definidos en `AppStrings` para asegurar consistencia.
/// - Considerar añadir animaciones o efectos visuales al seleccionar géneros para mejorar la UX.
/// - Implementar una validación del lado del servidor para verificar que la selección sea válida.
///
/// Características:
/// - Diseño responsive con `GridView` adaptado a dos columnas.
/// - Cambio dinámico de estilo visual en las tarjetas al seleccionarlas.
/// - Uso de `Consumer` para escuchar cambios en `BeginningProvider`.
/// - Botón de continuar activado únicamente si hay géneros seleccionados.
/// - Colores y estilos adaptados a la paleta global de la app (`ColorPalette`).
/// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:go_router/go_router.dart';

// Pantalla que permite al usuario seleccionar los géneros musicales que toca su grupo.
class MusicGenresScreen extends StatelessWidget {
  final GoRouter goRouter;

  // Lista de géneros musicales disponibles.
  final List<String> genres = [
    AppStrings.band,
    AppStrings.nortStyle,
    AppStrings.corridos,
    AppStrings.mariachi,
    AppStrings.montainStyle,
    AppStrings.cumbia,
    AppStrings.reggaeton,
  ];

  // Constructor que recibe el enrutador.
  MusicGenresScreen({Key? key, required this.goRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se obtienen colores personalizados y tema actual.
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],

      // AppBar superior con el título de la pantalla.
      appBar: AppBar(
        title: Text(
          AppStrings
              .genresPlayedByGroupQuestion, // Pregunta al usuario por los géneros.
          style: TextStyle(
            color: colorScheme[AppStrings.secondaryColor],
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        backgroundColor: colorScheme[AppStrings.primaryColor],
        iconTheme: IconThemeData(color: colorScheme[AppStrings.secondaryColor]),
        elevation: 0,
      ),

      // Cuerpo principal de la pantalla.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Grid con tarjetas que representan cada género musical.
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.5,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  String genre = genres[index];

                  // Usamos Consumer para escuchar los cambios del BeginningProvider.
                  return Consumer<BeginningProvider>(
                    builder: (context, provider, child) {
                      // Verificamos si este género está seleccionado.
                      bool isSelected = provider.selectedGenres.contains(genre);

                      return GestureDetector(
                        // Al tocar una tarjeta se alterna su selección.
                        onTap: () => provider.toggleGenre(genre),
                        child: Card(
                          // Color de fondo cambia según si está seleccionado o no.
                          color:
                              isSelected
                                  ? colorScheme[AppStrings.essentialColor]
                                  : colorScheme[AppStrings.primaryColor],
                          elevation: isSelected ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? colorScheme[AppStrings.essentialColor]!
                                      : colorScheme[AppStrings.secondaryColor]!
                                          .withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                genre,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? colorScheme[AppStrings.primaryColor]
                                          : colorScheme[AppStrings
                                              .secondaryColor],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24.0),

            // Botón de continuar, solo visible si al menos un género está seleccionado.
            Consumer<BeginningProvider>(
              builder: (context, provider, child) {
                return provider.selectedGenres.isNotEmpty
                    ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Al presionar, guarda los géneros seleccionados y navega a la siguiente pantalla.
                        onPressed: () => provider.saveGenres(context, goRouter),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme[AppStrings.essentialColor],
                          foregroundColor: colorScheme[AppStrings.primaryColor],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          elevation: 4.0,
                        ),
                        child: Text(
                          AppStrings.myContinue,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: colorScheme[AppStrings.primaryColor],
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(); // Oculta el botón si no hay géneros seleccionados.
              },
            ),
          ],
        ),
      ),
    );
  }
}
