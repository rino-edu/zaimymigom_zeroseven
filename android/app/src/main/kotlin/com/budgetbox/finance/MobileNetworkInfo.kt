package com.budgetbox.finance

import android.content.Context
import android.telephony.TelephonyManager
import android.os.Build

class MobileNetworkInfo(private val context: Context) {

    fun getMobileNetworkName(): String {
        return try {
            val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                // Для Android 9+ используем новый API
                val networkOperatorName = telephonyManager.networkOperatorName
                if (!networkOperatorName.isNullOrEmpty()) {
                    networkOperatorName
                } else {
                    "unknown"
                }
            } else {
                // Для более старых версий Android
                val networkOperatorName = telephonyManager.networkOperatorName
                if (!networkOperatorName.isNullOrEmpty()) {
                    networkOperatorName
                } else {
                    "unknown"
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MobileNetworkInfo", "Error getting network name: ${e.message}")
            "error_reading_carrier"
        }
    }
} 