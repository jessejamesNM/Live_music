
import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var initialLink: String?
    private var eventSink: FlutterEventSink?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Registrar plugins Flutter
        GeneratedPluginRegistrant.register(with: self)
        
        // Configurar API Key de Google Maps
        GMSServices.provideAPIKey("AIzaSyCYbig2C_P7jIU572lgl4xY5EZatQxoiTg")
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Configurar MethodChannel para el enlace inicial
        let methodChannel = FlutterMethodChannel(
            name: "app.channel/deeplink",
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "getInitialLink" {
                result(self?.initialLink)
                self?.initialLink = nil // Limpiar después de usar
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Configurar EventChannel para enlaces posteriores
        let eventChannel = FlutterEventChannel(
            name: "app.channel/deeplink/events",
            binaryMessenger: controller.binaryMessenger
        )
        
        eventChannel.setStreamHandler(self)
        
        // Manejar enlace inicial si la app se inicia desde un deep link
        if let url = launchOptions?[.url] as? URL {
            handleIncomingLink(url: url)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Manejo de Deep Links (URL Schemes)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        handleIncomingLink(url: url)
        return true
    }
    
    // Manejo de Universal Links
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            handleIncomingLink(url: url)
            return true
        }
        return false
    }
    
    private func handleIncomingLink(url: URL) {
        let link = url.absoluteString
        
        if eventSink != nil {
            // App ya está abierta, enviar por EventChannel
            eventSink?(link)
        } else {
            // Es el enlace inicial, guardar para cuando Flutter lo solicite
            initialLink = link
        }
    }
}

// Implementación de FlutterStreamHandler para el EventChannel
extension AppDelegate: FlutterStreamHandler {
    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        // Si hay un enlace inicial pendiente, enviarlo ahora
        if let link = initialLink {
            events(link)
            initialLink = nil
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
