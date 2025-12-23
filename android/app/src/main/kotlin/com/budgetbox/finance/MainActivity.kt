package com.budgetbox.finance

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.os.PowerManager

class MainActivity : FlutterFragmentActivity() {
    private val MOBILE_NETWORK_CHANNEL = "mobile_network_channel"
    private val BATTERY_CHANNEL = "battery_channel"
    private val NETWORK_INFO_CHANNEL = "network_info_channel"

    @Override
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Регистрируем плагины
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Инициализируем MobileNetworkInfo
        val mobileNetworkInfo = MobileNetworkInfo(applicationContext)

        // Настраиваем канал для получения информации о мобильной сети
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MOBILE_NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getMobileNetworkName") {
                    result.success(mobileNetworkInfo.getMobileNetworkName())
                } else {
                    result.notImplemented()
                }
            }

        // Настраиваем канал для получения информации о режиме энергосбережения
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "isLowPowerMode") {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(powerManager.isPowerSaveMode)
                } else {
                    result.notImplemented()
                }
            }

        // Создаем экземпляр NetworkInfoPlugin
        val networkInfoPlugin = NetworkInfoPlugin(applicationContext)

        // Настраиваем канал для получения детальной информации о сети
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_INFO_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getDetailedWifiInfo") {
                    result.success(networkInfoPlugin.getDetailedWifiInfo())
                } else {
                    result.notImplemented()
                }
            }
    }
}