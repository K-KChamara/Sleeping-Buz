import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/services.dart';
import 'widgets/location_search_field.dart';

double? _distanceToStop;
bool _showFooter = false;
bool _alarmEnabled = true;
String? _destinationName;

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

    _positionStream = Geolocator.getPositionStream().listen((
      Position position,
    ) {
      if (_destination != null) {
        double distance = _calculateDistance(
          position.latitude,
          position.longitude,
          _destination!.latitude,
          _destination!.longitude,
        );
        if (distance > 1000) {
          print(
            'Distance to stop: ${(distance / 1000).toStringAsFixed(2)} Kilometers',
          );
        }
        print('Distance to stop: ${distance.toStringAsFixed(2)} meters');

        setState(() {
          _distanceToStop = distance;
        });

        if (distance < 500 && _alarmEnabled) {
          _triggerAlarm();
        }
      }
    });
  }

  void _triggerAlarm() async {


    print('Buzz! You are near your stop!');
    _positionStream?.cancel(); // Stop tracking

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
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
                    Navigator.of(context).pop();
                      _alarmEnabled = false;
                  },
                  icon: Icon(Icons.accessibility_new_rounded),
                  label: Text("I'm Awake"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[700],
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
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
      appBar: AppBar(
        title: Text('Sleeping Buz'),
        backgroundColor: const Color.fromARGB(221, 255, 255, 255),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Restart Tracking',
            onPressed: () {
              // Restart location tracking
              _positionStream?.cancel(); // Stop current stream
              _startTracking(); // Start new one
              setState(() {
                _distanceToStop = null;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🗺️ Google Map (do NOT wrap with Expanded inside Stack)
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            onTap: (LatLng position) {
              setState(() {
                _destination = position;
                _destinationName = null; // Clear name if using manual tap
                _showFooter = true;
                _markers = {
                  Marker(
                    markerId: MarkerId('destination'),
                    position: position,
                    infoWindow: InfoWindow(title: 'Your Stop'),
                  ),
                };
              });
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // 🔍 Floating Search Bar
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: LocationSearchField(
                onPlaceSelected: (place) {
                  // No longer showing footer on search, just print it or keep for future
                  print("Searched: $place");
                },
              ),
            ),
          ),

          // 📦 Bottom footer appears only if user tapped
          if (_showFooter && _destination != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _destinationName ??
                                'Lat: ${_destination!.latitude.toStringAsFixed(4)}, '
                                    'Lon: ${_destination!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _distanceToStop != null
                              ? '📍 Distance: ${_distanceToStop! > 1000 ? (_distanceToStop! / 1000).toStringAsFixed(2) + ' km' : _distanceToStop!.toStringAsFixed(2) + ' m'}'
                              : 'Calculating...',
                          style: TextStyle(fontSize: 15),
                        ),
                        Row(
                          children: [
                            Text("Alarm"),
                            Switch(
                              value: _alarmEnabled,
                              onChanged: (val) {
                                if(val) _startTracking();
                                setState(() {
                                  _alarmEnabled = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
