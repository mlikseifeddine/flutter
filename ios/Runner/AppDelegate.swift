import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private let CHANNEL = "cie_login_flutter/cie_auth"
    private let NOTIFICATION_NAME = "RETURN_FROM_CIEID"
    
    // Riferimento al MethodChannel per inviare callback a Flutter
    private var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Crea il MethodChannel
        methodChannel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "isCieIdInstalled":
                result(self?.isCieIdInstalled() ?? false)
                
            case "openCieIdApp":
                if let args = call.arguments as? [String: Any],
                   let url = args["url"] as? String {
                    result(self?.openCieIdApp(urlString: url) ?? false)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", 
                                       message: "URL non fornito", 
                                       details: nil))
                }
                
            case "openCieIdAppStore":
                self?.openAppStore()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Gestione URL Scheme (ritorno da CieID)
    
    // Per iOS 9-12
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        handleCieIdCallback(url: url)
        return true
    }
    
    // Per iOS 13+ con SceneDelegate (se non usi SceneDelegate)
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if let url = userActivity.webpageURL {
            handleCieIdCallback(url: url)
        }
        return true
    }
    
    // MARK: - Metodi CieID
    
    /// Verifica se l'app CieID è installata
    private func isCieIdInstalled() -> Bool {
        guard let cieIdUrl = URL(string: "CIEID://") else {
            return false
        }
        return UIApplication.shared.canOpenURL(cieIdUrl)
    }
    
    /// Apre l'app CieID con l'URL specificato
    private func openCieIdApp(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
        }
        return false
    }
    
    /// Apre l'App Store alla pagina di CieID
    private func openAppStore() {
        let appStoreUrl = "https://apps.apple.com/it/app/cieid/id1504644677"
        if let url = URL(string: appStoreUrl) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /// Gestisce il callback dall'app CieID e lo invia a Flutter
    private func handleCieIdCallback(url: URL) {
        var urlString = url.absoluteString
        
        // Cerca https:// nell'URL
        if let httpsRange = urlString.range(of: "https://") {
            // Rimuove il prefisso dell'URL Scheme
            let startPos = urlString.distance(from: urlString.startIndex, to: httpsRange.lowerBound)
            urlString = String(urlString.dropFirst(startPos))
            
            // Invia il callback a Flutter! 👈 IMPORTANTE
            methodChannel?.invokeMethod("onCieIdCallback", arguments: ["url": urlString])
            
            // Invia anche la notifica (per compatibilità)
            let response: [String: String] = ["payload": urlString]
            NotificationCenter.default.post(
                name: Notification.Name(NOTIFICATION_NAME),
                object: nil,
                userInfo: response
            )
        }
    }
}