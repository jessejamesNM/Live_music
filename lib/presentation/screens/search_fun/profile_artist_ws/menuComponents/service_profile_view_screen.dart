import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class ServicesProfileViewScreen extends StatefulWidget {
  final String userId;
  final GoRouter goRouter;

  const ServicesProfileViewScreen({
    super.key,
    required this.userId,
    required this.goRouter,
  });

  @override
  State<ServicesProfileViewScreen> createState() =>
      _ServicesProfileViewScreenState();
}

class _ServicesProfileViewScreenState extends State<ServicesProfileViewScreen> {
  Map<String, dynamic>? servicio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarServicioExistente();
  }

  Future<void> _cargarServicioExistente() async {
    try {
      final docSnap =
          await FirebaseFirestore.instance
              .collection('services')
              .doc(widget.userId)
              .get();

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data.containsKey('service')) {
          final serviceData = data['service'] as Map<String, dynamic>;
          serviceData['imageUrls'] = [serviceData['imageUrl']];
          serviceData['serviceId'] = 'service';

          setState(() {
            servicio = serviceData;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar servicio: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Container(
      color: colorScheme[AppStrings.primaryColor],
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Servicios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : servicio == null
                        ? Center(
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 500),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme[AppStrings.primaryColorLight]
                                  ?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme[AppStrings.secondaryColor]!
                                    .withOpacity(0.2),
                              ),
                            ),
                            height: 90,
                            child: Center(
                              child: Icon(
                                Icons.hourglass_empty,
                                color: colorScheme[AppStrings.secondaryColor],
                                size: 40,
                              ),
                            ),
                          ),
                        )
                        : ListView(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme[AppStrings.primaryColorLight]
                                    ?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme[AppStrings.secondaryColor]!
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  widget.goRouter.push(
                                    AppStrings.servicePreviewScreen,
                                    extra: {
                                      'userId': widget.userId,
                                      'serviceId': 'service',
                                    },
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (servicio!['imageUrls'].isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            servicio!['imageUrls'][0],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => const Icon(
                                                  Icons.broken_image_rounded,
                                                  size: 50,
                                                ),
                                            loadingBuilder:
                                                (_, child, progress) =>
                                                    progress == null
                                                        ? child
                                                        : const SizedBox(
                                                          width: 100,
                                                          height: 100,
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                        ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          servicio!['name'] ?? 'Servicio',
                                          style: TextStyle(
                                            color:
                                                colorScheme[AppStrings
                                                    .secondaryColor],
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
