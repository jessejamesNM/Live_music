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
  int? _price;
  List<String> _selectedGenres = [];
  String _selectedSpecialty = "";
  bool _isEditing = false;
  String _instagramLink = "";
  String _facebookLink = "";
  bool _showGenresDropdown = false;
  bool _showSpecialtiesDropdown = false;
  
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;

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
  ];

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }void _checkInfoUpdated(DocumentSnapshot document) {
  try {
    // Verifica primero si el campo existe en el documento
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

          final adjustedHours = minutesRemaining == 60 ? hoursRemaining + 1 : hoursRemaining;
          final adjustedMinutes = minutesRemaining == 60 ? 0 : minutesRemaining;

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
    } else {
      debugPrint('ℹ️ Campo infoUpdated no existe en el documento - continuando normalmente');
    }
  } catch (e, stackTrace) {
    debugPrint('⚠️ Error no crítico en _checkInfoUpdated: $e');
    debugPrint(stackTrace.toString());
    // Continuar con el flujo normal sin interrumpir
  }
}

void _loadData() async {
  debugPrint('⏳ [LOAD DATA] Iniciando carga de datos...');
  debugPrint('🔑 User ID: ${widget.currentUserId}');

  final userRef = _db.collection("users").doc(widget.currentUserId);
  debugPrint('📄 Referencia de documento creada: ${userRef.path}');

  try {
    debugPrint('🔄 [FIRESTORE] Solicitando documento...');
    final document = await userRef.get();
    debugPrint('✅ [FIRESTORE] Documento obtenido');

    if (document.exists) {
      debugPrint('📦 Documento existe. Datos crudos:');
      debugPrint(document.data().toString());

      _checkInfoUpdated(document);

      dynamic safeGet(DocumentSnapshot doc, String field) {
        try {
          final value = doc.get(field);
          debugPrint('🔍 Campo [$field] encontrado: $value');
          return value;
        } catch (e) {
          debugPrint('⚠️ Campo [$field] no encontrado. Error: $e');
          return null;
        }
      }

      debugPrint('\n📋 Extrayendo campos específicos:');
      final description = safeGet(document, "description") ?? AppStrings.noDescription;
      final price = safeGet(document, "price");
      final genres = List<String>.from(safeGet(document, "genres") ?? []);
      final specialty = safeGet(document, "specialty") ?? "";
      final instagramLink = safeGet(document, "instagramLink") ?? "";
      final facebookLink = safeGet(document, "facebookLink") ?? "";

      debugPrint('\n📊 Datos extraídos:');
      debugPrint('• Descripción: $description');
      debugPrint('• Precio: $price');
      debugPrint('• Géneros: $genres');
      debugPrint('• Especialidad: $specialty');
      debugPrint('• Instagram: $instagramLink');
      debugPrint('• Facebook: $facebookLink');

      debugPrint('\n🔄 Actualizando estado...');
      setState(() {
        _description = description;
        _descriptionController.text = description;
        _price = price;
        _priceController.text = price?.toString() ?? "";
        _selectedGenres = genres;
        _selectedSpecialty = specialty;
        _instagramLink = instagramLink;
        _instagramController.text = instagramLink;
        _facebookLink = facebookLink;
        _facebookController.text = facebookLink;
      });
      debugPrint('🎉 [LOAD DATA] Datos cargados y estado actualizado');
    } else {
      debugPrint('❌ El documento no existe en Firestore');
      setState(() {
        _description = AppStrings.noDescription;
        _descriptionController.text = AppStrings.noDescription;
        _price = null;
        _priceController.text = "";
        _selectedGenres = [];
        _selectedSpecialty = "";
        _instagramLink = "";
        _instagramController.text = "";
        _facebookLink = "";
        _facebookController.text = "";
      });
    }
  } catch (error, stackTrace) {
    debugPrint('‼️ ERROR CRÍTICO en _loadData()');
    debugPrint('🛑 Tipo de error: ${error.runtimeType}');
    debugPrint('💥 Mensaje: ${error.toString()}');
    debugPrint('📜 Stack trace:');
    debugPrint(stackTrace.toString());
    
    // Mostrar error al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al cargar datos: ${error.toString()}'),
        duration: const Duration(seconds: 5),
      ),
    );
  } finally {
    debugPrint('🏁 [LOAD DATA] Finalizado');
  }
}

  Future<void> _saveData() async {
    if (_instagramLink.isNotEmpty &&
        !_instagramLink.startsWith("https://instagram.com/")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.invalidInstagramLink)),
      );
      return;
    }

    if (_facebookLink.isNotEmpty &&
        !_facebookLink.startsWith("https://facebook.com/")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.invalidFacebookLink)),
      );
      return;
    }

    final userRef = _db.collection("users").doc(widget.currentUserId);

    try {
      final document = await userRef.get();

      if (!document.exists) {
        return;
      }

      final data = document.data() ?? {};

      final lastUpdated =
          (data["infoUpdated"] as Timestamp?)?.toDate().millisecondsSinceEpoch ??
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

      final normalizedSpecialty = normalizeSpecialty(_selectedSpecialty);

      final fieldsToUpdate = {
        "description":
            _description.isNotEmpty ? _description : FieldValue.delete(),
        "price": _price ?? FieldValue.delete(),
        "genres":
            _selectedGenres.isNotEmpty ? _selectedGenres : FieldValue.delete(),
        "specialty": normalizedSpecialty.isNotEmpty
            ? normalizedSpecialty
            : FieldValue.delete(),
        "instagramLink":
            _instagramLink.isNotEmpty ? _instagramLink : FieldValue.delete(),
        "facebookLink":
            _facebookLink.isNotEmpty ? _facebookLink : FieldValue.delete(),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.dataSavedSuccessfully)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.errorSavingData)),
      );
    }
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
                style: const TextStyle(fontSize: 18),
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
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
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
            Card(
              color: colorScheme[AppStrings.primaryColorLight],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${AppStrings.hourlyRate}:",
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _price = null;
                          return;
                        }

                        final newPrice = int.tryParse(value);
                        if (newPrice == null) return;

                        if (newPrice <= 10000) {
                          _price = newPrice;
                        } else {
                          _priceController.text = _price?.toString() ?? "";
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.priceLimitExceeded),
                            ),
                          );
                        }
                      },
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme[AppStrings.primaryColorLight],
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        labelText: AppStrings.price,
                        labelStyle: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        errorText: _price != null && _price! > 10000
                            ? AppStrings.priceLimitExceeded
                            : null,
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
                      onPressed: _isEditing
                          ? () => setState(() {
                                _showGenresDropdown = !_showGenresDropdown;
                              })
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colorScheme[AppStrings.secondaryColor] ??
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
                          children: _genresList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final genre = entry.value;
                            final isSelected = _selectedGenres.contains(genre);

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
                                            color: colorScheme[
                                                AppStrings.secondaryColor],
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Checkbox(
                                          value: isSelected,
                                          onChanged: _isEditing
                                              ? (bool? selected) {
                                                  if (selected == true) {
                                                    _selectedGenres.add(genre);
                                                  } else {
                                                    _selectedGenres.remove(genre);
                                                  }
                                                  setState(() {});
                                                }
                                              : null,
                                          activeColor: colorScheme[
                                              AppStrings.secondaryColor],
                                          checkColor: colorScheme[
                                              AppStrings.primaryColor],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index != _genresList.length - 1)
                                  Divider(
                                    color: colorScheme[AppStrings.secondaryColor]
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
                      children: _selectedGenres
                          .map(
                            (genre) => Chip(
                              label: Text(
                                genre,
                                style: TextStyle(
                                  color: colorScheme[AppStrings.secondaryColor],
                                ),
                              ),
                              backgroundColor:
                                  colorScheme[AppStrings.essentialColor],
                              deleteIcon: Icon(
                                Icons.close,
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                              onDeleted: _isEditing
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
                      onPressed: _isEditing
                          ? () => setState(() {
                                _showSpecialtiesDropdown = !_showSpecialtiesDropdown;
                              })
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colorScheme[AppStrings.secondaryColor] ??
                              Colors.white,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        _selectedSpecialty.isNotEmpty
                            ? _selectedSpecialty
                            : AppStrings.selectSpecialty,
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
                                            color: colorScheme[
                                                AppStrings.secondaryColor],
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Radio<String>(
                                          value: specialty,
                                          groupValue: _selectedSpecialty,
                                          onChanged: _isEditing
                                              ? (String? value) {
                                                  _selectedSpecialty = value!;
                                                  _showSpecialtiesDropdown =
                                                      false;
                                                  setState(() {});
                                                }
                                              : null,
                                          activeColor: colorScheme[
                                              AppStrings.secondaryColor],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index != _specialtiesList.length - 1)
                                  Divider(
                                    color: colorScheme[AppStrings.secondaryColor]
                                        ?.withOpacity(0.3),
                                    height: 1,
                                    thickness: 1,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
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
                      AppStrings.instagram,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _instagramController,
                      onChanged: (value) => _instagramLink = value,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme[AppStrings.primaryColorLight],
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        labelText: AppStrings.instagramLinkPlaceholder,
                        labelStyle: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        errorText: _instagramLink.isNotEmpty &&
                                !_instagramLink.startsWith(
                                    "https://instagram.com/")
                            ? AppStrings.invalidInstagramLink
                            : null,
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
            Card(
              color: colorScheme[AppStrings.primaryColorLight],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.facebook,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _facebookController,
                      onChanged: (value) => _facebookLink = value,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme[AppStrings.primaryColorLight],
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor] ??
                                Colors.white,
                          ),
                        ),
                        labelText: AppStrings.facebookLinkPlaceholder,
                        labelStyle: TextStyle(
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        errorText: _facebookLink.isNotEmpty &&
                                !_facebookLink.startsWith(
                                    "https://facebook.com/")
                            ? AppStrings.invalidFacebookLink
                            : null,
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
if ((_instagramLink.isNotEmpty &&
        _instagramLink.startsWith("https://instagram.com/")) ||
    (_facebookLink.isNotEmpty &&
        _facebookLink.startsWith("https://facebook.com/")))
  Column(
    children: [
      if (_instagramLink.isNotEmpty &&
          _instagramLink.startsWith("https://instagram.com/"))
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.profileProvider.myLaunchUrl(_instagramLink),
            style: ElevatedButton.styleFrom(
              foregroundColor: colorScheme[AppStrings.secondaryColor],
              backgroundColor: colorScheme[AppStrings.essentialColor],
              minimumSize: const Size(double.infinity, 40),
            ),
            child: Text(
              AppStrings.openInstagram,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      if (_facebookLink.isNotEmpty &&
          _facebookLink.startsWith("https://facebook.com/"))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.profileProvider.myLaunchUrl(_facebookLink),
              style: ElevatedButton.styleFrom(
                foregroundColor: colorScheme[AppStrings.secondaryColor],
                backgroundColor: colorScheme[AppStrings.essentialColor],
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text(
                AppStrings.openFacebook,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
    ],
  ),

          ],
        ),
      ),
    );
  }
}
