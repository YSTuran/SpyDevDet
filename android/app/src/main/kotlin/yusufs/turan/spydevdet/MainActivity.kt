package yusufs.turan.spydevdet

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NETWORK_INFO_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "getNetworkSnapshot") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            readNetworkSnapshot(result)
        }
    }

    private fun readNetworkSnapshot(result: MethodChannel.Result) {
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork = connectivityManager.activeNetwork
        if (activeNetwork == null) {
            result.error("NO_ACTIVE_NETWORK", "Etkin bir ağ bağlantısı bulunamadı.", null)
            return
        }

        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
        if (capabilities == null) {
            result.error("NETWORK_UNAVAILABLE", "Ağ özellikleri okunamadı.", null)
            return
        }
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
            result.error(
                "VPN_ACTIVE",
                "VPN açıkken yanlış ağın taranmasını önlemek için tarama durduruldu.",
                null,
            )
            return
        }
        if (!capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            result.error("WIFI_REQUIRED", "Yerel ağ taraması için Wi-Fi bağlantısı gereklidir.", null)
            return
        }

        val linkProperties = connectivityManager.getLinkProperties(activeNetwork)
        if (linkProperties == null) {
            result.error("LINK_UNAVAILABLE", "Wi-Fi bağlantı bilgileri okunamadı.", null)
            return
        }

        val linkAddress = linkProperties.linkAddresses.firstOrNull {
            val address = it.address
            address is Inet4Address && !address.isLoopbackAddress && !address.isLinkLocalAddress
        }
        if (linkAddress == null) {
            result.error("NO_IPV4_ADDRESS", "Telefonun yerel IPv4 adresi bulunamadı.", null)
            return
        }

        val gateway = linkProperties.routes
            .asSequence()
            .filter { it.isDefaultRoute }
            .mapNotNull { it.gateway }
            .firstOrNull { it is Inet4Address }

        result.success(
            mapOf(
                "localIpv4" to linkAddress.address.hostAddress,
                "prefixLength" to linkAddress.prefixLength,
                "interfaceName" to (linkProperties.interfaceName ?: "bilinmiyor"),
                "gatewayIpv4" to gateway?.hostAddress,
                "isWifi" to true,
                "isEthernet" to false,
                "isVpn" to false,
            ),
        )
    }

    private companion object {
        const val NETWORK_INFO_CHANNEL = "yusufs.turan.spydevdet/network_info"
    }
}
