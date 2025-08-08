// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Esta pantalla muestra el perfil de un usuario en la aplicación, donde se detallan
// aspectos como la descripción personal, tarifa por hora, géneros musicales, especialización y enlaces a redes sociales como Instagram y Facebook.
// Características:
// 1. Recupera la información de un usuario específico desde Firestore.
// 2. Muestra la descripción, tarifa, géneros musicales, especialización y enlaces sociales del usuario.
// 3. Maneja posibles errores de carga de datos mostrando un mensaje de error.
// 4. Permite abrir los enlaces de redes sociales directamente desde la interfaz de usuario.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';

class DatesContentWS extends StatelessWidget {
  const DatesContentWS({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene el esquema de colores
    final userProvider = Provider.of<UserProvider>(
      context,
    ); // Proveedor de usuario
    final otherUserId =
        userProvider.otherUserId; // ID del otro usuario a mostrar

    // Widget que contiene la información del usuario
    return DatesContentWidget(
      otherUserId: otherUserId,
      colorScheme: colorScheme,
    );
  }
}

class DatesContentWidget extends StatefulWidget {
  final String otherUserId; // ID del otro usuario
  final Map<String, Color> colorScheme; // Esquema de colores

  DatesContentWidget({required this.otherUserId, required this.colorScheme});

  @override
  _DatesContentWidgetState createState() => _DatesContentWidgetState();
}

class _DatesContentWidgetState extends State<DatesContentWidget> {
  String description = ""; // Descripción del usuario
  String availability = ""; // Disponibilidad del usuario
  int? price; // Precio por hora del usuario
  List<String> selectedGenres = []; // Géneros musicales seleccionados
  String selectedSpecialty = ""; // Especialización del usuario
  String instagramLink = ""; // Enlace a Instagram
  String facebookLink = ""; // Enlace a Facebook
  bool showToast = false; // Indicador para mostrar un toast de error
  String toastMessage = ""; // Mensaje para el toast

  @override
  void initState() {
    super.initState();
    loadData(); // Cargar los datos del usuario cuando se inicializa
  }

  // Función para cargar los datos del usuario desde Firestore
  void loadData() async {
    try {
      final document =
          await FirebaseFirestore.instance
              .collection(AppStrings.usersCollection)
              .doc(widget.otherUserId) // Obtener datos del usuario usando su ID
              .get();

      if (document.exists) {
        final data =
            document.data() ??
            {}; // Si el documento existe, obtenemos los datos

        setState(() {
          // Actualizamos el estado con la información del usuario
          description = (data[AppStrings.descriptionField] ?? "").toString();
          price =
              data[AppStrings.priceField] is int
                  ? data[AppStrings.priceField]
                  : 200; // Valor por defecto de precio si no se encuentra
          selectedGenres =
              data[AppStrings.genresField] != null
                  ? List<String>.from(data[AppStrings.genresField])
                  : [];
          selectedSpecialty =
              (data[AppStrings.specialtyField] ?? "").toString();
          instagramLink =
              (data[AppStrings.instagramLinkField] ?? "").toString();
          facebookLink = (data[AppStrings.facebookLinkField] ?? "").toString();
        });
      } else {
        setState(() {
          toastMessage =
              AppStrings.profileNotFound; // Si el perfil no se encuentra
          showToast = true; // Mostrar mensaje de error
        });
      }
    } catch (e) {
      setState(() {
        toastMessage =
            "${AppStrings.errorGettingData}: ${e.toString()}"; // Manejo de error
        showToast = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar el toast si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toastMessage), // Mostrar el mensaje del toast
            backgroundColor: widget.colorScheme[AppStrings.primaryColorLight],
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(
          () => showToast = false,
        ); // Ocultar el toast después de mostrarlo
      }
    });

    // Construcción de la interfaz de usuario
    return Container(
      color: widget.colorScheme[AppStrings.primaryColor],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCard(
              // Mostrar la descripción
              AppStrings.description,
              description.isNotEmpty ? description : AppStrings.noDescription,
            ),
            const SizedBox(height: 8),
            buildCard(
              // Mostrar la tarifa por hora
              AppStrings.hourlyRate,
              price != null ? '\$$price' : AppStrings.priceNotSpecified,
            ),
            const SizedBox(height: 8),
            buildGenresCard(), // Mostrar los géneros musicales
            const SizedBox(height: 8),
            buildCard(
              // Mostrar la especialización
              AppStrings.specialization,
              selectedSpecialty.isNotEmpty
                  ? selectedSpecialty
                  : AppStrings.noSpecialty,
            ),
            const SizedBox(height: 8),
            buildLinkCard(
              AppStrings.instagram,
              instagramLink,
            ), // Mostrar enlace de Instagram
            const SizedBox(height: 8),
            buildLinkCard(
              AppStrings.facebook,
              facebookLink,
            ), // Mostrar enlace de Facebook
          ],
        ),
      ),
    );
  }

  // Función para construir una tarjeta con un título y contenido
  Widget buildCard(String title, String content) {
    return Card(
      color: widget.colorScheme[AppStrings.primaryColorLight],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: widget.colorScheme[AppStrings.secondaryColor],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: widget.colorScheme[AppStrings.secondaryColor],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para construir la tarjeta de géneros musicales
  Widget buildGenresCard() {
    return Card(
      color: widget.colorScheme[AppStrings.primaryColorLight],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.musicGenres,
              style: TextStyle(
                fontSize: 18,
                color: widget.colorScheme[AppStrings.secondaryColor],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            selectedGenres.isNotEmpty
                ? Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      selectedGenres
                          .map(
                            (genre) => Chip(
                              label: Text(genre),
                              backgroundColor:
                                  widget.colorScheme[AppStrings.essentialColor],
                              labelStyle: TextStyle(
                                color:
                                    widget.colorScheme[AppStrings
                                        .secondaryColor],
                              ),
                            ),
                          )
                          .toList(),
                )
                : Text(
                  AppStrings.notSpecified,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.colorScheme[AppStrings.secondaryColor],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // Función para construir tarjetas de enlaces de redes sociales
  Widget buildLinkCard(String title, String link) {
    if (link.isEmpty) return const SizedBox();

    return Card(
      color: widget.colorScheme[AppStrings.primaryColorLight],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: widget.colorScheme[AppStrings.secondaryColor],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                try {
                  if (await canLaunch(link)) {
                    // Intentar abrir el enlace
                    await launch(link);
                  }
                } catch (e) {
                  setState(() {
                    toastMessage =
                        AppStrings
                            .couldNotOpenLink; // Mensaje de error si no se puede abrir el enlace
                    showToast = true;
                  });
                }
              },
              child: Text(
                link,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      widget.colorScheme[AppStrings.blueColor] ?? Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
