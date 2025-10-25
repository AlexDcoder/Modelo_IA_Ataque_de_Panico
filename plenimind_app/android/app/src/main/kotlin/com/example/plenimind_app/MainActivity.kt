package com.example.plenimind_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.samsung.android.sdk.healthdata.*

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.plenimind/samsung_health"
    private lateinit var mStore: HealthDataStore

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getHealthData") {
                    connectToSamsungHealth(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun connectToSamsungHealth(result: MethodChannel.Result) {
        mStore = HealthDataStore(this, object : HealthDataStore.ConnectionListener {
            override fun onConnected() {
                val dados = getHealthData()
                result.success(dados)
            }

            override fun onConnectionFailed(error: HealthConnectionErrorResult) {
                if (error.errorCode == HealthConnectionErrorResult.OLD_VERSION_PLATFORM) {
                    result.error("OLD_VERSION_PLATFORM", "Atualize o Samsung Health", null)
                } else if (error.hasResolution()) {
                    error.resolve(this@MainActivity)
                } else {
                    result.error("CONNECTION_FAILED", "Falha ao conectar", null)
                }
            }

            override fun onDisconnected() {}
        })
        mStore.connectService()
    }

    private fun getHealthData(): Map<String, Any> {
        val resolver = HealthDataResolver(mStore, null)
        val dados = mutableMapOf<String, Any>()

        // Exemplo: batimento cardíaco
        val request = HealthDataResolver.ReadRequest.Builder()
            .setDataType(HealthConstants.HeartRate.HEALTH_DATA_TYPE)
            .setProperties(arrayOf(HealthConstants.HeartRate.HEART_RATE))
            .build()

        resolver.read(request).setResultListener { result ->
            for (data in result) {
                dados["hr"] = data.getInt(HealthConstants.HeartRate.HEART_RATE)
            }
            result.close()
        }

        // Aqui você pode adicionar passos, SpO2, nível de estresse, etc.

        return dados
    }
}
