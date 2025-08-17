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

  void _checkInfoUpdated(DocumentSnapshot document) {
    try {
      final data = document.data() as Map<String, dynamic>?;
      if (document.exists && data?.containsKey('infoUpdated') == true) {
        final infoUpdated = data?['infoUpdated'] as Timestamp?;
        if (infoUpdated != null) {
          final now = DateTime.now();
          final lastUpdate = infoUpdated.toDate();
          final difference = now.difference(lastUpdate);
          final hoursPassed = difference.inHours;
          final minutesPassed = difference.inMinutes % 60;

          if (hoursPassed < 24) {
            final hoursRemaining = 23 - hoursPassed;
            final minutesRemaining = 60 - minutesPassed;

            final adjustedHours =
                minutesRemaining == 60 ? hoursRemaining + 1 : hoursRemaining;
            final adjustedMinutes =
                minutesRemaining == 60 ? 0 : minutesRemaining;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) {
                  final colorScheme = ColorPalette.getPalette(context);
                  return AlertDialog(
                    backgroundColor: colorScheme[AppStrings.primaryColor],
                    title: Text(
                      AppStrings.recentlyUpdatedInfoTitle,
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    content: Text(
                      AppStrings.recentlyUpdatedInfoContent(
                        hoursPassed: hoursPassed,
                        minutesPassed: minutesPassed,
                        adjustedHours: adjustedHours,
                        adjustedMinutes: adjustedMinutes,
                      ),
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppStrings.understood,
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            });
          }
        }
      }
    } catch (e, stackTrace) {
      // Error handling omitted
    }
  }

  void _loadData() async {
    final userRef = _db.collection("users").doc(widget.currentUserId);
    try {
      final document = await userRef.get();
      if (document.exists) {
        _checkInfoUpdated(document);

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
    } catch (error, stackTrace) {
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

      if (!document.exists) {
        return;
      }

      final data = document.data() ?? {};

      final lastUpdated =
          (data["infoUpdated"] as Timestamp?)
              ?.toDate()
              .millisecondsSinceEpoch ??
          0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final oneDayInMillis = 24 * 60 * 60 * 1000;

      final updates = <String, dynamic>{};
      bool hasUpdateRestriction = false;

      bool canUpdateField(String fieldName, dynamic newValue) {
        final existingValue = data[fieldName];
        return existingValue == null ||
            (currentTime - lastUpdated) > oneDayInMillis ||
            existingValue != newValue;
      }

      String normalizeSpecialty(String specialty) {
        final lower = specialty.toLowerCase();
        if (lower.contains("boda")) return AppStrings.weddings;
        if (lower.contains("casual")) return AppStrings.casualParties;
        if (lower.contains("público") || lower.contains("publico")) {
          return AppStrings.publicEvents;
        }
        return specialty;
      }

      final normalizedSpecialties =
          _selectedSpecialty.map((spec) => normalizeSpecialty(spec)).toList();

      final fieldsToUpdate = {
        "description":
            _description.isNotEmpty ? _description : FieldValue.delete(),
        "genres":
            _selectedGenres.isNotEmpty ? _selectedGenres : FieldValue.delete(),
        "specialty":
            normalizedSpecialties.isNotEmpty
                ? normalizedSpecialties
                : FieldValue.delete(),
      };

      fieldsToUpdate.forEach((fieldName, value) {
        if (value != FieldValue.delete()) {
          if (canUpdateField(fieldName, value)) {
            updates[fieldName] = value;
          } else {
            hasUpdateRestriction = true;
          }
        }
      });

      if (hasUpdateRestriction) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.updateRestrictionMessage)),
        );
        return;
      }

      if (updates.isEmpty) {
        return;
      }

      updates["infoUpdated"] = FieldValue.serverTimestamp();

      await userRef.update(updates);

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.dataSavedSuccessfully)));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.errorSavingData)));
    }
  }

  Widget _buildSpecialtyChips() {
    final colorScheme = ColorPalette.getPalette(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _selectedSpecialty.map((specialty) {
            return Chip(
              label: Text(specialty, style: TextStyle(color: Colors.white)),
              backgroundColor: colorScheme[AppStrings.essentialColor],
              deleteIcon: Icon(Icons.close, color: Colors.white),
              onDeleted:
                  _isEditing
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
    return Container(
      color: colorScheme[AppStrings.primaryColor],
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (_isEditing) {
                  await _saveData();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: colorScheme[AppStrings.secondaryColor],
                backgroundColor: colorScheme[AppStrings.essentialColor],
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                _isEditing ? AppStrings.save : AppStrings.edit,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: colorScheme[AppStrings.primaryColorLight],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${AppStrings.description}:",
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _descriptionController,
                      onChanged: (value) => _description = value,
                      enabled: _isEditing,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme[AppStrings.primaryColorLight],
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_userType == "artist")
              Card(
                color: colorScheme[AppStrings.primaryColorLight],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.musicGenres,
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed:
                            _isEditing
                                ? () => setState(() {
                                  _showGenresDropdown = !_showGenresDropdown;
                                })
                                : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(
                          AppStrings.selectGenres,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      ),
                      if (_showGenresDropdown)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme[AppStrings.primaryColor],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children:
                                _genresList.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final genre = entry.value;
                                  final isSelected = _selectedGenres.contains(
                                    genre,
                                  );

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Center(
                                              child: Text(
                                                genre,
                                                style: TextStyle(
                                                  color:
                                                      colorScheme[AppStrings
                                                          .secondaryColor],
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Checkbox(
                                                value: isSelected,
                                                onChanged:
                                                    _isEditing
                                                        ? (bool? selected) {
                                                          if (selected ==
                                                              true) {
                                                            _selectedGenres.add(
                                                              genre,
                                                            );
                                                          } else {
                                                            _selectedGenres
                                                                .remove(genre);
                                                          }
                                                          setState(() {});
                                                        }
                                                        : null,
                                                activeColor:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                                checkColor:
                                                    colorScheme[AppStrings
                                                        .primaryColor],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (index != _genresList.length - 1)
                                        Divider(
                                          color: colorScheme[AppStrings
                                                  .secondaryColor]
                                              ?.withOpacity(0.3),
                                          height: 1,
                                          thickness: 1,
                                        ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _selectedGenres
                                .map(
                                  (genre) => Chip(
                                    label: Text(
                                      genre,
                                      style: TextStyle(
                                        color:
                                            colorScheme[AppStrings
                                                .secondaryColor],
                                      ),
                                    ),
                                    backgroundColor:
                                        colorScheme[AppStrings.essentialColor],
                                    deleteIcon: Icon(
                                      Icons.close,
                                      color:
                                          colorScheme[AppStrings
                                              .secondaryColor],
                                    ),
                                    onDeleted:
                                        _isEditing
                                            ? () => setState(() {
                                              _selectedGenres.remove(genre);
                                            })
                                            : null,
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              color: colorScheme[AppStrings.primaryColorLight],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.specialization,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed:
                          _isEditing
                              ? () => setState(() {
                                _showSpecialtiesDropdown =
                                    !_showSpecialtiesDropdown;
                              })
                              : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              colorScheme[AppStrings.secondaryColor] ??
                              Colors.white,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        AppStrings.selectSpecialty,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                    if (_showSpecialtiesDropdown)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme[AppStrings.primaryColor],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children:
                              _specialtiesList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final specialty = entry.value;
                                final isSelected = _selectedSpecialty.contains(
                                  specialty,
                                );

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Center(
                                            child: Text(
                                              specialty,
                                              style: TextStyle(
                                                color:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Checkbox(
                                              value: isSelected,
                                              onChanged:
                                                  _isEditing
                                                      ? (bool? selected) {
                                                        if (selected == true) {
                                                          _selectedSpecialty
                                                              .add(specialty);
                                                        } else {
                                                          _selectedSpecialty
                                                              .remove(
                                                                specialty,
                                                              );
                                                        }
                                                        setState(() {});
                                                      }
                                                      : null,
                                              activeColor:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                              checkColor:
                                                  colorScheme[AppStrings
                                                      .primaryColor],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index != _specialtiesList.length - 1)
                                      Divider(
                                        color: colorScheme[AppStrings
                                                .secondaryColor]
                                            ?.withOpacity(0.3),
                                        height: 1,
                                        thickness: 1,
                                      ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _buildSpecialtyChips(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
