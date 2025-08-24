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

class UserCanWorkCountryStateScreen extends StatelessWidget {
  final GoRouter goRouter;

  const UserCanWorkCountryStateScreen({Key? key, required this.goRouter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final titleFontSize = screenWidth * 0.06;
    final subtitleFontSize = screenWidth * 0.045;
    final buttonFontSize = screenWidth * 0.045;
    final chipFontSize = screenWidth * 0.04;
    final borderRadius = screenWidth * 0.04;
    final spacingVertical = screenHeight * 0.02;
    final paddingAll = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: EdgeInsets.all(paddingAll),
        child: Consumer<BeginningProvider>(
          builder: (context, provider, child) {
            provider.setIncludeAllStatesOption(true);

            Widget buildMultiSelectWithChips({
              required String hint,
              required List<String> items,
              required List<String> selectedItems,
              required Function(String) onItemSelected,
              required Function(String) onItemRemoved,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedItems.isNotEmpty)
                    Wrap(
                      spacing: spacingVertical * 0.4,
                      runSpacing: spacingVertical * 0.4,
                      children: selectedItems.map((item) {
                        return Chip(
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item,
                              style: TextStyle(
                                color: colorScheme[AppStrings.primaryColor],
                                fontSize: chipFontSize,
                              ),
                            ),
                          ),
                          backgroundColor: colorScheme[AppStrings.essentialColor],
                          deleteIconColor: colorScheme[AppStrings.primaryColor],
                          onDeleted: () => onItemRemoved(item),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: spacingVertical),
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme[AppStrings.primaryColor],
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(
                          color: colorScheme[AppStrings.secondaryColor]!
                              .withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        title: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hint,
                            style: TextStyle(
                              color: selectedItems.isEmpty
                                  ? colorScheme[AppStrings.secondaryColor]
                                      ?.withOpacity(0.7)
                                  : colorScheme[AppStrings.secondaryColor],
                              fontSize: subtitleFontSize,
                            ),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme[AppStrings.secondaryColor],
                          size: screenWidth * 0.08,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Consumer<BeginningProvider>(
                                builder: (context, provider, child) {
                                  return AlertDialog(
                                    title: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        hint,
                                        style: TextStyle(fontSize: subtitleFontSize),
                                      ),
                                    ),
                                    content: SingleChildScrollView(
                                      child: ListBody(
                                        children: items.map((item) {
                                          return CheckboxListTile(
                                            title: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                item,
                                                style: TextStyle(
                                                  fontSize: chipFontSize,
                                                ),
                                              ),
                                            ),
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
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Cerrar',
                                            style: TextStyle(
                                              color: colorScheme[AppStrings.essentialColor],
                                              fontSize: subtitleFontSize,
                                            ),
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
                SizedBox(height: spacingVertical * 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.whereCanWorkQuestion,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                ),
                SizedBox(height: spacingVertical * 1.5),
                buildMultiSelectWithChips(
                  hint: AppStrings.selectCountries,
                  items: provider.countries,
                  selectedItems: provider.selectedCountries,
                  onItemSelected: provider.selectCountry,
                  onItemRemoved: provider.removeCountry,
                ),
                if (provider.selectedCountries.length == 1) ...[
                  SizedBox(height: spacingVertical * 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.whereCanWorkStatesQuestion,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                  SizedBox(height: spacingVertical),
                  buildMultiSelectWithChips(
                    hint: AppStrings.selectStates,
                    items: provider.states,
                    selectedItems: provider.selectedStates,
                    onItemSelected: provider.selectState,
                    onItemRemoved: provider.removeState,
                  ),
                ],
                Spacer(),
                if (provider.selectedCountries.isNotEmpty &&
                    (provider.selectedCountries.length > 1 ||
                        provider.selectedStates.isNotEmpty))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.saveSelection(context, goRouter);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme[AppStrings.essentialColor],
                        foregroundColor: colorScheme[AppStrings.primaryColor],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        padding: EdgeInsets.symmetric(vertical: spacingVertical),
                        elevation: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppStrings.myContinue,
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.bold,
                            color: colorScheme[AppStrings.primaryColor],
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: spacingVertical),
              ],
            );
          },
        ),
      ),
    );
  }
}