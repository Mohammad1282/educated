import 'dart:async';
import 'dart:collection';
import 'package:educatednearby/constant/constant_colors.dart';
import 'package:educatednearby/fun/goto.dart';
import 'package:educatednearby/screens/singleservice.dart';
import 'package:educatednearby/view_model/store_view.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  final int id;
  final int distances;

  MapScreen({Key key, this.id, this.distances});

  @override
  _MapScreenState createState() => _MapScreenState(this.id);
}

class _MapScreenState extends State<MapScreen> {
  int id;
  _MapScreenState(this.id);

  CameraPosition _initialCamera;
  GoogleMapController _googleMapController;
  Marker marker;
  Circle circle;
  double lat, long;
  double distance;
  var currentLocation;
  // Location _locationTracker = Location();
  StreamSubscription<Position> ps;
  BitmapDescriptor pinLocationIcon;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  var myMarkers = HashSet<Marker>();

  Future<void> getLatLag() async {
    currentLocation =
        await Geolocator.getCurrentPosition().then((value) => value);
    lat = currentLocation.latitude;
    long = currentLocation.longitude;
    _initialCamera = CameraPosition(
      target: LatLng(lat, long),
      zoom: 14.4746,
    );
    myMarkers.add(Marker(
        markerId: const MarkerId("Mylocation"),
        position: LatLng(lat, long),
        icon: pinLocationIcon));
    setState(() {});
  }

  Set<Marker> myMarker = {};

  void setCustomMapPin() async {
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/person.png');
  }

  @override
  void dispose() {
    super.dispose();
    if (ps != null && myMarkers != null) {
      ps.cancel();
      myMarkers.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    getLatLag();
    setCustomMapPin();
  }

  @override
  Widget build(BuildContext context) {
    StoreViewModel storeViewModel = context.watch<StoreViewModel>();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: yellow,
        centerTitle: false,
        title: const Text('Maps'),
      ),
      body: _initialCamera == null
          ? const CircularProgressIndicator()
          : GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: (GoogleMapController googleMap) {
                _googleMapController = googleMap;
                setState(() {
                  _setMakers(storeViewModel);
                });
              },
              markers: myMarkers,
              circles: Set.of((circle != null) ? [circle] : []),
            ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     getCurrentLocation();
      //   },
      //   child: const Icon(Icons.location_searching),
      // ),
    );
  }

  _setMakers(StoreViewModel storeViewModel) async {
    await storeViewModel.getStore(id);
    if (storeViewModel.loading) {
      print("HIIII");
    }

    if (storeViewModel.store.isEmpty) {
    } else {
      setState(() {
        // _markers.clear();
        for (final store in storeViewModel.store) {
          // print(store.nameEn + "Hqqqqqq");
          distance = Geolocator.distanceBetween(
              lat, long, store.latitude, store.longitude);
          int indistance = distance.round().toInt();
          double distanceInKilo = indistance / 1000;

          if (distanceInKilo <= widget.distances) {
            myMarkers.add(Marker(
                markerId: MarkerId(store.nameEn),
                position: LatLng(store.latitude, store.longitude),
                infoWindow: InfoWindow(
                    title: store.nameEn,
                    snippet: store.descEn,
                    onTap: () async {
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                              store.latitude, store.longitude);
                      String street = placemarks[0].street;
                      funtions.push(
                          context,
                          SingleServiceScreen(
                            logo: store.logo,
                            nameEn: store.nameEn,
                            email: store.email,
                            phone: store.phone,
                            descEn: store.descEn,
                            descAr: store.descAr,
                            lat: store.latitude,
                            long: store.longitude,
                            street: street.toString(),
                          ));
                    })));
          } else {
            print('NOPEEEEEEE');
          }

          // print("HIIIII"+myMarkers.toString());
          // print("ALOOOOOOO"+lat.toString() + " " + long.toString() + ' Store' + ' ' + store.latitude.toString());

          // print("distance" + (indistance / 1000).toString());

        }
      });
    }
  }

  Widget getBottomSheet(String name, String mail, String description,
      double lat, double long, String phone, String street) {
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 32),
          color: Colors.white,
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.blueAccent,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: const <Widget>[
                          Text("4.5",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          Icon(
                            Icons.star,
                            color: Colors.yellow,
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Text("970 Folowers",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14))
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(description,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 20,
                  ),
                  const Icon(
                    Icons.map,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  street != null
                      ? Text(street)
                      : Text(lat.toString() + ',' + long.toString())
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () {
                  launch("tel:+96207" + phone);
                },
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 20,
                    ),
                    const Icon(
                      Icons.call,
                      color: Colors.blue,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text(phone)
                  ],
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.topRight,
            child: FloatingActionButton(
                child: const Icon(Icons.navigation),
                onPressed: () {
                  navigateTo(lat, long);
                }),
          ),
        )
      ],
    );
  }

  static void navigateTo(double lat, double lng) async {
    var uri = Uri.parse("https://maps.google.com/?q=$lat,$lng&mode=d");
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch ${uri.toString()}';
    }
  }

  // void getCurrentLocation() async {
  //   try {
  //     Uint8List imageData = await getMarker();
  //     var location = await _locationTracker.getLocation();

  //     updateMarkerAndCircle(location, imageData);

  //     if (_locationSubscription != null) {
  //       _locationSubscription.cancel();
  //     }

  //     _locationSubscription =
  //         _locationTracker.onLocationChanged.listen((newLocalData) {
  //       if (_googleMapController != null) {
  //         _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
  //             CameraPosition(
  //                 bearing: 192.8334901395799,
  //                 target: LatLng(newLocalData.latitude, newLocalData.longitude),
  //                 tilt: 0,
  //                 zoom: 18.00)));
  //         updateMarkerAndCircle(newLocalData, imageData);
  //       }
  //     });
  //   } on PlatformException catch (e) {
  //     if (e.code == 'PERMISSON_DENIED') {
  //       debugPrint("Perm deni");
  //     }
  //   }
  // }

  // Future<Uint8List> getMarker() async {
  //   ByteData byteData =
  //       await DefaultAssetBundle.of(context).load("assets/images/car_icon.png");
  //   return byteData.buffer.asUint8List();
  // }

  // void updateMarkerAndCircle(LocationData newLocalDat, Uint8List imageData) {
  //   LatLng latLng = LatLng(newLocalDat.latitude, newLocalDat.longitude);
  //   setState(() {
  //     marker = Marker(
  //         markerId: const MarkerId("home"),
  //         position: latLng,
  //         rotation: newLocalDat.heading,
  //         draggable: false,
  //         zIndex: 2,
  //         flat: true,
  //         anchor: const Offset(0.5, 0.5),
  //         icon: BitmapDescriptor.fromBytes(imageData));
  //     circle = Circle(
  //         circleId: const CircleId("car"),
  //         radius: 100,
  //         zIndex: 1,
  //         strokeColor: blue,
  //         center: latLng,
  //         fillColor: Colors.blue[50]);
  //   });
  // }

  // void _onMapCreated(GoogleMapController controller) async {
  //   this._googleMapController = controller;
  //   // _setMakers;
  // }
}
