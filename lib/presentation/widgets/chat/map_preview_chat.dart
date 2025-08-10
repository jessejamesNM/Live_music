/*
Fecha de creación: 26 de abril de 2025
Autor: KingdomOfJames

Descripción general:
Este widget 'MapPreviewChat' muestra una previsualización estática de una ubicación en Google Maps dentro de la app.
Al hacer clic en el mapa o en el botón, redirige a la aplicación de Google Maps para ver la ubicación completa.

Características:
- Muestra un mapa con un marcador en las coordenadas especificadas.
- No permite gestos de interacción en el mapa (es estático para evitar confusiones).
- Incluye un pequeño botón flotante que también abre Google Maps.
- Adaptable mediante el parámetro de tamaño.

Recomendaciones:
- Verificar siempre que la API de Google Maps esté configurada correctamente para evitar errores de mapa en blanco.
- Opcionalmente, se podría agregar una imagen de mapa estático como fallback si falla la carga del mapa.

Notas adicionales:
- Se podría optimizar usando una imagen estática en lugar de GoogleMap si solo se desea visualización.
- Actualmente se usa `Future.delayed` para mover la cámara después de un breve retardo; puede mejorarse con controladores avanzados de Google Maps.
*/

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPreviewChat extends StatelessWidget {
  final double latitude; // Latitud de la ubicación a mostrar
  final double longitude; // Longitud de la ubicación a mostrar
  final double size; // Tamaño del mapa (por defecto 250)

  const MapPreviewChat({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.size = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se define la posición inicial del mapa basado en las coordenadas recibidas
    final coordinates = LatLng(latitude, longitude);
    final cameraPosition = CameraPosition(target: coordinates, zoom: 15);

    return AspectRatio(
      aspectRatio: 1, // Mantiene el mapa cuadrado
      child: GestureDetector(
        onTap:
            () => _openGoogleMaps(context), // Abre Google Maps al tocar el mapa
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Muestra el mapa de Google Maps
                GoogleMap(
                  initialCameraPosition: cameraPosition,
                  markers: {
                    Marker(
                      markerId: MarkerId('locationMarker'),
                      position: coordinates,
                      infoWindow: InfoWindow(
                        title: AppStrings.sentLocation,
                        snippet:
                            '${AppStrings.latitude}: ${latitude.toStringAsFixed(6)}, ${AppStrings.longitude}: ${longitude.toStringAsFixed(6)}',
                      ),
                    ),
                  },
                  zoomControlsEnabled: false, // No muestra controles de zoom
                  scrollGesturesEnabled: false, // No permite scroll
                  zoomGesturesEnabled:
                      false, // No permite hacer zoom con gestos
                  tiltGesturesEnabled: false, // No permite cambiar inclinación
                  rotateGesturesEnabled: false, // No permite rotar
                  onTap:
                      (_) => _openGoogleMaps(
                        context,
                      ), // También abre Google Maps al tocar cualquier parte
                  onMapCreated: (GoogleMapController controller) {
                    // Después de crear el mapa, mueve ligeramente la cámara para asegurar que cargue bien
                    Future.delayed(Duration(milliseconds: 300), () {
                      controller.moveCamera(
                        CameraUpdate.newLatLng(coordinates),
                      );
                    });
                  },
                ),
                // Botón flotante en la esquina para abrir Google Maps
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _openGoogleMaps(context),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.map, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Función que intenta abrir Google Maps con la ubicación especificada
  Future<void> _openGoogleMaps(BuildContext context) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Muestra un mensaje si no puede abrir Google Maps
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.googleMapsNotInstalled)),
      );
    }
  }
}
