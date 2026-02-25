import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private let CHANNEL = "cie_login_flutter/cie_auth"
    private let NOTIFICATION_NAME = "RETURN_FROM_CIEID"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        let cieChannel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        
        cieChannel.setMethodCallHandler { [weak self] (call, result) in
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
    
    // Gestisce l'apertura dell'app tramite URL Scheme
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        handleCieIdCallback(url: url)
        return true
    }
    
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
    
    /// Gestisce il callback dall'app CieID
    private func handleCieIdCallback(url: URL) {
        var urlString = url.absoluteString
        
        if let httpsRange = urlString.range(of: "https://") {
            let startPos = urlString.distance(from: urlString.startIndex, to: httpsRange.lowerBound)
            urlString = String(urlString.dropFirst(startPos))
            
            let response: [String: String] = ["payload": urlString]
            NotificationCenter.default.post(
                name: Notification.Name(NOTIFICATION_NAME),
                object: nil,
                userInfo: response
            )
        }
    }
}
