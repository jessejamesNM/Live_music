/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla que permite al usuario seleccionar los países y estados donde puede
/// trabajar. Usa un sistema de selección múltiple con chips y menús desplegables.
/// Si el usuario selecciona un solo país, también puede especificar estados dentro
/// de ese país. Los datos se almacenan en el estado mediante `BeginningProvider`.
///
/// Recomendaciones:
/// - Implementar validaciones para evitar combinaciones inválidas de país-estado.
/// - Añadir feedback visual al guardar la selección (snackbars, loader, etc.).
/// - Considerar permitir búsqueda rápida dentro de los dropdowns si hay muchas opciones.
///
/// Características:
/// - Selección múltiple de países y estados con chips removibles.
/// - Menú desplegable personalizado visualmente para agregar nuevos ítems.
/// - Botón de "Continuar" habilitado solo si la selección es válida.
/// - Diseño responsivo y estilizado con colores definidos por `ColorPalette`.
/// - Lógica de control de visibilidad condicional basada en la selección actual.
/// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

// Pantalla donde el usuario selecciona los países y estados en los que puede trabajar
class UserCanWorkCountryStateScreen extends StatelessWidget {
  final GoRouter goRouter;

  const UserCanWorkCountryStateScreen({Key? key, required this.goRouter})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se obtiene la paleta de colores para aplicar estilo según el tema
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<BeginningProvider>(
          builder: (context, provider, child) {
            // Se configura la opción de incluir todos los estados
            provider.setIncludeAllStatesOption(true);

            // Widget que crea un selector múltiple con chips para seleccionar países/estados
            Widget buildMultiSelectWithChips({
              required String hint, // Texto que aparece cuando no hay selección
              required List<String> items, // Elementos disponibles para seleccionar
              required List<String> selectedItems, // Elementos ya seleccionados
              required Function(String) onItemSelected, // Función para añadir un elemento
              required Function(String) onItemRemoved, // Función para eliminar un elemento
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muestra los chips de los elementos seleccionados
                  if (selectedItems.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedItems.map((item) {
                        return Chip(
                          label: Text(item),
                          backgroundColor: colorScheme[AppStrings.essentialColor],
                          deleteIconColor: colorScheme[AppStrings.primaryColor],
                          onDeleted: () => onItemRemoved(item), // Elimina el chip seleccionado
                          labelStyle: TextStyle(
                            color: colorScheme[AppStrings.primaryColor],
                          ),
                        );
                      }).toList(),
                    ),

                  // Botón para abrir el diálogo de selección múltiple
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme[AppStrings.primaryColor],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          hint,
                          style: TextStyle(
                            color: selectedItems.isEmpty
                                ? colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7)
                                : colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        onTap: () {
                          // Mostrar el diálogo de selección múltiple
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Consumer<BeginningProvider>(
                                builder: (context, provider, child) {
                                  return AlertDialog(
                                    title: Text(hint),
                                    content: SingleChildScrollView(
                                      child: ListBody(
                                        children: items.map((item) {
                                          return CheckboxListTile(
                                            title: Text(item),
                                            value: selectedItems.contains(item),
                                            onChanged: (bool? value) {
                                              if (value != null) {
                                                if (value) {
                                                  onItemSelected(item);
                                                } else {
                                                  onItemRemoved(item);
                                                }
                                              }
                                            },
                                            activeColor: colorScheme[AppStrings.essentialColor],
                                            checkColor: colorScheme[AppStrings.primaryColor],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          'Cerrar',
                                          style: TextStyle(
                                            color: colorScheme[AppStrings.essentialColor],
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Título de la pregunta sobre los países en los que se puede trabajar
                Text(
                  AppStrings.whereCanWorkQuestion,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                const SizedBox(height: 24),

                // Selector múltiple de países
                buildMultiSelectWithChips(
                  hint: AppStrings.selectCountries,
                  items: provider.countries,
                  selectedItems: provider.selectedCountries,
                  onItemSelected: provider.selectCountry,
                  onItemRemoved: provider.removeCountry,
                ),

                // Solo mostrar selector de estados si se selecciona exactamente 1 país
                if (provider.selectedCountries.length == 1) ...[
                  const SizedBox(height: 32),
                  // Título de la pregunta sobre los estados en los que se puede trabajar
                  Text(
                    AppStrings.whereCanWorkStatesQuestion,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selector múltiple de estados
                  buildMultiSelectWithChips(
                    hint: AppStrings.selectStates,
                    items: provider.states,
                    selectedItems: provider.selectedStates,
                    onItemSelected: provider.selectState,
                    onItemRemoved: provider.removeState,
                  ),
                ],

                const Spacer(),

                // Mostrar botón solo si hay al menos un país seleccionado
                // y si es un solo país, también al menos un estado seleccionado
                if (provider.selectedCountries.isNotEmpty &&
                    (provider.selectedCountries.length > 1 ||
                        provider.selectedStates.isNotEmpty))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.saveSelection(
                          context,
                          goRouter,
                        ); // Guarda la selección del usuario
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
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}