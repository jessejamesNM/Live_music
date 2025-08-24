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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CountryStateScreen extends StatelessWidget {
  final GoRouter goRouter;

  const CountryStateScreen({Key? key, required this.goRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Consumer<BeginningProvider>(
          builder: (context, beginningProvider, child) {
            final String selectedCountry =
                beginningProvider.selectedCountry.isNotEmpty ? beginningProvider.selectedCountry : '';
            final String selectedState =
                beginningProvider.selectedState.isNotEmpty ? beginningProvider.selectedState : '';

            beginningProvider.setIncludeAllStatesOption(false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),

                // Pregunta principal
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.stateAndCountryQuestion,
                    style: TextStyle(
                      fontSize: screenWidth * 0.06, // Escalable
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

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
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: colorScheme[AppStrings.primaryColor],
                      value: selectedCountry.isNotEmpty ? selectedCountry : null,
                      hint: Text(
                        AppStrings.selectCountry,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: screenWidth * 0.07,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                      items: beginningProvider.countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(
                            country,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          beginningProvider.selectOneCountry(newValue);
                          beginningProvider.clearStates();
                        }
                      },
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Dropdown de estado
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
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: colorScheme[AppStrings.primaryColor],
                        value: selectedState.isNotEmpty ? selectedState : null,
                        hint: Text(
                          AppStrings.selectState,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: screenWidth * 0.07,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        items: beginningProvider.oneStates.map((String state) {
                          return DropdownMenuItem<String>(
                            value: state,
                            child: Text(
                              state,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
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

                // Botón continuar
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
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        elevation: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppStrings.myContinue,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: colorScheme[AppStrings.primaryColor],
                          ),
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: screenHeight * 0.02),
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
      final String country = provider.selectedCountry.isNotEmpty ? provider.selectedCountry : '';
      final String state = provider.selectedState.isNotEmpty ? provider.selectedState : '';

      if (country.isEmpty || state.isEmpty) {
        throw Exception('Por favor selecciona un país y un estado');
      }

      await db.collection("users").doc(currentUserId).update({
        "country": country,
        "state": state,
      });

      goRouter.go("/welcomescreen");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: ${e.toString()}")),
      );
    }
  }
}
