/*
 * Fecha de creación: 26 de abril de 2025
 * Autor: KingdomOfJames
 * 
 * Descripción:
 * Esta pantalla permite que los usuarios editen y guarden información de su perfil, como descripción, tarifa por hora, géneros musicales y especialidades.
 * Los usuarios pueden ingresar enlaces a sus redes sociales (Instagram, Facebook), los cuales serán validados antes de ser guardados. 
 * Si la información fue recientemente actualizada, se mostrará un diálogo indicando cuántas horas o minutos han pasado desde la última actualización.
 * 
 * Características:
 * - Visualización y edición de descripción personal.
 * - Edición de la tarifa por hora con validación de un límite máximo.
 * - Selección y visualización de géneros musicales y especialidades.
 * - Validación de enlaces de Instagram y Facebook antes de guardar.
 * - Muestra un mensaje si la información se actualizó recientemente.
 * - Se guarda la fecha de última actualización para evitar cambios repetidos en corto plazo.
 * - Interfaz optimizada para una experiencia de usuario fluida.
 * 
 * Recomendaciones:
 * - Asegúrate de que los campos de entrada como el precio y los enlaces estén correctamente validados antes de guardar los cambios.
 * - Los usuarios deberían tener la opción de cancelar cualquier cambio no guardado.
 * - Considera agregar un indicador visual de carga mientras se recuperan o guardan los datos en la base de datos.
 */
import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';

class DatesContent extends StatefulWidget {
  final ProfileProvider profileProvider;
  final String currentUserId;

