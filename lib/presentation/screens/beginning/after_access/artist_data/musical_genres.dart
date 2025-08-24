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
    final colorScheme = ColorPalette.getPalette(context);

    // Tamaños relativos a la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double baseText = screenWidth * 0.04; // tamaño base de texto
    final double titleText = screenWidth * 0.05; // título adaptable
    final double paddingValue = screenWidth * 0.04; // padding adaptable

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],

      appBar: AppBar(
        title: Text(
          AppStrings.genresPlayedByGroupQuestion,
          style: TextStyle(
            color: colorScheme[AppStrings.secondaryColor],
            fontWeight: FontWeight.bold,
            fontSize: titleText.clamp(16.0, 24.0), // se adapta, con límites
          ),
        ),
        backgroundColor: colorScheme[AppStrings.primaryColor],
        iconTheme: IconThemeData(
          color: colorScheme[AppStrings.secondaryColor],
          size: screenWidth * 0.06, // iconos adaptativos
        ),
        elevation: 0,
      ),

      body: Padding(
        padding: EdgeInsets.all(paddingValue),
        child: Column(
          children: [
            // Grid con tarjetas adaptativas
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardTextSize = constraints.maxWidth * 0.07;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth < 600 ? 2 : 3,
                      crossAxisSpacing: paddingValue * 0.7,
                      mainAxisSpacing: paddingValue * 0.7,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: genres.length,
                    itemBuilder: (context, index) {
                      String genre = genres[index];

                      return Consumer<BeginningProvider>(
                        builder: (context, provider, child) {
                          bool isSelected =
                              provider.selectedGenres.contains(genre);

                          return GestureDetector(
                            onTap: () => provider.toggleGenre(genre),
                            child: Card(
                              color: isSelected
                                  ? colorScheme[AppStrings.essentialColor]
                                  : colorScheme[AppStrings.primaryColor],
                              elevation: isSelected ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: BorderSide(
                                  color: isSelected
                                      ? colorScheme[AppStrings.essentialColor]!
                                      : colorScheme[AppStrings.secondaryColor]!
                                          .withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(paddingValue * 0.4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      genre,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: cardTextSize.clamp(12.0, 20.0),
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? colorScheme[
                                                AppStrings.primaryColor]
                                            : colorScheme[
                                                AppStrings.secondaryColor],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            Consumer<BeginningProvider>(
              builder: (context, provider, child) {
                return provider.selectedGenres.isNotEmpty
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              provider.saveGenres(context, goRouter),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme[AppStrings.essentialColor],
                            foregroundColor:
                                colorScheme[AppStrings.primaryColor],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                            ),
                            elevation: 4.0,
                          ),
                          child: Text(
                            AppStrings.myContinue,
                            style: TextStyle(
                              fontSize: baseText.clamp(14.0, 20.0),
                              fontWeight: FontWeight.bold,
                              color: colorScheme[AppStrings.primaryColor],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}