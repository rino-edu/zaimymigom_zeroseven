package com.budgetbox.finance

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

class NetworkInfoPlugin(private val context: Context) {

    fun getDetailedWifiInfo(): Map<String, Any> {
        val result = HashMap<String, Any>()

        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo

            // Получение силы сигнала WiFi (0-100)
            val signalStrength = WifiManager.calculateSignalLevel(wifiInfo.rssi, 100)
            result["strength"] = signalStrength

            // Получение частоты WiFi (в MHz)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                result["frequency"] = wifiInfo.frequency
            } else {
                result["frequency"] = 0
            }

            // Получение скорости соединения (в Mbps)
            result["linkSpeed"] = wifiInfo.linkSpeed

            // В более новых версиях Android доступны Tx и Rx скорости
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                result["txLinkSpeed"] = wifiInfo.txLinkSpeedMbps
                result["rxLinkSpeed"] = wifiInfo.rxLinkSpeedMbps
            } else {
                result["txLinkSpeed"] = wifiInfo.linkSpeed
                result["rxLinkSpeed"] = wifiInfo.linkSpeed
            }

            // Проверяем, дорогое ли соединение
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = connectivityManager.activeNetwork
                val capabilities = connectivityManager.getNetworkCapabilities(network)
                if (capabilities != null) {
                    result["isConnectionExpensive"] = !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
                } else {
                    result["isConnectionExpensive"] = false
                }
            } else {
                result["isConnectionExpensive"] = false
            }

        } catch (e: Exception) {
            // Логируем ошибку
            android.util.Log.e("NetworkInfoPlugin", "Error getting WiFi info: ${e.message}")
            
            // Возвращаем значения по умолчанию при ошибке
            result["strength"] = 0
            result["frequency"] = 0
            result["linkSpeed"] = 0
            result["txLinkSpeed"] = 0
            result["rxLinkSpeed"] = 0
            result["isConnectionExpensive"] = false
        }

        return result
    }

    // Преобразование числа в IP-адрес формата строки
    private fun intToIp(ipAddress: Int): String {
        return (ipAddress and 0xFF).toString() + "." +
                (ipAddress shr 8 and 0xFF) + "." +
                (ipAddress shr 16 and 0xFF) + "." +
                (ipAddress shr 24 and 0xFF)
    }
}