package com.example.cie_login_flutter

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "cie_login_flutter/cie_auth"
    
    // Package dell'app CieID
    private val CIE_ID_PACKAGE = "it.ipzs.cieid"
    private val CIE_ID_PACKAGE_TEST = "it.ipzs.cieid.coll"
    private val CIE_ID_CLASS_NAME = "it.ipzs.cieid.BaseActivity"
    
    // URL key per il ritorno da CieID
    private val URL_KEY = "URL"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isCieIdInstalled" -> {
                    result.success(isCieIdInstalled())
                }
                "openCieIdApp" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        result.success(openCieIdApp(url))
                    } else {
                        result.error("INVALID_ARGUMENT", "URL non fornito", null)
                    }
                }
                "openCieIdAppStore" -> {
                    openPlayStore()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Verifica se l'app CieID è installata
     */
    private fun isCieIdInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo(CIE_ID_PACKAGE, 0)
            true
        } catch (e: Exception) {
            // Prova con l'app di collaudo
            try {
                packageManager.getPackageInfo(CIE_ID_PACKAGE_TEST, 0)
                true
            } catch (e: Exception) {
                false
            }
        }
    }
    
    /**
     * Apre l'app CieID con l'URL specificato
     */
    private fun openCieIdApp(url: String): Boolean {
        val intent = Intent()
        
        return try {
            // Prova prima con l'app di produzione
            intent.setClassName(CIE_ID_PACKAGE, CIE_ID_CLASS_NAME)
            intent.data = Uri.parse(url)
            intent.action = Intent.ACTION_VIEW
            startActivityForResult(intent, 0)
            true
        } catch (e: ActivityNotFoundException) {
            // Prova con l'app di collaudo
            try {
                intent.setClassName(CIE_ID_PACKAGE_TEST, CIE_ID_CLASS_NAME)
                intent.data = Uri.parse(url)
                intent.action = Intent.ACTION_VIEW
                startActivityForResult(intent, 0)
                true
            } catch (e: ActivityNotFoundException) {
                false
            }
        }
    }
    
    /**
     * Apre il Play Store alla pagina di CieID
     */
    private fun openPlayStore() {
        try {
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=$CIE_ID_PACKAGE")
                )
            )
        } catch (e: Exception) {
            // Fallback al browser se Play Store non è disponibile
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=$CIE_ID_PACKAGE")
                )
            )
        }
    }
    
    /**
     * Gestisce il ritorno dall'app CieID
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        // Recupera l'URL di callback da CieID
        val callbackUrl = data?.getStringExtra(URL_KEY)
        
        if (callbackUrl != null) {
            // Invia l'URL al codice Flutter tramite un evento
            // La WebView gestirà il caricamento di questo URL
            flutterEngine?.dartExecutor?.let { dartExecutor ->
                MethodChannel(dartExecutor.binaryMessenger, CHANNEL).invokeMethod(
                    "onCieIdCallback",
                    mapOf("url" to callbackUrl)
                )
            }
        }
    }
}
