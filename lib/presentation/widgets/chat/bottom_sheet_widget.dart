// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Este widget representa un Bottom Sheet animado que aparece desde la parte inferior
// de la pantalla para ofrecer opciones de gestión de conversaciones seleccionadas,
// como eliminar o bloquear usuarios.
//
// Características:
// - Aparece y desaparece de manera animada.
// - Se adapta dinámicamente a si hay usuarios seleccionados.
// - Muestra dos acciones: "Eliminar" y "Bloquear".
// - Cierra el Bottom Sheet automáticamente tras una acción.
//
// Recomendaciones:
// - Usarlo en pantallas de chat o mensajería donde sea necesario gestionar múltiples conversaciones.
// - Asegurarse de gestionar correctamente el estado de `isBottomSheetVisible` y `selectedReceivers`.
// - Personalizar los colores en `ColorPalette` y los textos en `AppStrings` para mantener la coherencia visual de la app.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class BottomSheetWidget extends StatelessWidget {
  // Variables recibidas para controlar el estado y las acciones del Bottom Sheet.
  final bool isBottomSheetVisible;
  final List<String> selectedReceivers;
  final VoidCallback deleteSelectedConversations;
  final VoidCallback blockSelectedConversations;
  final Function(bool) onBottomSheetVisibilityChanged;

  const BottomSheetWidget({
    required this.isBottomSheetVisible,
    required this.selectedReceivers,
    required this.deleteSelectedConversations,
    required this.blockSelectedConversations,
    required this.onBottomSheetVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Se obtiene la paleta de colores definida para el tema actual.
    final colorScheme = ColorPalette.getPalette(context);

    return AnimatedPositioned(
      // Configuración de la animación de aparición/desaparición del Bottom Sheet.
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom:
          isBottomSheetVisible
              ? 0
              : -100, // Se muestra o se oculta dependiendo de la visibilidad.
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color:
              colorScheme[AppStrings
                  .primaryColor], // Color de fondo del Bottom Sheet.
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Botón de "Eliminar"
            GestureDetector(
              onTap:
                  selectedReceivers.isEmpty
                      ? null // Si no hay receptores seleccionados, no hace nada.
                      : () {
                        deleteSelectedConversations(); // Ejecuta la función de eliminar conversaciones.
                        onBottomSheetVisibilityChanged(
                          false,
                        ); // Oculta el Bottom Sheet tras la acción.
                      },
              child: Text(
                AppStrings.delete,
                style: TextStyle(
                  color: colorScheme[AppStrings.essentialColor]?.withOpacity(
                    selectedReceivers.isEmpty
                        ? 0.4
                        : 1.0, // Desactiva visualmente si no hay selección.
                  ),
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(), // Separa los dos botones.
            // Botón de "Bloquear"
            GestureDetector(
              onTap:
                  selectedReceivers.isEmpty
                      ? null // Si no hay receptores seleccionados, no hace nada.
                      : () {
                        blockSelectedConversations(); // Ejecuta la función de bloquear conversaciones.
                        onBottomSheetVisibilityChanged(
                          false,
                        ); // Oculta el Bottom Sheet tras la acción.
                      },
              child: Text(
                AppStrings.block,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                    selectedReceivers.isEmpty
                        ? 0.4
                        : 1.0, // Desactiva visualmente si no hay selección.
                  ),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
