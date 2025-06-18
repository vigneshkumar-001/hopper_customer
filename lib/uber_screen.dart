import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:hopper/driver_detail_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:hopper/Core/Utility/app_images.dart';

class UberStyleMapScreen extends StatefulWidget {
  @override
  _UberStyleMapScreenState createState() => _UberStyleMapScreenState();
}

class _UberStyleMapScreenState extends State<UberStyleMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final driverController = Get.put(DriverController());

  LatLng? _destinationPosition;
  BitmapDescriptor? _carIcon, _startIcon, _endIcon;
  Marker? _carMarker;
  final _searchController = TextEditingController();
  late GooglePlace googlePlace;
  Timer? _carTimer;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initGooglePlace();
    _loadCustomMarkers();
    _getCurrentLocation();
  }

  void _initGooglePlace() {
    const String apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    googlePlace = GooglePlace(apiKey);
  }

  Future<void> _loadCustomMarkers() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      AppImages.avoidDrinks,
    );
    _startIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      AppImages.pencilBike,
    );
    _endIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      AppImages.location,
      height: 30,
      width: 30,
    );
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
      setState(() {});
    }
  }

  Future<void> _getDirectionsPolyline(LatLng origin, LatLng destination) async {
    final String apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final route = data['routes'][0];
      final points = route['overview_polyline']['points'];
      final List<LatLng> polylinePoints = _decodePolyline(points);

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.black,
            width: 5,

            points: polylinePoints,
          ),
        );
      });
    } else {
      print("Failed to load directions: ${response.body}");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _onPlaceSelected(AutocompletePrediction prediction) async {
    print("Selected place: ${prediction.description}");

    final details = await googlePlace.details.get(prediction.placeId!);
    if (details == null) {
      print("Failed to get place details");
      return;
    }

    final loc = details.result?.geometry?.location;
    if (loc != null) {
      final newDestination = LatLng(loc.lat!, loc.lng!);

      // Always update destination and move camera even if same location
      setState(() {
        _destinationPosition = newDestination;
        _carMarker = null; // Reset car marker if needed
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newDestination, 17),
      );
      if (_currentPosition != null && _destinationPosition != null) {
        await _getDirectionsPolyline(_currentPosition!, _destinationPosition!);
      }
    } else {
      print("No location found in place details");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void dispose() {
    _carTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null ||
        _carIcon == null ||
        _startIcon == null ||
        _endIcon == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Set<Marker> markers = {};

    if (_destinationPosition == null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: _startIcon!,
        ),
      );
    } else {
      markers.addAll([
        Marker(
          markerId: const MarkerId('start'),
          position: _currentPosition!,
          icon: _startIcon!,
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: _destinationPosition!,
          icon: _endIcon!,
        ),
      ]);

      if (_carMarker != null) {
        markers.add(_carMarker!);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 17,
            ),
            markers: markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Autocomplete<AutocompletePrediction>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty)
                    return const Iterable<AutocompletePrediction>.empty();

                  final result = await googlePlace.autocomplete.get(
                    textEditingValue.text,
                    location:
                        _currentPosition == null
                            ? null
                            : LatLon(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                    radius: 50000,
                    strictbounds: true,
                  );

                  if (result == null || result.predictions == null) {
                    return const Iterable<AutocompletePrediction>.empty();
                  }

                  return result.predictions!;
                },

                displayStringForOption:
                    (AutocompletePrediction option) => option.description!,
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onEditingComplete,
                ) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search destination',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          _searchController.clear();
                          setState(() {
                            _polylines.clear();
                            _destinationPosition = null;
                          });
                        },
                      ),
                    ),
                  );
                },

                onSelected: _onPlaceSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
