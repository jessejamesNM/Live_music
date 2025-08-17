// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Esta pantalla es un widget desplegable que permite a los usuarios aplicar filtros de búsqueda para eventos de música.
// Los filtros disponibles incluyen tipo de evento, tipo de música, fecha, rango de precios y tipo de servicio.
// Es una interfaz interactiva con un diseño basado en tarjetas expandibles que permiten la selección de filtros.
// Recomendaciones: Asegúrate de validar los filtros correctamente antes de enviarlos a la base de datos. La implementación de los filtros es flexible y puede expandirse según las necesidades del proyecto.
// Características:
// - Filtros dinámicos para seleccionar el tipo de evento, género musical, fecha, precio y tipo de servicio.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/search/search_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../event_card.dart';
import 'date_card.dart';
import 'expandible_card.dart';
import 'music_chip.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopDropdown extends StatefulWidget {
  final SearchProvider searchProvider;
  final bool isVisible;
  final VoidCallback onClose;
  final String? currentUserId;
  final Function(List<String>) onFilterApplied;

  const TopDropdown({
    required this.searchProvider,
    required this.isVisible,
    required this.onClose,
    required this.currentUserId,
    required this.onFilterApplied,
    Key? key,
  }) : super(key: key);

  @override
  _TopDropdownState createState() => _TopDropdownState();
}

class _TopDropdownState extends State<TopDropdown> {
  ExpandedCard? expandedCard = ExpandedCard.ServiceType;
  String? selectedEvent;
  Set<String> selectedGenres = {};
  DateTime? selectedDay;
  RangeValues priceRange = const RangeValues(200, 200000);
  int minPrice = 200;
  int maxPrice = 200000;
  bool useTextFieldValues = false;
  bool isTransitioning = false;
  final int maxPriceLimit = 200000;

  // Estado para el tipo de servicio
  String? selectedServiceType;

