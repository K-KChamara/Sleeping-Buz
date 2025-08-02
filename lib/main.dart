import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/services.dart';
import 'widgets/location_search_field.dart';


double? _distanceToStop;

void main() => runApp(SleepingBuzzApp());

class SleepingBuzzApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleeping Buz',
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = LatLng(6.9271, 79.8612); // Colombo
  LatLng? _destination;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _startTracking();
  }

  void _onTap(LatLng location) {
    setState(() {
      _destination = location;
      _markers = {
        Marker(
          markerId: MarkerId('bus_stop'),
          position: location,
          infoWindow: InfoWindow(title: 'Your Stop'),
        ),
      };
    });
  }

  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permissions are denied');
      return;
    }

    _positionStream = Geolocator.getPositionStream().listen((Position position) {
      if (_destination != null) {
        double distance = _calculateDistance(
          position.latitude,
          position.longitude,
          _destination!.latitude,
          _destination!.longitude,
        );
        if(distance > 1000){
          print('Distance to stop: ${(distance/1000).toStringAsFixed(2)} Kilometers');
        }
        print('Distance to stop: ${distance.toStringAsFixed(2)} meters');

        setState(() {
          _distanceToStop = distance;
        });

        if (distance < 100) {
          _triggerAlarm();
        }
      }
    });
  }

void _triggerAlarm() async {
  print('Buzz! You are near your stop!');
  
  // Stop location updates to prevent repeat triggering
  _positionStream?.cancel();

  // 1. Vibrate (short pulse)
  HapticFeedback.heavyImpact();

  // 2. Play Ringtone

  // 3. Show full-screen "Wake up" overlay
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm, color: Colors.redAccent, size: 100),
              SizedBox(height: 20),
              Text(
                "Wake up!\nYour stop is just ahead",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                },
                icon: Icon(Icons.check),
                label: Text("I'm Awake"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[700],
                  foregroundColor: Colors.black,
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}


  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * 1000 * asin(sqrt(a)); // in meters
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Sleeping Buz')),
    body: Stack(
      children: [
        LocationSearchField(
          onPlaceSelected: (place) {
            print("User selected: $place");
          },
        ),
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: 14.0,
          ),
          onTap: _onTap,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        if (_distanceToStop != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
             '📍 You are ${_distanceToStop! > 1000 ? (_distanceToStop! / 1000).toStringAsFixed(2) + ' km' : _distanceToStop!.toStringAsFixed(2) + ' meters'} from your stop',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    ),
  );
}

}