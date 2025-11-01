package com.example.geodesy

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.sqrt
import kotlin.math.atan

class CameraFocalLengthPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.example.geodesy/camera_focal_length"
        )
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAllCameraFocalLengths" -> getAllCameraFocalLengths(result)
            "getCameraFullInfo" -> {
                val cameraId = call.argument<String>("cameraId") ?: "0"
                result.success(getCameraDetails(cameraId))
            }
            "getCameraFocalLength" -> {
                val cameraId = call.argument<String>("cameraId")
                if (cameraId != null) {
                    getCameraFocalLength(cameraId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Camera ID is required", null)
                }
            }
            "getCameraSensorSize" -> {
                val cameraId = call.argument<String>("cameraId")
                if (cameraId != null) {
                    getCameraSensorSize(cameraId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Camera ID is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Получить все данные по камере */
    private fun getCameraDetails(cameraId: String): Map<String, Any> {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val characteristics = cameraManager.getCameraCharacteristics(cameraId)

        val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
        val apertures = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_APERTURES)
        val stabilization = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION)
        val sensorSize = characteristics.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)

        if (focalLengths == null || sensorSize == null || focalLengths.isEmpty()) {
            return emptyMap()
        }

        val focal = focalLengths[0]
        val width = sensorSize.width
        val height = sensorSize.height

        val diagSensor = sqrt(width * width + height * height)
        val diag35mm = sqrt(36.0 * 36.0 + 24.0 * 24.0)
        val focal35mm = focal * (diag35mm / diagSensor)
        val hfov = 2 * atan(width / (2 * focal)) * 180 / Math.PI
        val vfov = 2 * atan(height / (2 * focal)) * 180 / Math.PI
        val magnification = focal35mm / 50.0

        return mapOf(
            "focalLengths" to focalLengths.map { it.toDouble() },
            "apertures" to (apertures?.map { it.toDouble() } ?: emptyList()),
            "stabilization" to (stabilization?.map { it.toInt() } ?: emptyList()),
            "sensorSize" to mapOf("width" to width, "height" to height),
            "focalLength35mm" to focal35mm,
            "horizontalFov" to hfov,
            "verticalFov" to vfov,
            "magnification" to magnification
        )
    }

    private fun getCameraSensorSize(cameraId: String, result: Result) {
        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val sensorSize = characteristics.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
            if (sensorSize != null) {
                val sensorData = mapOf(
                    "width" to sensorSize.width.toDouble(),
                    "height" to sensorSize.height.toDouble()
                )
                result.success(sensorData)
            } else {
                result.error("NOT_AVAILABLE", "Sensor size not available for camera $cameraId", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get sensor size for camera $cameraId: ${e.message}", null)
        }
    }

    private fun getAllCameraFocalLengths(result: Result) {
        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val allFocalLengths = mutableMapOf<String, List<Double>>()

            for (cameraId in cameraManager.cameraIdList) {
                try {
                    val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                    val focalLengths = getFocalLengthsFromCharacteristics(characteristics)
                    allFocalLengths[cameraId] = focalLengths
                } catch (_: Exception) { }
            }

            result.success(allFocalLengths)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get camera focal lengths: ${e.message}", null)
        }
    }

    private fun getCameraFocalLength(cameraId: String, result: Result) {
        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val focalLengths = getFocalLengthsFromCharacteristics(characteristics)
            result.success(focalLengths)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get focal length for camera $cameraId: ${e.message}", null)
        }
    }

    private fun getFocalLengthsFromCharacteristics(characteristics: CameraCharacteristics): List<Double> {
        val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
        return if (focalLengths != null && focalLengths.isNotEmpty()) {
            focalLengths.map { it.toDouble() }
        } else {
            listOf(4.5) // fallback
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
