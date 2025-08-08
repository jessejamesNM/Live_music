/// --------------------------------------------------------------
/// Archivo creado el 26 de abril de 2025
/// Autor: KingdomOfJames
///
/// Descripción:
/// Clase utilitaria para gestionar deep links en una app Flutter.
/// Permite manejar el enlace inicial cuando se abre la app y escuchar
/// nuevos eventos de deep links durante la ejecución.
///
/// Características:
/// - Obtiene el enlace inicial con MethodChannel.
/// - Escucha eventos de nuevos enlaces con EventChannel.
/// - Procesa el enlace para navegar a la pantalla correcta usando GoRouter.
///
/// Recomendaciones:
/// - Implementar más validaciones sobre los deep links para mayor seguridad.
/// - Capturar mejor errores de redirección o enlaces inválidos.
/// - Agregar soporte para más tipos de "modes" en el deep link si se necesita.
///
/// --------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class DeepLinkHandler {
  // Canal para obtener el enlace inicial desde la plataforma nativa
  static const platform = MethodChannel('app.channel/deeplink');

  // Canal para escuchar eventos de nuevos deep links
  static final EventChannel _eventChannel = EventChannel(
    'app.channel/deeplink/events',
  );

  // Stream expuesto para recibir deep links
  static Stream<String> get deepLinkStream =>
      _eventChannel.receiveBroadcastStream().cast<String>();

  /// Maneja los deep links cuando se inicia o mientras corre la app
  static Future<bool> handleDeepLink(
    BuildContext context,
    GoRouter router,
  ) async {
    try {
      // 1. Intentar obtener el enlace inicial si existe
      final initialLink = await _getInitialLink();
      if (initialLink != null && initialLink.isNotEmpty) {
        return processDeepLink(context, router, initialLink);
      }

      // 2. Escuchar nuevos enlaces recibidos en tiempo real
      deepLinkStream.listen((link) {
        if (link.isNotEmpty && context.mounted) {
          processDeepLink(context, router, link);
        }
      });

      return false;
    } catch (e) {
      // Error al manejar los enlaces (por ejemplo, permisos o implementación faltante)
      return false;
    }
  }

  /// Obtiene el enlace inicial que abrió la app (si existiera)
  static Future<String?> _getInitialLink() async {
    try {
      return await platform.invokeMethod<String>('getInitialLink');
    } on MissingPluginException {
      // Si el método no está implementado en la plataforma, simplemente ignorar
      return null;
    } on PlatformException {
      // Error genérico al intentar obtener el enlace
      return null;
    }
  }

  /// Procesa el deep link recibido y navega a la pantalla correspondiente
  static bool processDeepLink(
    BuildContext context,
    GoRouter router,
    String uriString,
  ) {
    try {
      final uri = Uri.tryParse(uriString);
      if (uri == null) {
        // URI inválida, no hacer nada
        return false;
      }

      // Obtener el parámetro 'mode' del query string
      final mode = uri.queryParameters['mode']?.toLowerCase() ?? '';

      if (!context.mounted) return false;

      // Navegar de forma asíncrona para no interrumpir el build actual
      Future.microtask(() {
        if (mode == 'resetpassword') {
          router.go('/resetpassword?link=${Uri.encodeComponent(uriString)}');
        } else if (mode == 'verifyemail') {
          router.go("/verifyemail");
        } else {
          // Si no reconoce el modo, llevar al usuario a una pantalla por defecto
          router.go("/selectionscreen");
        }
      });

      return true;
    } catch (e) {
      // Error procesando el deep link
      return false;
    }
  }
}
