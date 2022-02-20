import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key,}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Completer<GoogleMapController> _controller = Completer();
  LocationData? _currentPosition;
  LatLng? _latLong;
  bool _locating = false;
  geocoding.Placemark? _placeMark;



  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    _getUserLocation();
    super.initState();
  }

  Future<LocationData>_getLocationPermission()async{
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return Future.error('Service not enabled');
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return Future.error('Permission Denied');
      }
    }

    _locationData = await location.getLocation();
    return _locationData;
  }

  _getUserLocation()async{
    _currentPosition = await _getLocationPermission();
    _goToCurrentPosition(LatLng(_currentPosition!.latitude!,_currentPosition!.longitude!));
  }

  getUserAddress()async{
    List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(_latLong!.latitude, _latLong!.longitude);
    setState(() {
      _placeMark = placemarks.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height *.75,
                  decoration: const BoxDecoration(
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey)
                    )
                  ),
                  child: Stack(
                    children: [
                      GoogleMap(
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.terrain,
                        initialCameraPosition: _kGooglePlex,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        onCameraMove: (CameraPosition position){
                          setState(() {
                            _locating = true;
                            _latLong = position.target;
                          });
                        },
                        onCameraIdle: (){
                          setState(() {
                            _locating = false;
                          });
                          getUserAddress();
                        },
                      ),
                      Align(
                          alignment: Alignment.center,
                          child: Icon(Icons.location_on,size: 40,)),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [

                  Column(
                    children: [
                      _placeMark!=null ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_locating ?'Locating...': _placeMark!.locality==null ? _placeMark!.subLocality! : _placeMark!.locality!,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                            SizedBox(height: 8,),
                            Row(
                              children: [
                                Text(_placeMark!.subLocality!, ),
                                Text(_placeMark!.subAdministrativeArea!=null ? '${_placeMark!.subAdministrativeArea!}, ' : ''),
                              ],
                            ),
                          Text('${_placeMark!.administrativeArea!}, ${_placeMark!.country!}, ${_placeMark!.postalCode!}')
                        ],
                      ) : Container(),
                      SizedBox(height: 10,),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (){
                                print(_placeMark!.toJson());
                              },
                              child: Text('Confirm Location'),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _goToCurrentPosition(LatLng latlng) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            bearing: 192.8334901395799,
            target: LatLng(latlng.latitude, latlng.longitude),
            //tilt: 59.440717697143555,
            zoom: 14.4746)
    ));
  }
}