package yusufs.turan.spydevdet

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.Inet4Address
import java.net.InetAddress
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NETWORK_INFO_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNetworkSnapshot" -> readNetworkSnapshot(result)
                "acquireMulticastLock" -> acquireMulticastLock(result)
                "releaseMulticastLock" -> releaseMulticastLock(result)
                "getNeighborSnapshot" -> readNeighborSnapshot(result)
                "discoverReachableHosts" -> discoverReachableHosts(call, result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        releaseMulticastLock(null)
        super.onDestroy()
    }

    private fun acquireMulticastLock(result: MethodChannel.Result) {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val lock = multicastLock ?: wifiManager.createMulticastLock("SpyDevDet-MulticastDiscovery").also {
                it.setReferenceCounted(false)
                multicastLock = it
            }
            if (!lock.isHeld) {
                lock.acquire()
            }
            result.success(null)
        } catch (error: SecurityException) {
            result.error("MULTICAST_LOCK_DENIED", "Çok noktaya yayın kilidi alınamadı.", null)
        }
    }

    private fun releaseMulticastLock(result: MethodChannel.Result?) {
        val lock = multicastLock
        if (lock?.isHeld == true) {
            lock.release()
        }
        result?.success(null)
    }

    private fun readNeighborSnapshot(result: MethodChannel.Result) {
        val entries = mutableListOf<Map<String, String>>()
        try {
            File("/proc/net/arp").useLines { lines ->
                lines.drop(1).take(512).forEach { line ->
                    val columns = line.trim().split(Regex("\\s+"))
                    if (columns.size >= 4 &&
                        IPV4_PATTERN.matches(columns[0]) &&
                        MAC_PATTERN.matches(columns[3])
                    ) {
                        entries.add(
                            mapOf(
                                "ipAddress" to columns[0],
                                "macAddress" to columns[3].uppercase(),
                            ),
                        )
                    }
                }
            }
            result.success(mapOf("available" to true, "entries" to entries))
        } catch (_: Exception) {
            result.success(mapOf("available" to false, "entries" to emptyList<Any>()))
        }
    }

    private fun discoverReachableHosts(call: MethodCall, result: MethodChannel.Result) {
        val rawTargets = call.argument<List<*>>("targets")
        if (rawTargets == null || rawTargets.size > MAX_REACHABILITY_TARGETS) {
            result.error(
                "INVALID_REACHABILITY_TARGETS",
                "Erişilebilirlik hedefleri geçersiz.",
                null,
            )
            return
        }
        val timeoutMillis =
            (call.argument<Number>("timeoutMillis")?.toInt() ?: DEFAULT_REACHABILITY_TIMEOUT_MS)
                .coerceIn(MIN_REACHABILITY_TIMEOUT_MS, MAX_REACHABILITY_TIMEOUT_MS)
        val targets = rawTargets
            .mapNotNull { it as? String }
            .distinct()
            .filter { target ->
                if (!IPV4_PATTERN.matches(target)) {
                    false
                } else {
                    try {
                        val address = InetAddress.getByName(target)
                        address is Inet4Address && address.isSiteLocalAddress
                    } catch (_: Exception) {
                        false
                    }
                }
            }

        if (targets.isEmpty()) {
            result.success(emptyList<String>())
            return
        }

        val mainHandler = Handler(Looper.getMainLooper())
        Thread({
            val executor = Executors.newFixedThreadPool(
                minOf(REACHABILITY_WORKERS, targets.size),
            )
            try {
                val checks = targets.associateWith { target ->
                    executor.submit<Boolean> {
                        try {
                            InetAddress.getByName(target).isReachable(
                                null,
                                REACHABILITY_TTL,
                                timeoutMillis,
                            )
                        } catch (_: Exception) {
                            false
                        }
                    }
                }
                val reachable = checks.mapNotNull { (target, check) ->
                    if (check.get()) target else null
                }
                mainHandler.post { result.success(reachable) }
            } catch (_: Exception) {
                mainHandler.post {
                    result.error(
                        "REACHABILITY_FAILED",
                        "Yerel ağ erişilebilirlik kontrolü tamamlanamadı.",
                        null,
                    )
                }
            } finally {
                executor.shutdownNow()
            }
        }, "SpyDevDet-Reachability").start()
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
        const val MAX_REACHABILITY_TARGETS = 254
        const val REACHABILITY_WORKERS = 32
        const val REACHABILITY_TTL = 1
        const val DEFAULT_REACHABILITY_TIMEOUT_MS = 500
        const val MIN_REACHABILITY_TIMEOUT_MS = 100
        const val MAX_REACHABILITY_TIMEOUT_MS = 2_000
        val IPV4_PATTERN = Regex("^(?:\\d{1,3}\\.){3}\\d{1,3}$")
        val MAC_PATTERN = Regex("^(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")
    }
}
