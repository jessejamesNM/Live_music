/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla que permite al usuario introducir y validar un apodo (nickname) como parte del proceso de registro o configuración inicial.
/// Valida el formato del nickname localmente y verifica su disponibilidad mediante el `BeginningProvider`.
/// Si el nickname es válido y está disponible, se guarda y se navega al siguiente paso del flujo.
///
/// Recomendaciones:
/// - Considerar añadir un ícono o texto que indique si el nickname está disponible mientras se escribe.
/// - Mejorar el manejo de errores mostrando retroalimentación más contextual (por ejemplo, tiempo de espera, errores de red).
/// - Permitir usar el botón "Enter" del teclado como acción de envío para mayor accesibilidad.
///
/// Características:
/// - Validación en tiempo real del formato del nickname.
/// - Comprobación de disponibilidad del nickname con lógica asincrónica.
/// - Botón de continuar habilitado únicamente cuando el nickname es válido.
/// - Estilo consistente con la paleta de colores de la aplicación (`ColorPalette`).
/// - Integración con `GoRouter` para navegación tras éxito.
/// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';

class NicknameScreen extends StatefulWidget {
  final GoRouter goRouter;

  const NicknameScreen({Key? key, required this.goRouter}) : super(key: key);

  @override
  _NicknameScreenState createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  String nickname = '';
  String errorMessage = '';

 
Future<bool> shouldCheckLocation(bool isArtist) async {
  if (isArtist) return false;

  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null || currentUser.uid.trim().isEmpty) {
    print(" Usuario no autenticado o UID vacío");
    return true; // o false, depende de tu lógica general
  }

  final docSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();

  if (!docSnapshot.exists) return true;

  final data = docSnapshot.data();
  final hasCountry = data != null && data['country'] != null && data['country'].toString().trim().isNotEmpty;
  final hasState = data != null && data['state'] != null && data['state'].toString().trim().isNotEmpty;

  return !(hasCountry || hasState);
}

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BeginningProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userType = userProvider.userType;
    final currentUserId =  FirebaseAuth.instance.currentUser?.uid;
    final isArtist = userType == AppStrings.artist;
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppStrings.createNickName,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor],
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          nickname = value;
                          errorMessage = provider.validateNickname(value);
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme[AppStrings.primaryColor],
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                colorScheme[AppStrings.secondaryColor] ??
                                Colors.grey,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                colorScheme[AppStrings.secondaryColor] ??
                                Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        errorText:
                            errorMessage.isNotEmpty ? errorMessage : null,
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        hintText: AppStrings.yourNickname,
                        hintStyle: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor]
                              ?.withOpacity(0.5),
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (nickname.isNotEmpty && errorMessage.isEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      bool isAvailable = await provider.isNicknameAvailable(
                        nickname,
                      );
                      if (isAvailable) {
                        // Condición especial antes de guardar nickname y navegar
                        final needsLocationCheck = await shouldCheckLocation(
                          isArtist,
                          
                        );

                        if (needsLocationCheck) {
                          userProvider.getCountryAndState();
                        }

                        provider.saveNickname(
                          nickname,
                          context,
                          widget.goRouter,
                          provider.routeToGo ?? '',
                        );
                      } else {
                        setState(() {
                          errorMessage = AppStrings.noAvailableNickname;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme[AppStrings.essentialColor],
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
                        color: colorScheme[AppStrings.primaryColor],
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
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
