import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/Presentation/BookRide/Screens/confirm_booking.dart';
import 'package:hopper/Presentation/BookRide/Screens/search_screen.dart';

import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:hopper/driver_detail_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookMapScreen extends StatefulWidget {
  final Map<String, dynamic> pickupData;
  final Map<String, dynamic> destinationData;
  final String pickupAddress;
  final String destinationAddress;
  const BookMapScreen({
    super.key,
    required this.pickupData,
    required this.destinationData,
    required this.pickupAddress,
    required this.destinationAddress,
  });

  @override
  State<BookMapScreen> createState() => _BookMapScreenState();
}

class _BookMapScreenState extends State<BookMapScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  DriverSearchController driverController = Get.put(DriverSearchController());
  LatLng? _pickupPosition;
  LatLng? _destinationPosition;
  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;
  bool isSendSelected = true;
  String? _selectedCarType;

  @override
  void initState() {
    super.initState();

    _pickupPosition = LatLng(
      widget.pickupData['lat'],
      widget.pickupData['lng'],
    );

    _destinationPosition = LatLng(
      widget.destinationData['lat'],
      widget.destinationData['lng'],
    );

    driverController.getDriverSearch(
      pickupLat: _pickupPosition!.latitude,
      pickupLng: _pickupPosition!.longitude,
      dropLat: _destinationPosition!.latitude,
      dropLng: _destinationPosition!.longitude,
    );

    _drawPolyline();
  }

  void _fitBounds() {
    if (_pickupPosition == null ||
        _destinationPosition == null ||
        _mapController == null)
      return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _pickupPosition!.latitude < _destinationPosition!.latitude
            ? _pickupPosition!.latitude
            : _destinationPosition!.latitude,
        _pickupPosition!.longitude < _destinationPosition!.longitude
            ? _pickupPosition!.longitude
            : _destinationPosition!.longitude,
      ),
      northeast: LatLng(
        _pickupPosition!.latitude > _destinationPosition!.latitude
            ? _pickupPosition!.latitude
            : _destinationPosition!.latitude,
        _pickupPosition!.longitude > _destinationPosition!.longitude
            ? _pickupPosition!.longitude
            : _destinationPosition!.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60), // padding 60
    );
  }

  Future<void> _drawPolyline() async {
    final String apiKey =
        'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic'; // Replace with yours
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_pickupPosition!.latitude},${_pickupPosition!.longitude}&destination=${_destinationPosition!.latitude},${_destinationPosition!.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final encoded = data['routes'][0]['overview_polyline']['points'];
      final points = _decodePolyline(encoded);

      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId("route"),
            points: points,
            color: AppColors.commonBlack,
            width: 3,
          ),
        };
      });
    } else {
      print("Error fetching directions: ${data['status']}");
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

  void _goToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(position.latitude, position.longitude);

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
  }

  @override
  Widget build(BuildContext context) {
    _startController.text = widget.pickupAddress;
    _destController.text = widget.destinationAddress;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              expandedHeight: 300,
              automaticallyImplyLeading: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    GoogleMap(
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      initialCameraPosition: CameraPosition(
                        target: _pickupPosition ?? LatLng(0, 0),
                        zoom: 14,
                      ),
                      onMapCreated: (controller) async {
                        _mapController = controller;
                        _fitBounds();

                        String style = await DefaultAssetBundle.of(
                          context,
                        ).loadString('assets/map_style/map_style.json');
                        _mapController!.setMapStyle(style);
                      },

                      polylines: _polylines,

                      // markers: {
                      //   if (_pickupPosition != null)
                      //     Marker(
                      //       markerId: MarkerId("pickup"),
                      //       position: _pickupPosition!,
                      //       icon: BitmapDescriptor.defaultMarkerWithHue(
                      //         BitmapDescriptor.hueGreen,
                      //       ),
                      //     ),
                      //   if (_destinationPosition != null)
                      //     Marker(
                      //       markerId: MarkerId("destination"),
                      //       position: _destinationPosition!,
                      //       icon: BitmapDescriptor.defaultMarkerWithHue(
                      //         BitmapDescriptor.hueRed,
                      //       ),
                      //     ),
                      // },
                    ),
                    Positioned(
                      top: 270,
                      right: 10,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _goToCurrentLocation,
                        child: Icon(
                          Icons.my_location,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back_ios_new, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Search',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.favorite_border),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CustomTextFields.plainTextField(
                            Style: TextStyle(
                              fontSize: 12,
                              color: AppColors.commonBlack.withOpacity(0.6),
                              overflow: TextOverflow.ellipsis,
                            ),
                            readOnly: true,
                            onTap: () async {
                              final selected = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BookRideSearchScreen(
                                        isPickup: true,
                                        pickupData: {
                                          'description': _startController.text,
                                          'lat': _pickupPosition?.latitude,
                                          'lng': _pickupPosition?.longitude,
                                        },
                                        destinationData: {
                                          'description': _destController.text,
                                          'lat': _destinationPosition?.latitude,
                                          'lng':
                                              _destinationPosition?.longitude,
                                        },
                                      ),
                                ),
                              );
                              if (selected != null) {
                                setState(() {
                                  _startController.text =
                                      selected['description'];
                                  _pickupPosition = LatLng(
                                    selected['lat'],
                                    selected['lng'],
                                  );
                                  _drawPolyline();
                                  _fitBounds();
                                });
                              }
                            },
                            hintStyle: TextStyle(fontSize: 11),
                            imgHeight: 20,
                            controller: _startController,

                            containerColor: AppColors.commonWhite,
                            leadingImage: AppImages.dart,
                            title: 'Search for an address or landmark',
                          ),
                          const Divider(
                            height: 0,
                            color: AppColors.containerColor,
                          ),
                          CustomTextFields.plainTextField(
                            Style: TextStyle(
                              fontSize: 12,
                              color: AppColors.commonBlack.withOpacity(0.6),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              final selected = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BookRideSearchScreen(
                                        isPickup: false,
                                        pickupData: {
                                          'description': _startController.text,
                                          'lat': _pickupPosition?.latitude,
                                          'lng': _pickupPosition?.longitude,
                                        },
                                        destinationData: {
                                          'description': _destController.text,
                                          'lat': _destinationPosition?.latitude,
                                          'lng':
                                              _destinationPosition?.longitude,
                                        },
                                      ),
                                ),
                              );
                              if (selected != null) {
                                setState(() {
                                  _destController.text =
                                      selected['description'];
                                  _destinationPosition = LatLng(
                                    selected['lat'],
                                    selected['lng'],
                                  );
                                  _drawPolyline();
                                  _fitBounds();
                                });
                              }
                            },
                            controller: _destController,

                            hintStyle: TextStyle(fontSize: 11),
                            imgHeight: 20,
                            containerColor: AppColors.commonWhite,
                            leadingImage: AppImages.dart,
                            title: 'Enter destination',
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    PackageContainer.bookContainers(
                      isSendSelected: isSendSelected,
                      onSelectionChanged: (selected) {
                        setState(() {
                          isSendSelected = selected;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    Obx(() {
                      if (driverController.serviceType.isEmpty) {
                        return AppLoader.circularLoader(); // show loader while fetching
                      }
                      if (driverController.serviceType.isEmpty) {
                        return Center(
                          child: Text(
                            'No drivers in your location',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      final luxuryDriver = driverController.serviceType
                          .firstWhereOrNull(
                            (e) =>
                                e.driverId.carType?.toLowerCase() == 'luxury',
                          );

                      final sedanDriver = driverController.serviceType
                          .firstWhereOrNull(
                            (e) => e.driverId.carType?.toLowerCase() == 'sedan',
                          );

                      if (luxuryDriver == null && sedanDriver == null) {
                        return Center(
                          child: Text(
                            'Car not found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          if (luxuryDriver != null)
                            PackageContainer.bookCarTypeContainer(
                              borderColor:
                                  _selectedCarType == 'Luxury'
                                      ? AppColors.commonBlack
                                      : AppColors.containerColor,
                              carImg: AppImages.luxuryCar,
                              onTap: () {
                                setState(() {
                                  _selectedCarType = 'Luxury';
                                });
                              },
                              carTitle: 'Luxury',
                              carMinRate:
                                  luxuryDriver.estimatedPrice.toString(),
                              carMaxRate:
                                  (luxuryDriver.estimatedPrice + 30).toString(),

                              carSubTitle: 'Comfy, Economical Cars',
                              arrivingTime:
                                  '${luxuryDriver.estimatedTime ?? 0} min',
                            ),
                          const SizedBox(height: 20),
                          if (sedanDriver != null)
                            PackageContainer.bookCarTypeContainer(
                              borderColor:
                                  _selectedCarType == 'Sedan'
                                      ? AppColors.commonBlack
                                      : AppColors.containerColor,
                              carImg: AppImages.sedan,
                              onTap: () {
                                setState(() {
                                  _selectedCarType = 'Sedan';
                                });
                              },
                              carTitle: 'Sedan',
                              carMinRate: sedanDriver.estimatedPrice.toString(),

                              carMaxRate:
                                  (sedanDriver.estimatedPrice + 32).toString(),
                              carSubTitle: 'Comfy, Economical Cars',
                              arrivingTime:
                                  '${sedanDriver.estimatedTime ?? 0} min',
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: AppButtons.button(
          buttonColor:
              _selectedCarType == null
                  ? AppColors.containerColor
                  : AppColors.commonBlack,
          textColor: Colors.white,
          onTap: () async {
            if (_selectedCarType == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a car to proceed.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            String? result = await driverController.createBookingCar(
              fromLatitude: _pickupPosition?.latitude ?? 0.0,
              fromLongitude: _pickupPosition?.longitude ?? 0.0,
              toLatitude: _destinationPosition?.latitude ?? 0.0,
              toLongitude: _destinationPosition?.longitude ?? 0.0,
              customerId: '', // <-- Replace with actual ID
              context: context,
            );

            print("Booking: $_selectedCarType");

            if (result != null)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ConfirmBooking(
                        selectedCarType: _selectedCarType!,
                        pickupData: widget.pickupData,
                        destinationData: widget.destinationData,
                        pickupAddress: widget.pickupAddress,
                        destinationAddress: widget.destinationAddress,
                      ),
                ),
              );
          },
          text: _selectedCarType == null ? 'Book' : 'Book $_selectedCarType',
        ),
      ),
    );
  }
}
