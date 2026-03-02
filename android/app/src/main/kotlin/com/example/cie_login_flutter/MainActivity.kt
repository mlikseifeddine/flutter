package com.example.cie_login_flutter

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "cie_login_flutter/cie_auth"
    private val TAG = "CieLogin"
    
    // Package dell'app CieID
    private val CIE_ID_PACKAGE = "it.ipzs.cieid"
    private val CIE_ID_PACKAGE_TEST = "it.ipzs.cieid.coll"
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
        return isPackageInstalled(CIE_ID_PACKAGE) || isPackageInstalled(CIE_ID_PACKAGE_TEST)
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Apre l'app CieID con l'URL specificato
     */
    private fun openCieIdApp(url: String): Boolean {
        Log.d(TAG, "Opening CieID with URL: $url")

        if (url.startsWith("intent://")) {
            return openIntentUrl(url)
        }

        val appUrl = Uri.parse(url)

        return try {
            val genericIntent = Intent(Intent.ACTION_VIEW, appUrl).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            if (genericIntent.resolveActivity(packageManager) != null) {
                startActivityForResult(genericIntent, 0)
                true
            } else {
                Log.e(TAG, "No activity found for URL: $url")
                false
            }
        } catch (e: ActivityNotFoundException) {
            Log.e(TAG, "No handler for URL: $url", e)
            false
        }
    }

    private fun openIntentUrl(url: String): Boolean {
        return try {
            val intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME).apply {
                addCategory(Intent.CATEGORY_BROWSABLE)
                component = null
                selector = null
            }

            startActivityForResult(intent, 0)
            true
        } catch (e: ActivityNotFoundException) {
            Log.e(TAG, "CieID app not found for intent URL", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing intent URL", e)
            false
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
