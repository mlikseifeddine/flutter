import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Configurazione del Service Provider
/// IMPORTANTE: Sostituisci questi valori con quelli del tuo Service Provider federato
class CieConfig {
  /// URL del Service Provider per l'autenticazione CIE
  /// Deve essere un Service Provider registrato presso l'AGID
  static const String serviceProviderUrl = 'https://demo.ecivis.it/opid/sso/login?sp=democie&idp=CIETEST&u=a';
  
  /// URL dell'ambiente di collaudo (per test)
  static const String testServiceProviderUrl = 'https://demo.ecivis.it/opid/sso/login?sp=democie&idp=CIETEST&u=a';
  
  /// Package name dell'app CieID per Android
  static const String cieIdAndroidPackage = 'it.ipzs.cieid';
  
  /// Package name dell'app CieID di collaudo per Android
  static const String cieIdAndroidTestPackage = 'it.ipzs.cieid.coll';
  
  /// URL App Store per CieID iOS
  static const String cieIdAppStoreUrl = 'https://apps.apple.com/it/app/cieid/id1504644677';
  
  /// URL Play Store per CieID Android
  static const String cieIdPlayStoreUrl = 'https://play.google.com/store/apps/details?id=it.ipzs.cieid';
  
  /// Schema URL per aprire CieID su iOS
  static const String cieIdIosScheme = 'CIEID://';
  
  /// Usa ambiente di test
  static bool useTestEnvironment = false;
  
  /// Ottiene l'URL del Service Provider corrente
  static String get currentSpUrl => 
      useTestEnvironment ? testServiceProviderUrl : serviceProviderUrl;
}

/// Risultato dell'autenticazione CIE
class CieAuthResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? userData;

  CieAuthResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.userData,
  });

  factory CieAuthResult.success(Map<String, dynamic>? userData) {
    return CieAuthResult(success: true, userData: userData);
  }

  factory CieAuthResult.error(String message, {String? code}) {
    return CieAuthResult(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  factory CieAuthResult.cancelled() {
    return CieAuthResult(
      success: false,
      errorMessage: 'Autenticazione annullata dall\'utente',
      errorCode: 'USER_CANCELLED',
    );
  }
}

/// Servizio per la gestione dell'autenticazione con CIE
/// Supporta sia Android che iOS
class CieAuthService {
  static const MethodChannel _channel = MethodChannel('cie_login_flutter/cie_auth');
  
  /// Verifica se l'app CieID è installata sul dispositivo
  static Future<bool> isCieIdAppInstalled() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidCieIdInstalled();
      } else if (Platform.isIOS) {
        return await _checkIosCieIdInstalled();
      }
      return false;
    } catch (e) {
      print('Errore verifica CieID: $e');
      return false;
    }
  }
  
  /// Verifica CieID su Android
  static Future<bool> _checkAndroidCieIdInstalled() async {
    try {
      final result = await _channel.invokeMethod('isCieIdInstalled');
      return result == true;
    } on MissingPluginException {
      // Se il plugin nativo non è implementato, prova con url_launcher
      final uri = Uri.parse('package:${CieConfig.cieIdAndroidPackage}');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
  
  /// Verifica CieID su iOS
  static Future<bool> _checkIosCieIdInstalled() async {
    try {
      final result = await _channel.invokeMethod('isCieIdInstalled');
      return result == true;
    } on MissingPluginException {
      // Se il plugin nativo non è implementato, prova con url_launcher
      final uri = Uri.parse(CieConfig.cieIdIosScheme);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
  
  /// Apre lo store appropriato per scaricare CieID
  static Future<void> openCieIdStore() async {
    final String storeUrl;
    
    if (Platform.isAndroid) {
      storeUrl = CieConfig.cieIdPlayStoreUrl;
    } else if (Platform.isIOS) {
      storeUrl = CieConfig.cieIdAppStoreUrl;
    } else {
      return;
    }
    
    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  /// Apre l'app CieID (se installata)
  static Future<bool> openCieIdApp(String url) async {
    try {
      if (Platform.isAndroid) {
        return await _openAndroidCieId(url);
      } else if (Platform.isIOS) {
        return await _openIosCieId(url);
      }
      return false;
    } catch (e) {
      print('Errore apertura CieID: $e');
      return false;
    }
  }
  
  /// Apre CieID su Android
  static Future<bool> _openAndroidCieId(String url) async {
    try {
      final result = await _channel.invokeMethod('openCieIdApp', {'url': url});
      return result == true;
    } on MissingPluginException {
      // Fallback: usa url_launcher
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    }
  }
  
  /// Apre CieID su iOS
  static Future<bool> _openIosCieId(String url) async {
    try {
      final result = await _channel.invokeMethod('openCieIdApp', {'url': url});
      return result == true;
    } on MissingPluginException {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    }
  }
  
  /// Ottiene informazioni sul dispositivo
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'isAndroid': Platform.isAndroid,
      'isIOS': Platform.isIOS,
    };
  }
}
