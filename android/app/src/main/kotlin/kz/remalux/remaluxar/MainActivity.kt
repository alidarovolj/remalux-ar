package kz.remalux.remaluxar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.yandex.mapkit.MapKitFactory

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MapKitFactory.setLocale("ru_RU")
        MapKitFactory.setApiKey("4bf65d20-262c-427a-bd53-c9d12d3c2a7f")
        super.configureFlutterEngine(flutterEngine)
    }
} 