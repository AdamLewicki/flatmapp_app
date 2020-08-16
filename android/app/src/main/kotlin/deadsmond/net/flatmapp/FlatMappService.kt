package deadsmond.net.flatmapp

import android.R
import android.app.IntentService
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.location.Location
import android.media.AudioManager
import android.media.RingtoneManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.provider.Settings.Global
import android.util.JsonReader
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import deadsmond.net.flatmapp.objects.Action
import deadsmond.net.flatmapp.objects.Marker
import io.flutter.Log
import java.io.*
import java.lang.Exception
import java.time.Instant
import java.util.*
import kotlin.collections.ArrayList
import kotlin.collections.HashMap


class FlatMappService : IntentService("FlatMapp Service"){

    val TAG = "FlatMapp Service"
    val DEFAULT_NOTIFICATION_SOUND: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var wifiManager: WifiManager
    private lateinit var bluetoothAdapter: BluetoothAdapter
    private var isRunning:Boolean = true


    override fun onCreate(){
        showLog("onCreate")
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        wifiManager = baseContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        //bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    }


    override fun onDestroy() {
        showLog("onDestroy")
        isRunning = false
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        showLog("onStartCommand")
        var builder:NotificationCompat.Builder = NotificationCompat.Builder(this, "FlatMappMesseges")
                .setContentText("FlatMapp Service")
                .setContentTitle("FlutMapp service is running in the background")
                .setSmallIcon(R.drawable.ic_popup_reminder)
                .setPriority(NotificationCompat.PRIORITY_LOW)

        startForeground(101, builder.build())
        //popUpNotification("Notification Title", "Notification Description")
//        var markerFile = File(markerPath + "/marker_storage.json")
//        showLog(markerFile.readText())
//        readMarkers()
//        for(marker:Marker in markers)
//        {
//            showLog("markerId : ${marker.id}, range : ${marker.range}, X : ${marker.position_x}, Y : ${marker.position_y}")
//        }
        return super.onStartCommand(intent, flags, startId)
    }

    private fun showLog(message : String){
        Log.d(TAG, message)
    }

    private fun readMarkers(markerFile:File):HashMap<String, Marker>{
        try {
                val targetStream: InputStream = FileInputStream(markerFile)
                val reader = JsonReader(InputStreamReader(targetStream, "UTF-8"))
                var markers = HashMap<String, Marker>()
                reader.beginObject()
                while (reader.hasNext()) {
                    var name = reader.nextName()
                    var marker = Marker()
                    marker.id = name
                    reader.beginObject()
                    while (reader.hasNext()) {
                        var name2 = reader.nextName()
                        when (name2) {
                            "position_x" -> {
                                marker.position_x = reader.nextString().toDouble()
                            }
                            "position_y" -> {
                                marker.position_y = reader.nextString().toDouble()
                            }
                            "range" -> {
                                marker.range = reader.nextString().toDouble()
                            }
                            "actions" -> {
                                reader.beginArray()
                                while (reader.hasNext()) {
                                    var action = Action()
                                    reader.beginObject()
                                    while (reader.hasNext()) {
                                        var name3 = reader.nextName()
                                        showLog(name3)
                                        when (name3) {
                                            "Action_Name" -> {
                                                action.name = reader.nextString()
                                            }
                                            "action_detail" -> {
                                                var params = reader.nextString()
                                                val paramsStream: InputStream = ByteArrayInputStream(params.toByteArray(Charsets.UTF_8))
                                                val paramReader = JsonReader(InputStreamReader(paramsStream, "UTF-8"))
                                                paramReader.beginObject()
                                                while(paramReader.hasNext())
                                                {
                                                    val paramName = paramReader.nextName()
                                                    when (paramName){
                                                        "param1" -> {
                                                            action.params[0] = paramReader.nextString()
                                                        }
                                                        "param2" -> {
                                                            action.params[1] = paramReader.nextString()
                                                        }
                                                        "param3" -> {
                                                            action.params[2] = paramReader.nextString()
                                                        }
                                                        "param4" -> {
                                                            action.params[3] = paramReader.nextString()
                                                        }
                                                        "param5" -> {
                                                            action.params[4] = paramReader.nextString()
                                                        }
                                                        else -> {
                                                            paramReader.skipValue()
                                                        }
                                                    }
                                                }
                                                paramReader.endObject()
                                                paramsStream.close()
                                            }
                                            else -> {
                                                reader.skipValue()
                                            }
                                        }
                                    }
                                    reader.endObject()
                                    marker.actions.add(action)
                                }
                                reader.endArray()
                            }
                            else -> {
                                reader.skipValue()
                            }
                        }
                    }
                    reader.endObject()
                    if (marker.id != "temporary") {
                        marker.location.latitude = marker.position_x
                        marker.location.longitude = marker.position_y
                        markers[marker.id] = marker
                    }
                }
                reader.endObject()
                targetStream.close()
                return markers
        }catch(e:Exception)
        {
            showLog(e.toString())
            return HashMap<String, Marker>()
        }
    }

    private fun isModified(date: Long, date2: Long):Boolean{
       return date2 > date
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private fun turnOnVibrationMode()
    {
        val audioManager: AudioManager = baseContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if(Global.getInt(contentResolver, "zen_mode") == 0)
            try {
                audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
            }catch(e:SecurityException){
                showLog(e.toString())
            }
    }


    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private fun setRingVolume(volume:Int)
    {
        val audioManager: AudioManager = baseContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try{
            audioManager.setStreamVolume(AudioManager.STREAM_RING, volume, 0)
        }catch(e:SecurityException){
            showLog(e.toString())
        }
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private fun setAlarmVolume(volume:Int)
    {
        val audioManager: AudioManager = baseContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try{
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, volume, 0)
        }catch(e:SecurityException){
            showLog(e.toString())
        }
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
    private fun setMusicVolume(volume:Int)
    {
        val audioManager: AudioManager = baseContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try{
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0)
        }catch(e:SecurityException){
            showLog(e.toString())
        }
    }

    private fun enableWIFI()
    {
        wifiManager.isWifiEnabled = true
    }


    private fun disableWIFI()
    {
        wifiManager.isWifiEnabled = false
    }

    private fun enableBluetooth()
    {
        if(!bluetoothAdapter.isEnabled)
            bluetoothAdapter.enable()
    }

    private fun disableBluetooth()
    {
        if(bluetoothAdapter.isEnabled)
            bluetoothAdapter.disable()
    }


    private fun popUpNotification(title : String, description : String){
        var builder:NotificationCompat.Builder = NotificationCompat.Builder(this, "FlatMappMesseges")
                .setContentText(description)
                .setContentTitle(title)
                .setSmallIcon(R.drawable.ic_popup_reminder)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setSound(DEFAULT_NOTIFICATION_SOUND)
        with(NotificationManagerCompat.from(this)){
            notify(102, builder.build())
        }
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }

    override fun onHandleIntent(p0: Intent?) {
        var markers = HashMap<String, Marker>()
        val activatedNow = mutableSetOf<String>()
        val activatedPreviously = mutableSetOf<String>()
        var markerPath = baseContext.filesDir.path + "/../app_flutter"
        var lastModified:Long = -1L
        while(isRunning) {
            try {
                val markerFile = File("$markerPath/marker_storage.json")
                if ((lastModified == -1L) or isModified(markerFile.lastModified(), lastModified)) {
                    markers = readMarkers(markerFile)

                }
            }catch(e:Exception){
                showLog(e.toString())
            }
            fusedLocationClient.lastLocation
                    .addOnSuccessListener { location: Location? ->
                        if (location != null) {
                            showLog("latitude: ${location.latitude}, longitude:${location.longitude}")
                            showLog(markers.keys.toString())
                            for(key in markers.keys)
                            {
                                val marker = markers[key]
                                if (marker != null) {
                                    if(key in activatedNow && key !in activatedPreviously && location.distanceTo(marker.location) <= marker.range){
                                      showLog("actions for marker: $key should be used here")
                                        for(action:Action in marker.actions)
                                        {
                                            when (action.name) {
                                                "notification" -> {
                                                    showLog("called notification action")
                                                    popUpNotification(action.params[0], action.params[1])
                                                }
                                                "mute" -> {
                                                    showLog("called mute action")
                                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                                                        setRingVolume(0)
                                                        setAlarmVolume(0)
                                                        setMusicVolume(0)
                                                    }
                                                }
                                                "bluetooth" -> {
                                                    showLog("called bluetooth action")
                                                    //enableBluetooth()
                                                }
                                                "wi-fi" ->
                                                {
                                                    showLog("called wi-fi action")
                                                    disableWIFI()
                                                }
                                                else ->{
                                                    showLog("unknown action")
                                                }
                                            }
                                        }
                                      activatedNow.remove(key)
                                      activatedPreviously.add(key)
                                    }
                                    if(key !in activatedPreviously && key !in activatedNow && location.distanceTo(marker.location) <= marker.range)
                                    {
                                        showLog("adding marker: $key to _activatedNow set")
                                        activatedNow.add(key)
                                    }
                                    if(key in activatedPreviously && location.distanceTo(marker.location) > marker.range)
                                    {
                                        showLog("marker: $key removed from _activatedPreviously")
                                        activatedPreviously.remove(key)
                                    }
//                                    showLog("markerId : ${marker.id}, range : ${marker.range}, X : ${marker.position_x}, Y : ${marker.position_y}")
                                }
                            }
                        }
                    }
            Thread.sleep(5000)
        }
    }
}
