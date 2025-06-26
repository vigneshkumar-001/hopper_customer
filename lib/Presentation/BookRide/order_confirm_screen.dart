import 'package:flutter/foundation.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class OrderConfirmScreen extends StatefulWidget {
  const OrderConfirmScreen({super.key});

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  LatLng? _pickedPosition;
  double? _lastZoom;
  final double _zoomThreshold = 0.01;
  String _address = 'Search...';
  Future<void> _initLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    AppLogger.log.i(_currentPosition);
  }

  Future<void> _getAndSetCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
      _pickedPosition = _currentPosition;
      setState(() {});
    } catch (e) {
      print("Location error: $e");
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _address = "${placemark.street}, ${placemark.locality}";
        });
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  void _goToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(position.latitude, position.longitude);

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
  }

  @override
  void initState() {
    super.initState();

    _initLocation();
    _goToCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 550,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(0, 0),
                zoom: 16,
              ),
              onMapCreated: (controller) async {
                _mapController = controller;
                String style = await DefaultAssetBundle.of(
                  context,
                ).loadString('assets/map_style/map_style1.json');
                _mapController?.setMapStyle(style);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
          Positioned(
            top: 350,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      textAlign: TextAlign.center,
                      'Looking for the best drivers for you',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 7,

                      backgroundColor: AppColors.linearIndicatorColor
                          .withOpacity(0.2),
                      color: AppColors.linearIndicatorColor,
                    ),
                    SizedBox(height: 20),
                    Image.asset(
                      AppImages.confirmCar,
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 20),
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
                    AppButtons.button(
                      hasBorder: true,
                      borderColor: AppColors.commonBlack.withOpacity(0.2),

                      buttonColor: AppColors.commonWhite,
                      textColor: AppColors.cancelRideColor,

                      onTap: () {},
                      text: 'Cancel Ride',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 350,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? const LatLng(0, 0),
                  zoom: 16,
                ),

                // markers: {
                //   Marker(
                //     markerId: const MarkerId('current'),
                //     position: _currentPosition!,
                //     icon:
                //         _customIcon ??
                //         BitmapDescriptor.defaultMarker,
                //   ),
                // },
                onMapCreated: (controller) async {
                  _mapController = controller;
                  String style = await DefaultAssetBundle.of(
                    context,
                  ).loadString('assets/map_style/map_style1.json');
                  _mapController!.setMapStyle(style);
                },
                onCameraMove: (CameraPosition position) {
                  // Save camera target every frame
                  _pickedPosition = position.target;

                  // Check if this is a zoom action
                  if (_lastZoom != null &&
                      (position.zoom - _lastZoom!).abs() > _zoomThreshold) {
                    // It's zooming — ignore
                    _lastZoom = position.zoom;
                    return;
                  }

                  _lastZoom = position.zoom;
                },

                onCameraIdle: () async {
                  LatLngBounds? bounds =
                      await _mapController?.getVisibleRegion();
                  if (bounds != null) {
                    final centerLat =
                        (bounds.northeast.latitude +
                            bounds.southwest.latitude) /
                        2;
                    final centerLng =
                        (bounds.northeast.longitude +
                            bounds.southwest.longitude) /
                        2;

                    _currentPosition = LatLng(centerLat, centerLng);
                    await _getAddressFromLatLng(_currentPosition!);
                    setState(() {});
                  }
                },

                //
                // onCameraIdle: () {
                //   if (_isCameraMoving &&
                //       _currentPosition != null) {
                //     _isCameraMoving = false;
                //     _getAddressFromLatLng(_currentPosition!);
                //     setState(() {
                //       // Only update on confirm, or if you want to auto update:
                //       // _currentPosition = _pickedPosition;
                //     });
                //   }
                // },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,

                mapToolbarEnabled: false,
                zoomControlsEnabled: false,

                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