  // Controladores para los campos de texto
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    minPriceController.text = '\$$minPrice';
    maxPriceController.text = '\$$maxPrice';
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  void onEventSelected(String event) async {
    setState(() {
      selectedEvent = selectedEvent == event ? null : event;
    });

    await Future.delayed(Duration(milliseconds: 300));

    setState(() {
      if (selectedServiceType == 'artist') {
        expandedCard = ExpandedCard.MusicType;
      } else {
        expandedCard = ExpandedCard.Date;
      }
    });
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void onNextClicked(ExpandedCard? currentCard) {
    setState(() {
      expandedCard = null;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        expandedCard = _getNextCard(currentCard);
      });
    });
  }

  ExpandedCard? _getNextCard(ExpandedCard? currentCard) {
    if (selectedServiceType != 'artist') {
      switch (currentCard) {
        case ExpandedCard.ServiceType:
          return ExpandedCard.EventType;
        case ExpandedCard.EventType:
          return ExpandedCard.Date;
        case ExpandedCard.Date:
          return ExpandedCard.Price;
        case ExpandedCard.Price:
        case ExpandedCard.MusicType:
        case null:
          return null;
      }
    } else {
      switch (currentCard) {
        case ExpandedCard.ServiceType:
          return ExpandedCard.EventType;
        case ExpandedCard.EventType:
          return ExpandedCard.MusicType;
        case ExpandedCard.MusicType:
          return ExpandedCard.Date;
        case ExpandedCard.Date:
          return ExpandedCard.Price;
        case ExpandedCard.Price:
        case null:
          return null;
      }
    }
  }

  void _applyFilters() async {
    final searchProvider = widget.searchProvider;

    if (minPrice > maxPrice) {
      showToast(AppStrings.priceRangeError);
      return;
    }

    if (maxPrice > maxPriceLimit) {
      showToast('El precio máximo no puede exceder \$$maxPriceLimit');
      return;
    }

    if (selectedServiceType == null) {
      showToast('Seleccione un tipo de servicio');
      return;
    }

    try {
      final userId = widget.currentUserId;
      if (userId == null) return;

      final availability = selectedDay?.toString() ?? '';

      await searchProvider.loadCountryAndState(userId);

      await searchProvider.getUsersByCountry(
        userId,
        selectedServiceType == 'artist' ? selectedGenres.toList() : [],
        RangeValues(minPrice.toDouble(), maxPrice.toDouble()),
        availability,
        selectedServiceType!,
      );

      widget.onClose();
    } catch (e) {
      showToast(AppStrings.filterErrorMessage);
    }
  }

  void _handleMinPriceChange(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    final newMinPrice = int.tryParse(cleanValue) ?? 0;

    if (newMinPrice > maxPriceLimit) {
      showToast('El precio mínimo no puede exceder \$$maxPriceLimit');
      return;
    }

    setState(() {
      minPrice = newMinPrice;
      priceRange = RangeValues(newMinPrice.toDouble(), priceRange.end);
      useTextFieldValues = true;
    });

    minPriceController.text = '\$$cleanValue';
    minPriceController.selection = TextSelection.fromPosition(
      TextPosition(offset: minPriceController.text.length),
    );
  }

  void _handleMaxPriceChange(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    final newMaxPrice = int.tryParse(cleanValue) ?? 0;

    if (newMaxPrice > maxPriceLimit) {
      showToast('El precio máximo no puede exceder \$$maxPriceLimit');
      return;
    }

    setState(() {
      maxPrice = newMaxPrice;
      priceRange = RangeValues(priceRange.start, newMaxPrice.toDouble());
      useTextFieldValues = true;
    });

    maxPriceController.text = '\$$cleanValue';
    maxPriceController.selection = TextSelection.fromPosition(
      TextPosition(offset: maxPriceController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldWidth = screenWidth / 4;

    final showMusicType = selectedServiceType == 'artist';

    return Stack(
      children: [
        if (widget.isVisible)
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.5),
            ),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: widget.isVisible ? 0 : -MediaQuery.of(context).size.height,
          left: 0,
          right: 0,
          child: Material(
            color: colorScheme[AppStrings.primaryColor],
            child: SafeArea(
              minimum: EdgeInsets.zero,
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                widget.onClose();
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: colorScheme[AppStrings.primaryColor],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        colorScheme[AppStrings
                                            .secondaryColor] ??
                                        Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: colorScheme[AppStrings.secondaryColor],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.filterRecommended,
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Column(
                              children: [
                                ExpandableCard(
                                  title: "Tipo de servicio",
                                  isExpanded:
                                      expandedCard == ExpandedCard.ServiceType,
                                  onClick: () {
                                    setState(() {
                                      if (expandedCard !=
                                          ExpandedCard.ServiceType) {
                                        expandedCard = ExpandedCard.ServiceType;
                                      }
                                    });
                                  },
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "¿Qué servicio buscas?",
                                        style: TextStyle(
                                          fontSize: 22,
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 160,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: [
                                            _ServiceOptionCard(
                                              text: "musica",
                                              svgAsset: AppStrings.icMusicAsset,
                                              isSelected:
                                                  selectedServiceType ==
                                                  'artist',
                                              onTap: () {
                                                setState(() {
                                                  selectedServiceType =
                                                      'artist';
                                                  selectedGenres.clear();
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            _ServiceOptionCard(
                                              text: 'Repostería/Alimentos',
                                              svgAsset:
                                                  'assets/svg/reposteria.svg',
                                              isSelected:
                                                  selectedServiceType ==
                                                  'bakery',
                                              onTap: () {
                                                setState(() {
                                                  selectedServiceType =
                                                      'bakery';
                                                  selectedGenres.clear();
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            _ServiceOptionCard(
                                              text: 'Local de eventos',
                                              svgAsset:
                                                  'assets/svg/eventplace.svg',
                                              isSelected:
                                                  selectedServiceType ==
                                                  'place',
                                              onTap: () {
                                                setState(() {
                                                  selectedServiceType = 'place';
                                                  selectedGenres.clear();
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            _ServiceOptionCard(
                                              text: 'Decoraciones',
                                              svgAsset:
                                                  'assets/svg/decoration.svg',
                                              isSelected:
                                                  selectedServiceType ==
                                                  'decoration',
                                              onTap: () {
                                                setState(() {
                                                  selectedServiceType =
                                                      'decoration';
                                                  selectedGenres.clear();
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            _ServiceOptionCard(
                                              text: 'Mueblería',
                                              svgAsset:
                                                  'assets/svg/ic_furniture.svg',
                                              isSelected:
                                                  selectedServiceType ==
                                                  'furniture',
                                              onTap: () {
                                                setState(() {
                                                  selectedServiceType =
                                                      'furniture';
                                                  selectedGenres.clear();
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            _ServiceOptionCard(
                                              text: 'Entretenimiento',
                                              svgAsset:
                                                  'assets/svg/ic_entertainment.svg',
                                              isSelected:
                                                  selectedServiceType ==
                                                  'entertainment',
                                              onTap: () {
                                                setState(() {
                                                  selectedServiceType =
                                                      'entertainment';
                                                  selectedGenres.clear();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (expandedCard ==
                                          ExpandedCard.ServiceType)
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: TextButton(
                                            onPressed:
                                                () =>
                                                    onNextClicked(expandedCard),
                                            child: Text(
                                              AppStrings.next,
                                              style: TextStyle(
                                                color:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                ExpandableCard(
                                  title: AppStrings.eventType,
                                  isExpanded:
                                      expandedCard == ExpandedCard.EventType,
                                  onClick: () {
                                    setState(() {
                                      if (expandedCard !=
                                          ExpandedCard.EventType) {
                                        expandedCard = ExpandedCard.EventType;
                                      }
                                    });
                                  },
                                  content: Column(
                                    children: [
                                      Text(
                                        AppStrings.whatEventType,
                                        style: TextStyle(
                                          fontSize: 22,
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 150,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              EventCard(
                                                text: AppStrings.weddings,
                                                iconPath:
                                                    'assets/svg/ic_marriage.svg',
                                                isSelected:
                                                    selectedEvent ==
                                                    AppStrings.weddings,
                                                onClick:
                                                    () => onEventSelected(
                                                      AppStrings.weddings,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              EventCard(
                                                text: AppStrings.quinceaneras,
                                                iconPath:
                                                    'assets/svg/ic_quinceanera.svg',
                                                isSelected:
                                                    selectedEvent ==
                                                    AppStrings.quinceaneras,
                                                onClick:
                                                    () => onEventSelected(
                                                      AppStrings.quinceaneras,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              EventCard(
                                                text: AppStrings.casualParties,
                                                iconPath:
                                                    'assets/svg/ic_party.svg',
                                                isSelected:
                                                    selectedEvent ==
                                                    AppStrings.casualParties,
                                                onClick:
                                                    () => onEventSelected(
                                                      AppStrings.casualParties,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              EventCard(
                                                text: AppStrings.publicEvents,
                                                iconPath:
                                                    'assets/svg/ic_public_event.svg',
                                                isSelected:
                                                    selectedEvent ==
                                                    AppStrings.publicEvents,
                                                onClick:
                                                    () => onEventSelected(
                                                      AppStrings.publicEvents,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              EventCard(
                                                text: 'Cumpleaños',
                                                iconPath:
                                                    'assets/svg/ic_birthday.svg',
                                                isSelected:
                                                    selectedEvent ==
                                                    'Cumpleaños',
                                                onClick:
                                                    () => onEventSelected(
                                                      'Cumpleaños',
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              EventCard(
                                                text: 'Conferencia',
                                                iconPath:
                                                    'assets/svg/ic_conferencia.svg',
                                                isSelected:
                                                    selectedEvent ==
                                                    'Conferencia',
                                                onClick:
                                                    () => onEventSelected(
                                                      'Conferencia',
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              EventCard(
                                                text: 'Posada',
                                                iconPath:
                                                    'assets/svg/ic_piñata.svg',
                                                isSelected:
                                                    selectedEvent == 'Posada',
                                                onClick:
                                                    () => onEventSelected(
                                                      'Posada',
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              EventCard(
                                                text: 'Graduación',
                                                iconPath:
                                                    'assets/svg/ic_graduaciones.svg',
                                                isSelected:
                                                    selectedEvent ==
                                                    'Graduación',
                                                onClick:
                                                    () => onEventSelected(
                                                      'Graduación',
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                if (showMusicType)
                                  ExpandableCard(
                                    title: AppStrings.musicType,
                                    isExpanded:
                                        expandedCard == ExpandedCard.MusicType,
                                    onClick: () {
                                      setState(() {
                                        if (expandedCard !=
                                            ExpandedCard.MusicType) {
                                          expandedCard = ExpandedCard.MusicType;
                                        }
                                      });
                                    },
                                    content: Column(
                                      children: [
                                        Text(
                                          AppStrings.whatMusicType,
                                          style: TextStyle(
                                            fontSize: 22,
                                            color:
                                                colorScheme[AppStrings
                                                    .secondaryColor],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 135,
                                          child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: [
                                              for (String genre in [
                                                AppStrings.band,
                                                AppStrings.nortStyle,
                                                AppStrings.corridos,
                                                AppStrings.mariachi,
                                                AppStrings.montainStyle,
                                                AppStrings.cumbia,
                                                AppStrings.reggaeton,
                                              ])
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8.0,
                                                      ),
                                                  child: MusicChip(
                                                    text: genre,
                                                    isSelected: selectedGenres
                                                        .contains(genre),
                                                    onClick: () {
                                                      setState(() {
                                                        if (selectedGenres
                                                            .contains(genre)) {
                                                          selectedGenres.remove(
                                                            genre,
                                                          );
                                                        } else {
                                                          selectedGenres.add(
                                                            genre,
                                                          );
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (expandedCard ==
                                            ExpandedCard.MusicType)
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: TextButton(
                                              onPressed:
                                                  () => onNextClicked(
                                                    expandedCard,
                                                  ),
                                              child: Text(
                                                AppStrings.next,
                                                style: TextStyle(
                                                  color:
                                                      colorScheme[AppStrings
                                                          .secondaryColor],
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                if (showMusicType) const SizedBox(height: 16),

                                ExpandableCard(
                                  title: AppStrings.date,
                                  isExpanded: expandedCard == ExpandedCard.Date,
                                  onClick: () {
                                    setState(() {
                                      if (expandedCard != ExpandedCard.Date) {
                                        expandedCard = ExpandedCard.Date;
                                      }
                                    });
                                  },
                                  content: Column(
                                    children: [
                                      DateCard(
                                        selectedDate: selectedDay,
                                        onDateSelected: (DateTime day) {
                                          setState(() {
                                            selectedDay = day;
                                          });
                                        },
                                      ),
                                      if (expandedCard == ExpandedCard.Date)
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: TextButton(
                                            onPressed:
                                                () =>
                                                    onNextClicked(expandedCard),
                                            child: Text(
                                              AppStrings.next,
                                              style: TextStyle(
                                                color:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                ExpandableCard(
                                  title: "Presupuesto",
                                  isExpanded:
                                      expandedCard == ExpandedCard.Price,
                                  onClick: () {
                                    setState(() {
                                      if (expandedCard != ExpandedCard.Price) {
                                        expandedCard = ExpandedCard.Price;
                                      }
                                    });
                                  },
                                  content: Column(
                                    children: [
                                      Text(
                                        AppStrings.indicateHourlyRate,
                                        style: TextStyle(
                                          fontSize: 22,
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      RangeSlider(
                                        values: priceRange,
                                        min: 0,
                                        max: maxPriceLimit.toDouble(),
                                        divisions: 100,
                                        onChanged: (RangeValues values) {
                                          if (values.end > maxPriceLimit) {
                                            showToast(
                                              'El precio máximo no puede exceder \$$maxPriceLimit',
                                            );
                                            return;
                                          }

                                          setState(() {
                                            priceRange = values;
                                            minPrice = values.start.toInt();
                                            maxPrice = values.end.toInt();
                                            useTextFieldValues = false;
                                            minPriceController.text =
                                                '\$${minPrice.toString()}';
                                            maxPriceController.text =
                                                '\$${maxPrice.toString()}';
                                          });
                                        },
                                        activeColor:
                                            colorScheme[AppStrings
                                                .essentialColor],
                                      ),
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  AppStrings.minimum,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        colorScheme[AppStrings
                                                            .secondaryColor],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  width: textFieldWidth,
                                                  child: TextField(
                                                    controller:
                                                        minPriceController,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme[AppStrings
                                                              .secondaryColor],
                                                    ),
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                      ),
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged:
                                                        _handleMinPriceChange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                  AppStrings.maximum,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        colorScheme[AppStrings
                                                            .secondaryColor],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  width: textFieldWidth,
                                                  child: TextField(
                                                    controller:
                                                        maxPriceController,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme[AppStrings
                                                              .secondaryColor],
                                                    ),
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                      ),
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged:
                                                        _handleMaxPriceChange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (expandedCard == ExpandedCard.Price)
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: TextButton(
                                            onPressed:
                                                () =>
                                                    onNextClicked(expandedCard),
                                            child: Text(
                                              AppStrings.next,
                                              style: TextStyle(
                                                color:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                if (selectedEvent != null &&
                                    selectedDay != null &&
                                    selectedServiceType != null &&
                                    (selectedServiceType != 'artist' ||
                                        (selectedServiceType == 'artist' &&
                                            selectedGenres.isNotEmpty)))
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _applyFilters,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              colorScheme[AppStrings
                                                  .essentialColor],
                                          foregroundColor:
                                              colorScheme[AppStrings
                                                  .essentialColor],
                                        ),
                                        child: Text(
                                          AppStrings.applyFilters,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceOptionCard extends StatelessWidget {
  final String text;
  final String svgAsset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceOptionCard({
    required this.text,
    required this.svgAsset,
    required this.isSelected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme[AppStrings.essentialColor]?.withOpacity(0.2)
                  : colorScheme[AppStrings.primaryColor],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? colorScheme[AppStrings.essentialColor] ?? Colors.blue
                    : colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                svgAsset,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ExpandedCard { EventType, MusicType, Date, Price, ServiceType }
