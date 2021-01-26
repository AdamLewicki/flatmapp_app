package deadsmond.net.flatmapp

//import io.flutter.app.FlutterActivity
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {

  val TAG = "MainActivity"
  var CHANNEL:String = "com.flatmapp.messeges"
  private lateinit var geofencingClient: GeofencingClient
  private lateinit var geofenceHelper: GeofenceHelper
  private var receiver = GeofenceBroadcastReceiver()

  // fix engine crash on app leaving via left arrow
//  override fun onDestroy() {
//    flutterEngine?.platformViewsController?.onFlutterViewDestroyed()
//    super.onDestroy()
//  }

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // TODO
    val notificationManager:NotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
            && !notificationManager.isNotificationPolicyAccessGranted) {
      val intent = Intent(
              Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
      startActivity(intent)
    }
    geofencingClient = LocationServices.getGeofencingClient(this)
    geofenceHelper = GeofenceHelper(this)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
      when(call.method){
        "addMarker" ->
        {
          val marker: String? = call.argument<String>("marker")
          if(marker != null)
          {
           val parameters:List<String> = marker.split(";")
            if(parameters.size == 4)
            {
              addGeofence(parameters[0], parameters[1].toDouble(), parameters[2].toDouble(), parameters[3].toFloat())
            }
          }
        }
        "deleteMarkers" ->
        {
          val markers: String? = call.argument<String>("markers")
          if(markers != null)
          {
            for(ID in markers.split(";"))
            {
              deleteGeofence(ID)
            }
          }
        }
        else -> {
          result.notImplemented()
        }
      }
    }
  }

  private fun addGeofence(ID:String, latitude:Double, longitude:Double, radius:Float){
    val geofence: Geofence = geofenceHelper.getGeofence(ID, latitude, longitude, radius,
            Geofence.GEOFENCE_TRANSITION_DWELL)// or Geofence.GEOFENCE_TRANSITION_EXIT)
    val geofencingRequest: GeofencingRequest = geofenceHelper.getGeofencingRequest(geofence)
    val pendingIntent: PendingIntent = geofenceHelper.getPendingIntent()
    geofencingClient.addGeofences(geofencingRequest, pendingIntent)
            .addOnSuccessListener { Log.d(TAG, "addGeofence onSuccess: Geofence $ID Added...")}
            .addOnFailureListener {
              val errorMassage:String = geofenceHelper.getErrorString(it)
              Log.d(TAG, "addGeofence onFailure: $errorMassage")
            }
  }

  private fun deleteGeofence(ID: String){
    val list:MutableList<String> = MutableList(1){ID}
    try {
      geofencingClient.removeGeofences(list)
              .addOnSuccessListener{Log.d(TAG, "deleteGeofence onSuccess: Geofence $ID Deleted...")}
              .addOnFailureListener{
                Log.d(TAG, "deleteGeofence onFailure: $it")
              }
    }catch (e:Exception)
    {
      Log.d(TAG, "Delete geofence error: $e")
    }
  }



}