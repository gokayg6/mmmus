package com.omechat.app

import android.os.Build
import android.os.Bundle
import android.view.Window
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set frame rate to 120Hz with FIXED_SOURCE compatibility - Android 12+ (API 31+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window?.let { window ->
                try {
                    // Use reflection to call setFrameRate (available in Android 12+)
                    val setFrameRateMethod = Window::class.java.getMethod(
                        "setFrameRate",
                        Float::class.java,
                        Int::class.java
                    )
                    // FRAME_RATE_COMPATIBILITY_FIXED_SOURCE = 1
                    setFrameRateMethod.invoke(window, 120f, 1)
                } catch (e: Exception) {
                    // Method not available, continue with default
                }
            }
        }
    }
}
