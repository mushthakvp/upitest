package com.yourcompany.upi_payment_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "upi_payment_channel"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAppInstallation" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val isInstalled = isAppInstalled(packageName)
                        result.success(isInstalled)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "launchApp" -> {
                    val scheme = call.argument<String>("scheme")
                    if (scheme != null) {
                        val launched = launchAppWithScheme(scheme)
                        result.success(launched)
                    } else {
                        result.error("INVALID_ARGUMENT", "Scheme is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleUPIResponse(intent)
    }

    override fun onResume() {
        super.onResume()
        handleUPIResponse(intent)
    }

    private fun handleUPIResponse(intent: Intent?) {
        intent?.let {
            val data = it.data
            if (data != null && data.scheme == "upi") {
                parseUPIResponse(data)
            } else {
                // Check for UPI response in extras
                val response = it.getStringExtra("response")
                if (response != null) {
                    parseUPIResponseString(response)
                }
            }
        }
    }

    private fun parseUPIResponse(uri: Uri) {
        val status = uri.getQueryParameter("Status") ?: 
                    uri.getQueryParameter("status") ?: "FAILURE"
        val txnId = uri.getQueryParameter("txnId") ?: 
                   uri.getQueryParameter("ApprovalRefNo") ?: ""
        val response = uri.toString()
        
        sendResponseToFlutter(status, txnId, response)
    }

    private fun parseUPIResponseString(response: String) {
        try {
            val params = response.split("&").associate {
                val parts = it.split("=", limit = 2)
                if (parts.size == 2) parts[0] to parts[1] else parts[0] to ""
            }
            
            val status = params["Status"] ?: params["status"] ?: "FAILURE"
            val txnId = params["txnId"] ?: params["ApprovalRefNo"] ?: ""
            
            sendResponseToFlutter(status, txnId, response)
        } catch (e: Exception) {
            sendResponseToFlutter("FAILURE", "", response)
        }
    }

    private fun sendResponseToFlutter(status: String, txnId: String, response: String) {
        methodChannel?.invokeMethod("onPaymentResponse", mapOf(
            "status" to status,
            "txnId" to txnId,
            "response" to response
        ))
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun launchAppWithScheme(scheme: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(scheme))
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}

