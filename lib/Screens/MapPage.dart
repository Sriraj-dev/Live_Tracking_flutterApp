import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:maps_sample/Screens/LoginPage.dart';
import 'package:maps_sample/constants.dart';


class MapScreen extends StatefulWidget {
  User user;
  MapScreen(this.user);
  @override
  _MapScreenState createState() => _MapScreenState(user);
}

class _MapScreenState extends State<MapScreen> {
  User user;
  _MapScreenState(this.user);

  final _auth = FirebaseAuth.instance;
  late GoogleMapController mapController;
  Completer<GoogleMapController> _controller = Completer();
  LocationData? sourceLocation;
  LocationData? currentLocation;
  Map<MarkerId, Marker> markers = {};
  late Location location;
  late StreamSubscription<LocationData> subscription;

  Set<Marker> reqMarkers = Set<Marker>();
  Set<Polyline> reqPolyline = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  String googleApiKey = "AIzaSyC-8N7ESD9Z6kH5l2FjamMqtM0pVJ4uo_8";
  //AIzaSyCbaELHR_jnHhd3FZTaTir38Bkb0Mrwpgo
  String distanceTravelled = '0m';

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    subscription.cancel();
  }
  @override
  void initState() {
    super.initState();

    location = Location();
    polylinePoints = PolylinePoints();

    subscription = location.onLocationChanged.listen((sLocation) {
      currentLocation = sLocation;
      updatePinsOnMap();
    });

    setInitialLocation();
  }

  void setInitialLocation()async{
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        showSnackBar('Location service is disabled!');
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        showSnackBar('Location Permission is required!');
        return;
      }
    }
    await location.getLocation().then((value) {
      sourceLocation = value;
      currentLocation = value;
      setState(() {

      });
    });
  }

  void showLocationPinsOnMap(){
    var sourcePosition = LatLng(sourceLocation!.latitude??0.0, sourceLocation!.longitude??0.0);
    var currentPosition = LatLng(currentLocation!.latitude??0.0, currentLocation!.longitude??0.0);
    print('---------------------------showing pins on map------------------------------');
    reqMarkers.add(
        Marker(
          markerId: MarkerId('sourceLocation'),
          position: sourcePosition,
          infoWindow: InfoWindow(
            title: 'Initial Position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
        ),
    );
    reqMarkers.add(
      Marker(
          markerId: MarkerId('currentPosition'),
          position: currentPosition,
          infoWindow: InfoWindow(
            title: 'CurrentPosition'
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
      ),
    );
    showPolyLineOnMap();
  }

  void showPolyLineOnMap()async{
    print('---------------------------showing polyline on map------------------------------');
    var result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey,
        PointLatLng(sourceLocation!.latitude??0.0, sourceLocation!.longitude??0.0),
        PointLatLng(currentLocation!.latitude??0.0,currentLocation!.longitude??0.0)
    );

    if(result.points.isNotEmpty){
      print('points are not empty--------------');
      result.points.forEach((e){
        polylineCoordinates.add(LatLng(e.latitude, e.longitude));
      });
    }else{
      print('---------------------points are empty------------------------');
    }

    setState(() {
      reqPolyline.add(Polyline(
          polylineId: PolylineId('polyline'),
          points: polylineCoordinates,
          width: 4,
          color: kPrimaryColor
      ));
    });
    print("req poly line are $reqPolyline");
  }

  void updatePinsOnMap()async{
    CameraPosition cameraPosition = CameraPosition(
        target:LatLng(currentLocation!.latitude??0.0,currentLocation!.longitude??0.0),
      zoom: 15
    );
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    var currentPosition = LatLng(currentLocation!.latitude??0.0, currentLocation!.longitude??0.0);
    setState(() {
      reqMarkers.removeWhere((marker) => marker.mapsId.value == 'currentPosition');
      reqMarkers.add(
        Marker(
            markerId: MarkerId('currentPosition'),
            position: currentPosition,
            infoWindow: InfoWindow(
                title: 'CurrentPosition'
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
        ),
      );
      showPolyLineOnMap();
    });

  }
  void showSnackBar(String text) {
    final snackBar = SnackBar(
      backgroundColor: Colors.red,
        content: Text(text),
      padding: EdgeInsets.symmetric(vertical: 15,horizontal: 10),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.symmetric(horizontal: 10,),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context){
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: Text('Live Tracking'),
          centerTitle: true,
          //elevation: ,
          actions: [
            IconButton(
                onPressed: ()async{
                  await _auth.signOut();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>LoginPage()));
                },
                icon: Icon(Icons.logout_rounded))
          ],
        ),
          body: (currentLocation==null || sourceLocation ==null)?
              Center(
                child: CircularProgressIndicator(
                  color: kSecondaryColor,
                ),
              ):Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: LatLng(currentLocation!.latitude??0.0, currentLocation!.longitude??0.0),
                    zoom: 15
                ),
                onMapCreated: (GoogleMapController controller){
                  _controller.complete(controller);
                  print('========================Im running==========================');
                  showLocationPinsOnMap();
                },
                markers: reqMarkers,
                polylines: reqPolyline,
                mapType: MapType.normal,
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  height: 100,
                  width: MediaQuery.of(context).size.width,
                  color: kSecondaryColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Welcome ${user.displayName??"User"}',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: kPrimaryColor
                        ),
                      ),
                      SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Distance Travelled: ',
                            style: GoogleFonts.lato(
                              fontSize: 17,
                              color: kPrimaryColor
                            ),
                          ),
                          Text(distanceTravelled.toString(),
                            style: GoogleFonts.lato(
                              fontSize: 17,
                              color: bgColor
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          )
      ),
    );
  }

  // void _onMapCreated(GoogleMapController controller) async
  // {
  //   print('map created');
  //   mapController = controller;
  // }
}