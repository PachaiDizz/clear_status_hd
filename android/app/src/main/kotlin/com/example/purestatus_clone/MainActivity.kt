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

                        try {
                            val file = File(filePath)

                            // Use FileProvider — same technique as Pure Status
                            // This makes WhatsApp treat the file as received media
                            // instead of an upload, bypassing recompression
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
                            }

                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // WhatsApp not installed — fallback to share sheet
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
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(Intent.createChooser(intent, "Share via"))
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("SHARE_ERROR", e2.message, null)
                            }
                        }
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
}