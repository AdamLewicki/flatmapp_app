package deadsmond.net.flatmapp

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.wifi.WifiManager
import android.os.AsyncTask
import android.os.Build
import android.util.JsonReader
import android.util.Log
import androidx.annotation.RequiresApi
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import java.io.*
import java.lang.Exception
import kotlin.math.roundToInt

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    val TAG = "GeofenceBroadcast"

    override fun onReceive(context: Context, intent: Intent) {
        // This method is called when the BroadcastReceiver is receiving an Intent broadcast.
        Log.d(TAG, "onReceive: Geofence triggered.")
        val geofencingEvent:GeofencingEvent = GeofencingEvent.fromIntent(intent)
        if(geofencingEvent.hasError())
        {
            Log.d(TAG, "onReceive: Error receiving geofence event...")
            return
        }
        val pendingResult:PendingResult = goAsync()
        Task(pendingResult, intent, context).execute(geofencingEvent)

    }

    class Task(var pendingResult: PendingResult, var intent: Intent, var context: Context)
        : AsyncTask<GeofencingEvent, Void, Void>() {

        val TAG = "flutterBackground"

        override fun onPostExecute(result: Void?) {
            super.onPostExecute(result)
            pendingResult.finish()
        }

        override fun doInBackground(vararg p0: GeofencingEvent?): Void? {
            try {
                val notificationHelper = NotificationHelper(context)
                val markerPath = context.filesDir.path + "/../app_flutter"
                val markerFile = File(markerPath + "/marker_storage.json")
                val markerMap = HashMap<String, ArrayList<Action>>()
                val transition = p0[0]?.geofenceTransition
//                Log.i(TAG, transition.toString())
//                Log.i(TAG, markerFile.readText()) // Log to be erased later
                for(geofence:Geofence in p0[0]?.triggeringGeofences!!)
                {
                    val geo:Geofence = geofence
                    markerMap[geo.requestId] = ArrayList()
                }
                val targetStream: InputStream = FileInputStream(markerFile)
                val reader = JsonReader(InputStreamReader(targetStream, "UTF-8"))
                reader.beginObject()
                while (reader.hasNext()) {
                    val name = reader.nextName()
                    if (name in markerMap.keys) {
                        reader.beginObject()
                        while (reader.hasNext()) {
                            val name2 = reader.nextName()
                            when (name2) {
                                "actions" -> {
                                    reader.beginArray()
                                    while (reader.hasNext()) {
                                        val action = Action()
                                        reader.beginObject()
                                        while (reader.hasNext()) {
                                            val name3 = reader.nextName()
                                            when (name3) {
                                                "Action_Name" -> {
                                                    action.name = reader.nextString()
                                                }
                                                "action_detail" -> {
                                                    val params = reader.nextString()
                                                    val paramsStream: InputStream = ByteArrayInputStream(params.toByteArray(Charsets.UTF_8))
                                                    val paramReader = JsonReader(InputStreamReader(paramsStream, "UTF-8"))
                                                    paramReader.beginObject()
                                                    while (paramReader.hasNext()) {
                                                        val paramName = paramReader.nextName()
                                                        when (paramName) {
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
                                                            "param6" -> {
                                                                action.params[5] = paramReader.nextString()
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
                                        markerMap[name]?.add(action)
                                    }
                                    reader.endArray()
                                }
                                else -> {
                                    reader.skipValue()
                                }
                            }
                        }
                        reader.endObject()
                    }
                    else{
                        reader.skipValue()
                    }
                }
                reader.endObject()
                targetStream.close()
                for(marker:String in markerMap.keys)
                {
                    Log.i(TAG, "$marker's list of actions:")
                    for(action:Action in markerMap[marker]!!)
                    {
                        Log.i(TAG, action.name)
                        when(action.name)
                        {
                            "notification" ->
                            {
                                if(((action.params[2] == "false"||  action.params[2] == "") && transition == 4) ||
                                        (action.params[2] == "true" && transition == 2)) {
                                    notificationHelper.sendHighPriorityNotification(action.params[0],
                                            action.params[1], MainActivity::class.java)
                                    Log.i(TAG, "Flatmapp called notification action. Title: " +
                                            "${action.params[0]}, body: ${action.params[1]}")
                                }
                            }
//                            "sound" ->
//                            {
//                                Log.i(TAG, "called mute action")
//                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
//                                    if(action.params[0] == "true")
//                                        try{
//                                            setAlarmVolume(action.params[1].toDouble())
//                                        }catch(e:Exception) {
//                                         Log.i(TAG, e.toString())
//                                        }
//                                    if(action.params[2] == "true")
//                                        try{
//                                        setRingVolume(action.params[3].toDouble())
//                                        }catch(e:Exception) {
//                                            Log.i(TAG, e.toString())
//                                        }
//                                    if(action.params[4] == "true")
//                                        try{
//                                        setMusicVolume(action.params[5].toDouble())
//                                        }catch(e:Exception) {
//                                            Log.i(TAG, e.toString())
//                                        }
//                                }
//                            }
                            "wi-fi" ->
                            {
                                Log.i(TAG, "Flatmapp called wifi action")
                                if(((action.params[1] == "false"||  action.params[1] == "") && transition == 4) ||
                                        (action.params[1] == "true" && transition == 2)) {
                                    if (action.params[0] != "") {
                                        when (action.params[0]) {
                                            "false" -> {
                                                disableWIFI()
                                            }
                                            "true" -> {
                                                enableWIFI()
                                            }
                                            else -> {
                                                enableWIFI()
                                            }
                                        }
                                    }
                                }
                            }
                            "bluetooth" ->
                            {
                                Log.i(TAG, "Flatmapp called bluetooth action")
                                if(((action.params[1] == "false"||  action.params[1] == "") && transition == 4) ||
                                        (action.params[1] == "true" && transition == 2)) {
                                    if (action.params[0] != "") {
                                        when (action.params[0]) {
                                            "false" -> {
                                                disableBluetooth()
                                            }
                                            "true" -> {
                                                enableBluetooth()
                                            }
                                            else -> {
                                                enableBluetooth()
                                            }
                                        }
                                    }
                                }
                            }
                            "mute" ->
                            {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                                    if(((action.params[0] == "false"||  action.params[0] == "") && transition == 4) ||
                                            (action.params[0] == "true" && transition == 2))
                                        mutePhone()
                                    Log.i(TAG, "Flatmapp called mute phone action")
                                }
                            }
                            "unmute" ->
                            {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                                    if(((action.params[0] == "false"||  action.params[0] == "") && transition == 4) ||
                                            (action.params[0] == "true" && transition == 2))
                                    unmutePhone()
                                    Log.i(TAG, "Flatmapp called unmute phone action")
                                }
                            }
                            "change alarm volume" ->
                            {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                                    try{
                                        if(((action.params[1] == "false"||  action.params[1] == "") && transition == 4) ||
                                                (action.params[1] == "true" && transition == 2))
                                        setAlarmVolume(action.params[0].toDouble())
                                        Log.i(TAG, "Flatmapp called change alarm volume" +
                                                " action")
                                    }catch(e:Exception) {
                                        Log.i(TAG, e.toString())
                                    }
                                }
                            }
                            "change ringtone volume" ->
                            {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                                    try{
                                        if(((action.params[1] == "false"||  action.params[1] == "") && transition == 4) ||
                                                (action.params[1] == "true" && transition == 2))
                                        setRingVolume(action.params[0].toDouble())
                                        Log.i(TAG, "Flatmapp called change ringtone volume " +
                                                "action")
                                    }catch(e:Exception) {
                                        Log.i(TAG, e.toString())
                                    }
                                }
                            }
                            "change multimedia volume" ->
                            {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                                    try{
                                        if(((action.params[1] == "false"||  action.params[1] == "") && transition == 4) ||
                                                (action.params[1] == "true" && transition == 2))
                                        setMusicVolume(action.params[0].toDouble())
                                        Log.i(TAG, "Flatmapp called change multimedia volume" +
                                                " action")
                                    }catch(e:Exception) {
                                        Log.i(TAG, e.toString())
                                    }
                                }
                            }
                            "single sound" ->
                            {
                                try{
                                    if(((action.params[0] == "false"||  action.params[0] == "") && transition == 4) ||
                                            (action.params[0] == "true" && transition == 2))
                                    playSound()
                                    Log.i(TAG, "Flatmapp called play single sound" +
                                            " action")
                                }catch(e:Exception) {
                                    Log.i(TAG, e.toString())
                                }

                            }
                            else ->
                            {
                                Log.i(TAG, "FlatMapp called not implemented action ${action.name}")
                            }
                        }
                    }
                }
            }catch(e:Exception)
            {
                e.printStackTrace()
            }
            return null
        }


        @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        private fun mutePhone()
        {
            try{
                val audioManager: AudioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
            }catch(e:SecurityException){
                Log.i(TAG, e.toString())
            }
        }

        @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        private fun unmutePhone()
        {
            try{
                val audioManager: AudioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
            }catch(e:SecurityException){
                Log.i(TAG, e.toString())
            }
        }


        @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        private fun setRingVolume(volume:Double)
        {
            try{
                val audioManager: AudioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_RING)
                val vol = volume / 100.0 * maxVolume.toDouble()
                        audioManager.setStreamVolume(AudioManager.STREAM_RING, vol.roundToInt(), 0)
            }catch(e:SecurityException){
                Log.i(TAG, e.toString())
            }
        }

        @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        private fun setAlarmVolume(volume:Double)
        {
            try{
                val audioManager: AudioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                val vol = volume / 100.0 * maxVolume.toDouble()
                audioManager.setStreamVolume(AudioManager.STREAM_ALARM, vol.roundToInt(), 0)
            }catch(e:SecurityException){
                Log.i(TAG, e.toString())
            }
        }

        @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
        private fun setMusicVolume(volume:Double)
        {
            try{
                val audioManager: AudioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                val vol = volume / 100.0 * maxVolume.toDouble()
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, vol.roundToInt(), 0)
            }catch(e:SecurityException){
                Log.i(TAG, e.toString())
            }
        }

        private fun enableWIFI()
        {
            try {
                val wifiManager: WifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                wifiManager.isWifiEnabled = true
            }catch (e:Exception)
            {
                Log.i(TAG, e.toString())
            }
        }


        private fun disableWIFI()
        {
            try{
                val wifiManager: WifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                wifiManager.isWifiEnabled = false
            }catch (e:Exception)
            {
                Log.i(TAG, e.toString())
            }
        }

        private fun enableBluetooth()
        {
            try {
                val bluetoothAdapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                if (!bluetoothAdapter.isEnabled)
                    bluetoothAdapter.enable()
            }catch (e:Exception)
            {
                Log.i(TAG, e.toString())
            }
        }

        private fun disableBluetooth()
        {
            try{
                val bluetoothAdapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                if(bluetoothAdapter.isEnabled)
                    bluetoothAdapter.disable()
            }catch (e:Exception)
            {
                Log.i(TAG, e.toString())
            }
        }

        private fun playSound()
        {
            try{
                MediaPlayer.create(context, R.raw.notification)?.start()
            }catch (e:Exception)
            {
                Log.i(TAG, e.toString())
            }
        }
    }

}
