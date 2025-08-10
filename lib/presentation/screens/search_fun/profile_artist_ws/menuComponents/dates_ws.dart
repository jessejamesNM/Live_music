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
    final colorScheme = ColorPalette.getPalette(context);
    final userProvider = Provider.of<UserProvider>(context);
    final otherUserId = userProvider.otherUserId;

    return DatesContentWidget(
      otherUserId: otherUserId,
      colorScheme: colorScheme,
    );
  }
}

class DatesContentWidget extends StatefulWidget {
  final String otherUserId;
  final Map<String, Color> colorScheme;

  const DatesContentWidget({
    required this.otherUserId,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  _DatesContentWidgetState createState() => _DatesContentWidgetState();
}

class _DatesContentWidgetState extends State<DatesContentWidget> {
  String description = "";
  List<String> selectedGenres = [];
  List<String> selectedSpecialty = [];
  String instagramLink = "";
  String facebookLink = "";
  bool showToast = false;
  String toastMessage = "";
  String userType = "";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    try {
      final document =
          await FirebaseFirestore.instance
              .collection(AppStrings.usersCollection)
              .doc(widget.otherUserId)
              .get();

      if (document.exists) {
        final data = document.data() ?? {};
        setState(() {
          description = (data[AppStrings.descriptionField] ?? "").toString();
          selectedGenres =
              data[AppStrings.genresField] != null
                  ? List<String>.from(data[AppStrings.genresField])
                  : [];
          selectedSpecialty =
              data[AppStrings.specialtyField] != null
                  ? List<String>.from(data[AppStrings.specialtyField])
                  : [];
          instagramLink =
              (data[AppStrings.instagramLinkField] ?? "").toString();
          facebookLink = (data[AppStrings.facebookLinkField] ?? "").toString();
          userType = (data[AppStrings.userTypeField] ?? "").toString();
        });
      } else {
        setState(() {
          toastMessage = AppStrings.profileNotFound;
          showToast = true;
        });
      }
    } catch (e) {
      setState(() {
        toastMessage = "${AppStrings.errorGettingData}: ${e.toString()}";
        showToast = true;
      });
    }
  }

  Widget _buildSpecialtyChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children:
          selectedSpecialty.map((specialty) {
            return Chip(
              label: Text(
                specialty,
                style: TextStyle(
                  color: widget.colorScheme[AppStrings.secondaryColor],
                ),
              ),
              backgroundColor: widget.colorScheme[AppStrings.essentialColor],
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toastMessage),
            backgroundColor: widget.colorScheme[AppStrings.primaryColorLight],
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => showToast = false);
      }
    });

    return Container(
      color: widget.colorScheme[AppStrings.primaryColor],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCard(
              AppStrings.description,
              description.isNotEmpty ? description : AppStrings.noDescription,
            ),
            const SizedBox(height: 8),
            if (userType == "artist") ...[
              buildGenresCard(),
              const SizedBox(height: 8),
            ],
            Card(
              color: widget.colorScheme[AppStrings.primaryColorLight],
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.specialization,
                      style: TextStyle(
                        fontSize: 18,
                        color: widget.colorScheme[AppStrings.secondaryColor],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    selectedSpecialty.isNotEmpty
                        ? _buildSpecialtyChips()
                        : Text(
                          AppStrings.noSpecialty,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                widget.colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            buildLinkCard(AppStrings.instagram, instagramLink),
            const SizedBox(height: 8),
            buildLinkCard(AppStrings.facebook, facebookLink),
          ],
        ),
      ),
    );
  }

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
                    await launch(link);
                  }
                } catch (e) {
                  setState(() {
                    toastMessage = AppStrings.couldNotOpenLink;
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
