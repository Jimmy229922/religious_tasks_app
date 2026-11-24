package com.jimmy.religiousapp

import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.sqrt

class QiblaSensorHandler(
    private val context: Context,
    messenger: BinaryMessenger
) : EventChannel.StreamHandler, SensorEventListener {

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val rotationVectorSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val magnetometerSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    private val accelerometerSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    private var eventSink: EventChannel.EventSink? = null
    private var latitude: Double = 21.4225
    private var longitude: Double = 39.8262
    private var altitude: Double = 0.0

    private var lastAccuracyStatus: Int = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
    private var lastMagneticUt: Double = 45.0
    private var lastAccel: FloatArray? = null
    private var lastMag: FloatArray? = null
    private var lastEmitMs: Long = 0L

    private val rotationMatrix = FloatArray(9)
    private val remappedMatrix = FloatArray(9)
    private val orientationAngles = FloatArray(3)

    init {
        EventChannel(messenger, "religious_tasks_app/qibla_sensor").setStreamHandler(this)
        MethodChannel(messenger, "religious_tasks_app/qibla_control").setMethodCallHandler { call, result ->
            when (call.method) {
                "setLocation" -> {
                    latitude = call.argument<Double>("latitude") ?: latitude
                    longitude = call.argument<Double>("longitude") ?: longitude
                    altitude = call.argument<Double>("altitude") ?: 0.0
                    result.success(null)
                }
                "getSensorCapabilities" -> {
                    result.success(
                        mapOf(
                            "hasRotationVector" to (rotationVectorSensor != null),
                            "hasMagnetometer" to (magnetometerSensor != null),
                            "hasAccelerometer" to (accelerometerSensor != null)
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (magnetometerSensor == null) {
            events?.error("NO_MAGNETOMETER", "Magnetometer sensor not available on device", null)
            return
        }

        if (rotationVectorSensor != null) {
            sensorManager.registerListener(this, rotationVectorSensor, SensorManager.SENSOR_DELAY_UI)
        } else if (accelerometerSensor != null) {
            sensorManager.registerListener(this, accelerometerSensor, SensorManager.SENSOR_DELAY_UI)
        }
        sensorManager.registerListener(this, magnetometerSensor, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        eventSink = null
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD || sensor?.type == Sensor.TYPE_ROTATION_VECTOR) {
            lastAccuracyStatus = accuracy
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        val sink = eventSink ?: return

        when (event.sensor.type) {
            Sensor.TYPE_MAGNETIC_FIELD -> {
                val x = event.values[0].toDouble()
                val y = event.values[1].toDouble()
                val z = event.values[2].toDouble()
                lastMagneticUt = sqrt(x * x + y * y + z * z)
                lastMag = event.values.clone()
                if (rotationVectorSensor == null && lastAccel != null) {
                    if (SensorManager.getRotationMatrix(rotationMatrix, null, lastAccel, lastMag)) {
                        emitOrientation(sink)
                    }
                }
            }
            Sensor.TYPE_ACCELEROMETER -> {
                lastAccel = event.values.clone()
            }
            Sensor.TYPE_ROTATION_VECTOR -> {
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                emitOrientation(sink)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun getScreenRotation(): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.display?.rotation ?: Surface.ROTATION_0
            } else {
                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.defaultDisplay.rotation
            }
        } catch (_: Exception) {
            Surface.ROTATION_0
        }
    }

    private fun emitOrientation(sink: EventChannel.EventSink) {
        val nowMs = System.currentTimeMillis()
        if (nowMs - lastEmitMs < 40L) return
        lastEmitMs = nowMs

        val (axisX, axisY) = when (getScreenRotation()) {
            Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
        }

        SensorManager.remapCoordinateSystem(rotationMatrix, axisX, axisY, remappedMatrix)
        SensorManager.getOrientation(remappedMatrix, orientationAngles)

        val magneticDeg = ((Math.toDegrees(orientationAngles[0].toDouble()) % 360.0) + 360.0) % 360.0
        val pitchDeg = Math.toDegrees(orientationAngles[1].toDouble())
        val rollDeg = Math.toDegrees(orientationAngles[2].toDouble())
        val isFlat = abs(pitchDeg) <= 35.0 && abs(rollDeg) <= 35.0

        val geoField = GeomagneticField(
            latitude.toFloat(),
            longitude.toFloat(),
            altitude.toFloat(),
            nowMs
        )
        val declination = geoField.declination.toDouble()
        val trueDeg = ((magneticDeg + declination) % 360.0 + 360.0) % 360.0
        val interference = lastMagneticUt < 20.0 || lastMagneticUt > 70.0

        sink.success(
            mapOf(
                "trueHeading" to trueDeg,
                "magneticHeading" to magneticDeg,
                "declination" to declination,
                "accuracyStatus" to lastAccuracyStatus,
                "magneticFieldUt" to lastMagneticUt,
                "magneticInterference" to interference,
                "isFlat" to isFlat,
                "hasRotationVector" to (rotationVectorSensor != null)
            )
        )
    }
}
