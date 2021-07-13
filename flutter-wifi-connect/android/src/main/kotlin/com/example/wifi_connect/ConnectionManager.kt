package com.example.wifi_connect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.ScanResult
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.util.Log

class ConnectionManager(val ctx: Context, val wifi: WifiManager) {
    fun scanAndConnect(
            ssid: String,
            password: String,
            hidden: Boolean,
            capabilities: String,
            onDone: (WifiConnectStatus) -> Unit
    ) {
        if (hidden) {
            onDone(connect(ssid, password, capabilities, hidden = true))
            return
        }

        scan { results ->
            Log.d(TAG, "Scan results: ${results.map { it.SSID }}")

            for (it in results) {
                if (ssid == it.SSID) {
                    onDone(connect(ssid, password, it.capabilities))
                    return@scan
                }
            }

            onDone(WifiConnectStatus.NOT_FOUND)
        }
    }

    fun scan(onDone: (List<ScanResult>) -> Unit) {
        ctx.registerReceiver(
                object : BroadcastReceiver() {
                    override fun onReceive(context: Context, intent: Intent) {
                        ctx.unregisterReceiver(this)
                        onDone(wifi.scanResults)
                    }
                },
                IntentFilter().apply {
                    addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
                }
        )
        wifi.startScan()
    }

    fun connect(
            ssid: String,
            password: String,
            capabilities: String,
            hidden: Boolean = false
    ): WifiConnectStatus {


        if (Build.VERSION.SDK_INT >= 29) {
            val sbuilder: WifiNetworkSpecifier.Builder = WifiNetworkSpecifier.Builder()
            sbuilder.setSsid(ssid)
            sbuilder.setIsHiddenSsid(hidden)
            sbuilder.setWpa2Passphrase(password)
            sbuilder.build()

            val request: NetworkRequest = NetworkRequest.Builder()
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .setNetworkSpecifier(sbuilder.build())
                    .build()
            val connectivityManager: ConnectivityManager = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    Log.d("Bersh", "connected")
                }
                // etc.
            }
            connectivityManager.requestNetwork(request, networkCallback);
            return WifiConnectStatus.OK
        }

        //Make new configuration
        var conf = WifiConfiguration()

        //clear alloweds
        conf.allowedAuthAlgorithms.clear()
        conf.allowedGroupCiphers.clear()
        conf.allowedKeyManagement.clear()
        conf.allowedPairwiseCiphers.clear()
        conf.allowedProtocols.clear()

        // Quote ssid and password
        conf.SSID = String.format("\"%s\"", ssid)

        getExistingWifiConfig(conf.SSID)?.let {
            Log.d("Bersh", "Removing existing network")
            wifi.removeNetwork(it.networkId)
        }

        Log.d("Bersh", "aaaaa")

        // appropriate ciper is need to set according to security type used
        if (
                capabilities.contains("WPA")
                || capabilities.contains("WPA2")
                || capabilities.contains("WPA/WPA2 PSK")
        ) {
            Log.d("Bersh", "inside if wpa2")
            conf.preSharedKey = String.format("\"%s\"", password)
            // This is needed for WPA/WPA2
            // Reference - https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/wifi/java/android/net/wifi/WifiConfiguration.java#149
            conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.OPEN)

            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.TKIP)

            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK)

            conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.CCMP)
            conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.TKIP)

            conf.allowedProtocols.set(WifiConfiguration.Protocol.RSN)
            conf.allowedProtocols.set(WifiConfiguration.Protocol.WPA)
            conf.status = WifiConfiguration.Status.ENABLED
        } else if (capabilities.contains("WEP")) {
            // This is needed for WEP
            // Reference - https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/wifi/java/android/net/wifi/WifiConfiguration.java#149
            conf.wepKeys[0] = "\"" + password + "\""
            conf.wepTxKeyIndex = 0
            conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.OPEN)
            conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.SHARED)
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.WEP40)
        } else {
            Log.d("Bersh", "inside if none")
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
        }

        var newNetwork = -1

        // Use the existing network config if exists
        for (wifiConfig in wifi.configuredNetworks) {
            Log.d("Bersh", "Configurated SSID: ${wifiConfig.SSID}")
            if (wifiConfig.SSID == conf.SSID) {
                conf = wifiConfig
                newNetwork = conf.networkId
                Log.d("Bersh", "Found network with the same ssid")
            }
        }

        conf.hiddenSSID = hidden

        // If network not already in configured networks add new network
        if (newNetwork == -1) {
            newNetwork = wifi.addNetwork(conf)
            wifi.saveConfiguration()

            for (wifiConfig in wifi.configuredNetworks) {
                if (wifiConfig.SSID == conf.SSID) {
                    conf = wifiConfig
                    newNetwork = conf.networkId
                }
            }
            Log.d("Bersh", "Added new network")
        }

        // if network not added return false
        if (newNetwork == -1) {
            Log.d("Bersh", "newNetwork == -1 AAAAAAA")
            return WifiConnectStatus.FAILED
        }

        // disconnect current network
        val disconnect = wifi.disconnect()
        if (!disconnect) {
            return WifiConnectStatus.FAILED
        }

        // enable new network
        val success = wifi.enableNetwork(newNetwork, true)

        return if (success) {
            WifiConnectStatus.OK
        } else {
            WifiConnectStatus.FAILED
        }
    }

    fun getExistingWifiConfig(ssid: String): WifiConfiguration? {
        for (config in wifi.configuredNetworks) {
            if (config.SSID == "\"" + ssid + "\"") {
                return config
            }
        }
        return null
    }

    fun disconnect(ssid: String) {
        Log.d("Bersh", "Wifi disconnect")
        if (Build.VERSION.SDK_INT < 29) {
            wifi.disconnect()
            getExistingWifiConfig(ssid)?.let {
                Log.d("Bersh", "Removing existing network")
                wifi.removeNetwork(it.networkId)
            }
        }
    }
}