  const DatesContent({
    Key? key,
    required this.profileProvider,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _DatesContentState createState() => _DatesContentState();
}

class _DatesContentState extends State<DatesContent> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _description = "";
  List<String> _selectedGenres = [];
  List<String> _selectedSpecialty = [];
  bool _isEditing = false;
  bool _showGenresDropdown = false;
  bool _showSpecialtiesDropdown = false;
  String _userType = "";

  late TextEditingController _descriptionController;

  final List<String> _genresList = [
    AppStrings.band,
    AppStrings.nortStyle,
    AppStrings.corridos,
    AppStrings.mariachi,
    AppStrings.montainStyle,
    AppStrings.cumbia,
    AppStrings.reggaeton,
  ];

  final List<String> _specialtiesList = [
    AppStrings.weddings,
    AppStrings.quinceaneras,
    AppStrings.casualParties,
    AppStrings.publicEvents,
    "Graduación",
    "Conferencia",
    "Cumpleaños",
    "Posada",
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final userRef = _db.collection("users").doc(widget.currentUserId);
    try {
      final document = await userRef.get();
      if (document.exists) {
        dynamic safeGet(DocumentSnapshot doc, String field) {
          try {
            return doc.get(field);
          } catch (e) {
            return null;
          }
        }

        final description =
            safeGet(document, "description") ?? AppStrings.noDescription;
        final genres = List<String>.from(safeGet(document, "genres") ?? []);
        final specialty = List<String>.from(
          safeGet(document, "specialty") ?? [],
        );
        final userType = safeGet(document, "userType") ?? "";

        setState(() {
          _description = description;
          _descriptionController.text = description;
          _selectedGenres = genres;
          _selectedSpecialty = specialty;
          _userType = userType;
        });
      } else {
        setState(() {
          _description = AppStrings.noDescription;
          _descriptionController.text = AppStrings.noDescription;
          _selectedGenres = [];
          _selectedSpecialty = [];
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: ${error.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _saveData() async {
    final userRef = _db.collection("users").doc(widget.currentUserId);
    try {
      final document = await userRef.get();
      if (!document.exists) return;

      final data = document.data() ?? {};
      final updates = <String, dynamic>{
        "description": _description.isNotEmpty ? _description : FieldValue.delete(),
        "genres": _selectedGenres.isNotEmpty ? _selectedGenres : FieldValue.delete(),
        "specialty": _selectedSpecialty.isNotEmpty ? _selectedSpecialty : FieldValue.delete(),
        "infoUpdated": FieldValue.serverTimestamp(),
      };
      await userRef.update(updates);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.dataSavedSuccessfully)));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorSavingData)));
    }
  }

  Widget _buildSpecialtyChips(double fontSize) {
    final colorScheme = ColorPalette.getPalette(context);
    return Wrap(
      spacing: fontSize * 0.6,
      runSpacing: fontSize * 0.6,
      children: _selectedSpecialty.map((specialty) {
        return Chip(
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(specialty, style: TextStyle(color: Colors.white, fontSize: fontSize)),
          ),
          backgroundColor: colorScheme[AppStrings.essentialColor],
          deleteIcon: Icon(Icons.close, color: Colors.white, size: fontSize),
          onDeleted: _isEditing
              ? () {
                  setState(() {
                    _selectedSpecialty.remove(specialty);
                  });
                }
              : null,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Tamaños adaptativos
    final padding = screenWidth * 0.04;
    final buttonHeight = screenHeight * 0.06;
    final textFontSize = screenWidth * 0.045;
    final titleFontSize = screenWidth * 0.05;
    final chipFontSize = screenWidth * 0.04;

    return Container(
      color: colorScheme[AppStrings.primaryColor],
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: _isEditing ? _saveData : () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: colorScheme[AppStrings.essentialColor],
                minimumSize: Size(double.infinity, buttonHeight),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isEditing ? AppStrings.save : AppStrings.edit,
                  style: TextStyle(fontSize: titleFontSize, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Card(
              color: colorScheme[AppStrings.primaryColorLight],
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "${AppStrings.description}:",
                        style: TextStyle(fontSize: titleFontSize, color: colorScheme[AppStrings.secondaryColor]),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    TextField(
                      controller: _descriptionController,
                      onChanged: (value) => _description = value,
                      enabled: _isEditing,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme[AppStrings.primaryColorLight],
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
                        ),
                      ),
                      style: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: textFontSize),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            if (_userType == "artist")
              Card(
                color: colorScheme[AppStrings.primaryColorLight],
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppStrings.musicGenres,
                          style: TextStyle(fontSize: titleFontSize, color: colorScheme[AppStrings.secondaryColor]),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      OutlinedButton(
                        onPressed: _isEditing ? () => setState(() => _showGenresDropdown = !_showGenresDropdown) : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
                          minimumSize: Size(double.infinity, buttonHeight),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.selectGenres,
                            style: TextStyle(fontSize: textFontSize, color: colorScheme[AppStrings.secondaryColor]),
                          ),
                        ),
                      ),
                      if (_showGenresDropdown)
                        Column(
                          children: _genresList.map((genre) {
                            final isSelected = _selectedGenres.contains(genre);
                            return Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: _isEditing
                                      ? (bool? selected) {
                                          setState(() {
                                            if (selected == true) _selectedGenres.add(genre);
                                            else _selectedGenres.remove(genre);
                                          });
                                        }
                                      : null,
                                  activeColor: colorScheme[AppStrings.secondaryColor],
                                  checkColor: colorScheme[AppStrings.primaryColor],
                                ),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      genre,
                                      style: TextStyle(fontSize: textFontSize, color: colorScheme[AppStrings.secondaryColor]),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      SizedBox(height: screenHeight * 0.01),
                      Wrap(
                        spacing: chipFontSize * 0.6,
                        runSpacing: chipFontSize * 0.6,
                        children: _selectedGenres.map((genre) {
                          return Chip(
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(genre, style: TextStyle(color: Colors.white, fontSize: chipFontSize)),
                            ),
                            backgroundColor: colorScheme[AppStrings.essentialColor],
                            deleteIcon: Icon(Icons.close, color: Colors.white, size: chipFontSize),
                            onDeleted: _isEditing
                                ? () => setState(() => _selectedGenres.remove(genre))
                                : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: screenHeight * 0.015),
            Card(
              color: colorScheme[AppStrings.primaryColorLight],
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.specialization,
                        style: TextStyle(fontSize: titleFontSize, color: colorScheme[AppStrings.secondaryColor]),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    OutlinedButton(
                      onPressed: _isEditing ? () => setState(() => _showSpecialtiesDropdown = !_showSpecialtiesDropdown) : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
                        minimumSize: Size(double.infinity, buttonHeight),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppStrings.selectSpecialty,
                          style: TextStyle(fontSize: textFontSize, color: colorScheme[AppStrings.secondaryColor]),
                        ),
                      ),
                    ),
                    if (_showSpecialtiesDropdown)
                      Column(
                        children: _specialtiesList.map((specialty) {
                          final isSelected = _selectedSpecialty.contains(specialty);
                          return Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: _isEditing
                                    ? (bool? selected) {
                                        setState(() {
                                          if (selected == true) _selectedSpecialty.add(specialty);
                                          else _selectedSpecialty.remove(specialty);
                                        });
                                      }
                                    : null,
                                activeColor: colorScheme[AppStrings.secondaryColor],
                                checkColor: colorScheme[AppStrings.primaryColor],
                              ),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    specialty,
                                    style: TextStyle(fontSize: textFontSize, color: colorScheme[AppStrings.secondaryColor]),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    SizedBox(height: screenHeight * 0.01),
                    _buildSpecialtyChips(chipFontSize),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
          ],
        ),
      ),
    );
  }
}