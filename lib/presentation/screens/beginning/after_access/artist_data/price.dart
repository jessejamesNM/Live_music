/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla para ingresar la tarifa por hora del usuario (precio en dólares).
/// Permite al usuario introducir un valor numérico que representa su precio por hora.
/// Al confirmar, se guarda en la base de datos (Firestore) bajo el documento del usuario actual.
///
/// Recomendaciones:
/// - Mostrar retroalimentación visual inmediata cuando el valor ingresado es inválido.
/// - Agregar validación más robusta para evitar valores extremos o maliciosos.
/// - Considerar mover la lógica de validación y guardado al provider o un controlador externo.
///
/// Características:
/// - Entrada restringida a solo caracteres numéricos.
/// - Validación básica y conversión a entero del valor ingresado.
/// - Guarda la tarifa en Firestore bajo el campo `price`.
/// - Usa el esquema de colores definido en `ColorPalette`.
/// - Navega automáticamente a la siguiente pantalla si la tarifa se guarda correctamente.
/// - Muestra `SnackBar` con mensajes de error si algo falla.
/// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/resources/colors.dart';

// Pantalla donde el usuario introduce su tarifa por hora.
// La tarifa se guarda en Firestore y luego se navega a la siguiente pantalla.
class PriceScreen extends StatelessWidget {
  final GoRouter goRouter;

  // Constructor que recibe el router para navegación
  const PriceScreen({Key? key, required this.goRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Paleta de colores personalizada
    final colorScheme = ColorPalette.getPalette(context);

    // Instancias de Firebase para acceder a Firestore y Auth
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Variable local para guardar el valor ingresado
    String tarifa = '';

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título
              Text(
                AppStrings.enterHourlyRate,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo de texto decorado para ingresar la tarifa
              Container(
                decoration: BoxDecoration(
                  color: colorScheme[AppStrings.primaryColor],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme[AppStrings.secondaryColor]!.withOpacity(
                      0.5,
                    ),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  // Se actualiza tarifa solo si son caracteres numéricos
                  onChanged: (newValue) {
                    if (newValue
                        .split('')
                        .every((char) => RegExp(r'[0-9]').hasMatch(char))) {
                      tarifa = newValue;
                    }
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: "\$",
                    prefixStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    hintText: AppStrings.rateExample,
                    hintStyle: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor]
                          ?.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón para continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final currentUserId = auth.currentUser?.uid;

                    // Validación: si el usuario está logueado y la tarifa no está vacía
                    if (currentUserId != null && tarifa.isNotEmpty) {
                      final priceInt = int.tryParse(tarifa) ?? 0;

                      // Se actualiza el documento del usuario con la tarifa ingresada
                      db
                          .collection("users")
                          .doc(currentUserId)
                          .update({"price": priceInt})
                          .then((_) {
                            // Redirección a la siguiente pantalla
                            goRouter.go(
                              AppStrings.userCanWorkCountryStateScreenRoute,
                            );
                          })
                          .catchError((e) {
                            // Si hay error al guardar, muestra SnackBar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${AppStrings.errorSavingRate}: $e",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                    } else {
                      // Si los datos no son válidos, muestra mensaje de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.enterValidRate),
                          backgroundColor: Colors.red,
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
          ),
        ),
      ),
    );
  }
}
