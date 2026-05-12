package com.example.purestatus_clone

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.purestatus_clone/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareToWhatsApp" -> {
                        val filePath = call.argument<String>("filePath")!!
                        val mimeType = call.argument<String>("mimeType")!!
                        shareFileToWhatsApp(filePath, mimeType, null, result)
                    }
                    "shareToMyself" -> {
                        val filePath = call.argument<String>("filePath")!!
                        val mimeType = call.argument<String>("mimeType")!!
                        val phone = call.argument<String>("phone") ?: ""
                        shareFileToWhatsApp(filePath, mimeType, phone, result)
                    }
                    "isWhatsAppInstalled" -> {
                        try {
                            packageManager.getPackageInfo("com.whatsapp", 0)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareFileToWhatsApp(
        filePath: String,
        mimeType: String,
        targetPhone: String?,
        result: MethodChannel.Result
    ) {
        try {
            val file = File(filePath)
            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                // 🔹 This is the magic – opens YOUR OWN chat
                if (!targetPhone.isNullOrBlank()) {
                    putExtra("jid", "${targetPhone}@s.whatsapp.net")
                }
            }

            startActivity(intent)
            result.success(true)

        } catch (e: Exception) {
            // WhatsApp not installed or other error – fallback to share sheet
            try {
                val file = File(filePath)
                val uri: Uri = FileProvider.getUriForFile(
                    this,
                    "${packageName}.fileprovider",
                    file
                )
                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                    type = mimeType
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(Intent.createChooser(shareIntent, "Share via"))
                result.success(true)
            } catch (e2: Exception) {
                result.error("SHARE_ERROR", e2.message, null)
            }
        }
    }
}

