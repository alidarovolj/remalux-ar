package com.example.remalux_ar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.yandex.mapkit.MapKitFactory

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            MapKitFactory.setLocale("ru_RU")
            val apiKey = context.getString(R.string.yandex_mapkit_key)
            MapKitFactory.setApiKey(apiKey)
            super.configureFlutterEngine(flutterEngine)
        } catch (e: Exception) {
            e.printStackTrace()
            super.configureFlutterEngine(flutterEngine)
        }
    }
}
