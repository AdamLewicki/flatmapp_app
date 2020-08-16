package deadsmond.net.flatmapp.objects

import android.location.Location
import deadsmond.net.flatmapp.objects.Action

class Marker(){
    var id:String = ""
    var position_x:Double = -1.0
    var position_y:Double = -1.0
    var location: Location = Location("Marker's location")
    var range:Double = -1.0
    var actions = ArrayList<Action>()

}