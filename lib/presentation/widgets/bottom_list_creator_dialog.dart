// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: El widget `BottomFavoritesListCreatorDialog` muestra un cuadro de diálogo en la parte inferior de la pantalla
//              para crear una lista de favoritos. Permite al usuario ingresar un nombre para la lista y, si ya existe una
//              lista con el mismo nombre, muestra un mensaje de advertencia. Si la lista no existe, crea una nueva lista de
//              favoritos y realiza una acción adicional al presionar el botón de "like".
// Recomendaciones: Asegúrate de pasar correctamente los parámetros `userId`, `onDismiss`, `favoritesProvider` y `onLikeClick`
//                  al crear este widget. El manejo del estado y la interacción con la base de datos es fundamental para la
//                  funcionalidad, por lo que se debe garantizar que `favoritesProvider` esté bien configurado para interactuar
//                  con los datos del usuario.
// Características:
//   - Muestra un cuadro de diálogo en la parte inferior de la pantalla.
//   - Permite crear una lista de favoritos proporcionando un nombre.
//   - Verifica si el usuario ya está en una lista existente antes de permitir la creación de una nueva.
//   - Usa un botón de acción para crear la lista o mostrar un mensaje de advertencia si la lista ya existe.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/resources/colors.dart';

import '../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';

class BottomFavoritesListCreatorDialog extends StatefulWidget {
  final String
  userId; // El ID del usuario para verificar si ya está en alguna lista de favoritos.
  final VoidCallback
  onDismiss; // Función que se ejecuta cuando se cierra el diálogo.
  final FavoritesProvider
  favoritesProvider; // Proveedor que maneja las listas de favoritos.
  final VoidCallback
  onLikeClick; // Acción que se ejecuta al presionar el botón "like".

  const BottomFavoritesListCreatorDialog({
    Key? key,
    required this.userId,
    required this.onDismiss,
    required this.favoritesProvider,
    required this.onLikeClick,
  }) : super(key: key);

  @override
  _BottomFavoritesListCreatorDialogState createState() =>
      _BottomFavoritesListCreatorDialogState();
}

class _BottomFavoritesListCreatorDialogState
    extends State<BottomFavoritesListCreatorDialog> {
  final TextEditingController _textController =
      TextEditingController(); // Controlador de texto para el nombre de la lista.
  final FocusNode _focusNode =
      FocusNode(); // Nodo de enfoque para el campo de texto.

  @override
  void dispose() {
    _textController.dispose(); // Liberar recursos del controlador de texto.
    _focusNode.dispose(); // Liberar recursos del nodo de enfoque.
    super.dispose();
  }

  void _showCenteredDialog(String listName) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtener el esquema de colores actual.

    final overlay = Overlay.of(
      context,
    ); // Usar el overlay para mostrar el diálogo.
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Center(
            child: Material(
              color: Colors.black.withOpacity(0.7),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color:
                      colorScheme[AppStrings
                          .primaryColor], // Color de fondo del diálogo.
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '${AppStrings.userAlreadyInListPrefix}"$listName"${AppStrings.userAlreadyInListSuffix}', // Mensaje de advertencia.
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del texto.
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry); // Insertar el overlay en la pantalla.
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove(); // Eliminar el overlay después de 3 segundos.
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtener el esquema de colores.

    return GestureDetector(
      behavior:
          HitTestBehavior
              .opaque, // Detectar el toque en la pantalla y cerrar el diálogo si se toca fuera.
      onTap: () {
        _focusNode.unfocus(); // Quitar el enfoque del campo de texto.
        widget.onDismiss(); // Llamar a la función de cierre del diálogo.
      },
      child: Container(
        color: Colors.black.withOpacity(0.5), // Fondo semitransparente.
        child: Align(
          alignment:
              Alignment
                  .bottomCenter, // Alinear el diálogo en la parte inferior.
          child: Material(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            color: colorScheme[AppStrings.primaryColor], // Fondo del diálogo.
            child: Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context)
                        .viewInsets
                        .bottom, // Asegurar que el teclado no se superponga.
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Minimizar el tamaño del contenido.
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start, // Alinear el contenido a la izquierda.
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400], // Línea de arrastre.
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween, // Espacio entre el título y el icono de cerrar.
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.createFavoritesList, // Título del diálogo.
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                colorScheme[AppStrings
                                    .secondaryColor], // Color del texto.
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close, // Icono de cerrar el diálogo.
                          size: 28,
                          color:
                              colorScheme[AppStrings
                                  .essentialColor], // Color del icono.
                        ),
                        onPressed:
                            widget
                                .onDismiss, // Cerrar el diálogo al presionar el icono.
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller:
                        _textController, // Vincular el controlador de texto.
                    focusNode: _focusNode, // Vincular el nodo de enfoque.
                    decoration: InputDecoration(
                      hintText: AppStrings.listNameHint, // Texto de sugerencia.
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color:
                            Colors.grey[500], // Estilo del texto de sugerencia.
                      ),
                      filled: true,
                      fillColor: Colors.grey[850], // Fondo del campo de texto.
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none, // Sin borde.
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          colorScheme[AppStrings
                              .secondaryColor], // Color del texto ingresado.
                    ),
                    textInputAction:
                        TextInputAction.done, // Acción de entrada al finalizar.
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final listName =
                            _textController.text
                                .trim(); // Obtener el nombre de la lista.
                        if (listName.isEmpty)
                          return; // No hacer nada si el nombre está vacío.

                        final existingListName = await widget.favoritesProvider
                            .getListNameContainingUser(
                              widget.userId,
                            ); // Verificar si el usuario ya está en alguna lista.

                        if (existingListName != null) {
                          _showCenteredDialog(
                            existingListName,
                          ); // Mostrar mensaje si ya existe la lista.
                          return;
                        }

                        widget
                            .onLikeClick(); // Acción de "like" al crear la lista.
                        await widget.favoritesProvider.createFavoritesList(
                          listName, // Crear la lista de favoritos.
                          widget.userId,
                        );
                        _textController.clear(); // Limpiar el campo de texto.
                        widget
                            .onDismiss(); // Cerrar el diálogo después de crear la lista.
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colorScheme[AppStrings
                                .essentialColor], // Color de fondo del botón.
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        AppStrings.createListButtonText, // Texto del botón.
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Color del texto del botón.
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
