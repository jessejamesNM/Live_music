/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla de selección de país y estado para el perfil del usuario dentro del flujo inicial.
/// Permite seleccionar un país de una lista proporcionada y, si se elige uno,
/// muestra la lista de estados correspondientes para su selección.
/// Al tener ambos valores seleccionados, el usuario puede continuar al siguiente paso.
///
/// Recomendaciones:
/// - Asegúrate de que las listas `countries` y `states` estén correctamente cargadas en el `BeginningProvider`.
/// - La selección debe ser válida antes de permitir continuar.
/// - Considera manejar errores o vacíos en las listas desde el backend o el provider.
///
/// Características:
/// - Dropdown dinámico para países y estados.
/// - Validación automática de selección (ambos campos requeridos).
/// - Botón de continuación habilitado solo si se han hecho ambas selecciones.
/// - Diseño responsivo y adaptado al esquema de color definido en el proyecto.
/// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:go_router/go_router.dart';

class CountryStateScreen extends StatelessWidget {
  final GoRouter goRouter;

  const CountryStateScreen({Key? key, required this.goRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<BeginningProvider>(
          builder: (context, beginningProvider, child) {
            // Obtener las selecciones actuales
            final String selectedCountry = beginningProvider.selectedCountry.isNotEmpty
                ? beginningProvider.selectedCountry
                : '';
            final String selectedState = beginningProvider.selectedState.isNotEmpty
                ? beginningProvider.selectedState
                : '';

            beginningProvider.setIncludeAllStatesOption(false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  AppStrings.stateAndCountryQuestion,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                const SizedBox(height: 32),

                // Dropdown de país
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme[AppStrings.primaryColor],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: colorScheme[AppStrings.primaryColor],
                      value: selectedCountry.isNotEmpty ? selectedCountry : null,
                      hint: Text(
                        AppStrings.selectCountry,
                        style: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                      items: beginningProvider.countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(
                            country,
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          // Limpiar la selección de estado cuando se cambia el país
                          beginningProvider.selectOneCountry(newValue);
                          beginningProvider.clearStates(); // Asegúrate de tener este método en tu provider
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Dropdown de estado (solo visible si hay un país seleccionado)
                if (selectedCountry.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme[AppStrings.primaryColor],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: colorScheme[AppStrings.primaryColor],
                        value: selectedState.isNotEmpty ? selectedState : null,
                        hint: Text(
                          AppStrings.selectState,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        items: beginningProvider.oneStates.map((String state) {
                          return DropdownMenuItem<String>(
                            value: state,
                            child: Text(
                              state,
                              style: TextStyle(
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            beginningProvider.selectOneState(newValue);
                          }
                        },
                      ),
                    ),
                  ),

                const Spacer(),

                // Botón de continuar (solo visible si hay selección completa)
                if (selectedCountry.isNotEmpty && selectedState.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveSelection(context, beginningProvider, goRouter),
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

  Future<void> _saveSelection(
    BuildContext context,
    BeginningProvider provider,
    GoRouter goRouter,
  ) async {
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final currentUserId = auth.currentUser?.uid;

    if (currentUserId == null) return;

    try {
      final String country = provider.selectedCountry.isNotEmpty
          ? provider.selectedCountry
          : '';
      final String state = provider.selectedState.isNotEmpty 
          ? provider.selectedState
          : '';

      if (country.isEmpty || state.isEmpty) {
        throw Exception('Por favor selecciona un país y un estado');
      }

      await db.collection("users").doc(currentUserId).update({
        "country": country,
        "state": state,
      });

      goRouter.go("/welcomescreen");
    } catch (e) {
      print("Error al guardar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: ${e.toString()}")),
      );
    }
  }
}
