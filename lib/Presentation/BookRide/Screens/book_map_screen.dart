import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui; // Important for image and canvas
import 'package:flutter/services.dart'; // For rootBundle

import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Core/Utility/app_toasts.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/Presentation/BookRide/Screens/confirm_booking.dart';
import 'package:hopper/Presentation/BookRide/Screens/ride_share_screen.dart';
import 'package:hopper/Presentation/BookRide/Screens/search_screen.dart';

import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:hopper/driver_detail_controller.dart';
import 'package:hopper/uitls/netWorkHandling/network_handling_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';

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
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _destinationIcon;
  Set<Marker> _markers = {};
  Offset? _pickupOffset;
  Offset? _dropOffset;
  bool _markerAdded = false;
  String? _estimatedTime;

  Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;
  bool isSendSelected = true;

  String _address = 'Search...';
  LatLng? _currentPosition;

  String? _mapStyle;
  Future<void> _loadCustomMarkers() async {
    _startIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(65, 65)),
      AppImages.circleStart,
    );
    _destinationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(65, 65)),
      AppImages.rectangleDest,
    );
    setState(() {}); // Refresh map once icons are loaded
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadCustomMarkers();

    LatLng? pickupLocation;
    LatLng? destinationLocation;

    if (widget.pickupData.containsKey('location')) {
      pickupLocation = widget.pickupData['location'];
    } else if (widget.pickupData.containsKey('lat') &&
        widget.pickupData.containsKey('lng')) {
      pickupLocation = LatLng(
        widget.pickupData['lat'],
        widget.pickupData['lng'],
      );
    }

    if (widget.destinationData.containsKey('location')) {
      destinationLocation = widget.destinationData['location'];
    } else if (widget.destinationData.containsKey('lat') &&
        widget.destinationData.containsKey('lng')) {
      destinationLocation = LatLng(
        widget.destinationData['lat'],
        widget.destinationData['lng'],
      );
    }

    if (pickupLocation == null || destinationLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar("Error", "Location data is missing");
      });
      return;
    }

    double distance = Geolocator.distanceBetween(
      pickupLocation.latitude,
      pickupLocation.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    if (distance < 1000) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back(); // First, go back

        // Delay the toast slightly to ensure the context is still safe
        Future.delayed(const Duration(milliseconds: 300), () {
          AppToasts.customToast(
            Get.context!, // safer than old `context` after pop
            'Pickup and destination must be more than 1 km apart.',
          );
        });
      });
      return;
    }

    _pickupPosition = pickupLocation;
    _destinationPosition = destinationLocation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      driverController.getDriverSearch(
        pickupLat: _pickupPosition!.latitude,
        pickupLng: _pickupPosition!.longitude,
        dropLat: _destinationPosition!.latitude,
        dropLng: _destinationPosition!.longitude,
      );
    });

    _drawPolyline();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style/map_style.json');
  }

  void _fitBounds() async {
    if (_pickupPosition == null ||
        _destinationPosition == null ||
        _mapController == null)
      return;

    double minLat = math.min(
      _pickupPosition!.latitude,
      _destinationPosition!.latitude,
    );
    double maxLat = math.max(
      _pickupPosition!.latitude,
      _destinationPosition!.latitude,
    );
    double minLng = math.min(
      _pickupPosition!.longitude,
      _destinationPosition!.longitude,
    );
    double maxLng = math.max(
      _pickupPosition!.longitude,
      _destinationPosition!.longitude,
    );

    const minDelta = 0.009;
    if ((maxLat - minLat) < minDelta) {
      minLat -= minDelta;
      maxLat += minDelta;
    }
    if ((maxLng - minLng) < minDelta) {
      minLng -= minDelta;
      maxLng += minDelta;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 120),
    );
  }

  Future<void> _drawPolyline() async {
    final String apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
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

  Future<BitmapDescriptor> createCustomMarkerWithLabel({
    required String label,
    required String assetPath,
    String? timeText, // null means no time box
    double width = 300,
    double height = 100,
    double iconSize = 50,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    const double cornerRadius = 0;
    const double padding = 10;
    const double timeBoxWidth = 60;

    final bool showTime = timeText != null;
    final double labelBoxWidth =
        showTime ? width - timeBoxWidth - (padding * 3) : width - (padding * 2);
    final double totalHeight = height + iconSize + 10;

    // Draw background box
    final RRect backgroundBox = RRect.fromLTRBR(
      0,
      0,
      width,
      height,
      const Radius.circular(cornerRadius),
    );
    paint.color = Colors.white;
    canvas.drawRRect(backgroundBox, paint);

    // Time Box
    if (showTime) {
      paint.color = Colors.black;
      final RRect timeBox = RRect.fromLTRBR(
        0,
        0,
        padding + timeBoxWidth,
        height - 0,
        const Radius.circular(0),
      );
      canvas.drawRRect(timeBox, paint);

      // Draw Time Text
      // Draw Time Text in vertical format (top: 1, bottom: MIN)
      final timePara =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 2),
            )
            ..pushStyle(
              ui.TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            )
            ..addText(
              timeText.replaceAll(" ", "\n"),
            ); // 🔁 Replaces "1 MIN" → "1\nMIN"

      final timeParagraph = timePara.build();
      timeParagraph.layout(ui.ParagraphConstraints(width: timeBoxWidth));
      canvas.drawParagraph(
        timeParagraph,
        Offset(padding, (height - timeParagraph.height) / 2),
      );
    }

    // Draw Label
    final labelPara =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              maxLines: 2,
              ellipsis: '',
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: Colors.black,
              fontSize: 29,
              fontWeight: FontWeight.w600,
            ),
          )
          ..addText(label);

    final labelParagraph = labelPara.build();
    labelParagraph.layout(ui.ParagraphConstraints(width: labelBoxWidth));

    final labelOffsetX = showTime ? padding + timeBoxWidth + padding : padding;
    canvas.drawParagraph(
      labelParagraph,
      Offset(labelOffsetX, (height - labelParagraph.height) / 2),
    );

    // Draw Marker Icon Below
    final ByteData data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final ui.Image markerImage = frame.image;

    final imageOffset = Offset((width - iconSize) / 2, height + 5);
    canvas.drawImageRect(
      markerImage,
      Rect.fromLTWH(
        0,
        0,
        markerImage.width.toDouble(),
        markerImage.height.toDouble(),
      ),
      Rect.fromLTWH(imageOffset.dx, imageOffset.dy, iconSize, iconSize),
      paint,
    );

    final picture = recorder.endRecording();
    final ui.Image finalImage = await picture.toImage(
      width.toInt(),
      totalHeight.toInt(),
    );
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _addMarkers(String estimatedTime) async {
    final startIcon = await createCustomMarkerWithLabel(
      timeText: estimatedTime.isNotEmpty ? '$estimatedTime MIN' : null,
      label: widget.pickupAddress,
      assetPath: AppImages.circleStart,
    );

    final destIcon = await createCustomMarkerWithLabel(
      timeText: null,
      label: widget.destinationAddress,
      assetPath: AppImages.rectangleDest,
    );

    _markers.clear();

    _markers.add(
      Marker(
        markerId: MarkerId("pickup"),
        icon: startIcon,
        position: _pickupPosition!,
      ),
    );

    _markers.add(
      Marker(
        markerId: MarkerId("destination"),
        icon: destIcon,
        position: _destinationPosition!,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _startController.text = widget.pickupAddress;
    _destController.text = widget.destinationAddress;

    return NoInternetOverlay(
      child: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Scaffold(
          body: NotificationListener<ScrollNotification>(
            onNotification: (_) => true,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  expandedHeight: 320,
                  automaticallyImplyLeading: false,
                  pinned: true,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        GoogleMap(
                          compassEnabled: false,

                          myLocationEnabled: true,
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: _pickupPosition ?? LatLng(0, 0),
                            zoom: 14,
                          ),
                          onMapCreated: (controller) async {
                            _mapController = controller;

                            if (!mounted) return;

                            String style = await DefaultAssetBundle.of(
                              context,
                            ).loadString('assets/map_style/map_style.json');
                            _mapController!.setMapStyle(style);

                            _fitBounds();
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

                          polylines: _polylines,
                          markers: _markers,
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
                          left: 15,

                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CommonBottomNavigation(
                                        initialIndex: 0,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                AppImages.backImage,
                                height: 25,
                                width: 25,
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
                                autofocus: false,
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
                                              'description':
                                                  _startController.text,
                                              'lat': _pickupPosition?.latitude,
                                              'lng': _pickupPosition?.longitude,
                                            },
                                            destinationData: {
                                              'description':
                                                  _destController.text,
                                              'lat':
                                                  _destinationPosition
                                                      ?.latitude,
                                              'lng':
                                                  _destinationPosition
                                                      ?.longitude,
                                            },
                                          ),
                                    ),
                                  );

                                  if (selected != null &&
                                      selected['pickup'] != null) {
                                    final pickup = selected['pickup'];
                                    final LatLng updatedPickupLoc =
                                        pickup['location'];

                                    setState(() {
                                      _startController.text =
                                          pickup['description'];
                                      _pickupPosition = updatedPickupLoc;
                                      _drawPolyline();
                                      _fitBounds();
                                    });
                                  }
                                },

                                hintStyle: TextStyle(fontSize: 11),
                                imgHeight: 17,
                                controller: _startController,

                                containerColor: AppColors.commonWhite,
                                leadingImage: AppImages.circleStart,

                                title: 'Search for an address or landmark',
                              ),
                              const Divider(
                                height: 0,
                                color: AppColors.containerColor,
                              ),
                              CustomTextFields.plainTextField(
                                autofocus: false,
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
                                              'description':
                                                  _startController.text,
                                              'lat': _pickupPosition?.latitude,
                                              'lng': _pickupPosition?.longitude,
                                            },
                                            destinationData: {
                                              'description':
                                                  _destController.text,
                                              'lat':
                                                  _destinationPosition
                                                      ?.latitude,
                                              'lng':
                                                  _destinationPosition
                                                      ?.longitude,
                                            },
                                          ),
                                    ),
                                  );

                                  if (selected != null &&
                                      selected['destination'] != null) {
                                    final dest = selected['destination'];
                                    final LatLng updatedDestLoc =
                                        dest['location'];

                                    setState(() {
                                      _destController.text =
                                          dest['description'];
                                      _destinationPosition = updatedDestLoc;
                                      _drawPolyline();
                                      _fitBounds();
                                    });
                                  }
                                },

                                controller: _destController,

                                hintStyle: TextStyle(fontSize: 11),
                                imgHeight: 17,
                                containerColor: AppColors.commonWhite,
                                leadingImage: AppImages.rectangleDest,
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
                            AppLogger.log.i(isSendSelected);
                          },
                        ),
                        SizedBox(height: 20),
                        Obx(() {
                          if (driverController.isGetLoading.value) {
                            return AppLoader.circularLoader();
                          }

                          if (driverController.serviceType.isEmpty) {
                            return Center(
                              child: Text(
                                'No drivers in your location',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          final luxuryDriver = driverController.serviceType
                              .firstWhereOrNull(
                                (e) =>
                                    e.driverId.carType?.toLowerCase() ==
                                    'luxury',
                              );

                          final sedanDriver = driverController.serviceType
                              .firstWhereOrNull(
                                (e) =>
                                    e.driverId.carType?.toLowerCase() ==
                                    'sedan',
                              );

                          if (!driverController.markerAdded.value &&
                              (luxuryDriver != null || sedanDriver != null)) {
                            final defaultDriver = luxuryDriver ?? sedanDriver;
                            driverController.estimatedTime.value =
                                defaultDriver?.estimatedTime?.toString() ?? '';
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _addMarkers(driverController.estimatedTime.value);
                              driverController.markerAdded.value = true;
                            });
                          }

                          return Column(
                            children: [
                              if (luxuryDriver != null)
                                PackageContainer.bookCarTypeContainer(
                                  borderColor:
                                      driverController.selectedCarType.value ==
                                              'Luxury'
                                          ? AppColors.commonBlack
                                          : AppColors.containerColor,

                                  carImg: AppImages.luxuryCar,
                                  onTap: () {
                                    driverController.selectedCarType.value =
                                        'Luxury';
                                    driverController.estimatedTime.value =
                                        luxuryDriver.estimatedTime
                                            ?.toString() ??
                                        '';
                                    _addMarkers(
                                      driverController.estimatedTime.value,
                                    );
                                  },
                                  carTitle: 'Luxury',
                                  carMinRate:
                                      luxuryDriver.estimatedPrice.toString(),
                                  carMaxRate:
                                      (luxuryDriver.estimatedPrice + 30)
                                          .toString(),
                                  carSubTitle: 'Comfy, Economical Cars',
                                  arrivingTime:
                                      '${luxuryDriver.estimatedTime ?? 0} min',
                                ),
                              const SizedBox(height: 20),
                              if (sedanDriver != null)
                                PackageContainer.bookCarTypeContainer(
                                  borderColor:
                                      driverController.selectedCarType.value ==
                                              'Sedan'
                                          ? AppColors.commonBlack
                                          : AppColors.containerColor,

                                  carImg: AppImages.sedan,
                                  onTap: () {
                                    driverController.selectedCarType.value =
                                        'Sedan';
                                    driverController.estimatedTime.value =
                                        sedanDriver.estimatedTime?.toString() ??
                                        '';
                                    _addMarkers(
                                      driverController.estimatedTime.value,
                                    );
                                  },
                                  carTitle: 'Sedan',
                                  carMinRate:
                                      sedanDriver.estimatedPrice.toString(),
                                  carMaxRate:
                                      (sedanDriver.estimatedPrice + 32)
                                          .toString(),
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

          bottomNavigationBar: Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child:
                  driverController.isLoading.value
                      ? AppLoader.appLoader()
                      : AppButtons.button(
                        buttonColor:
                            driverController.selectedCarType.value.isEmpty
                                ? AppColors.containerColor
                                : AppColors.commonBlack,
                        textColor: Colors.white,
                        onTap: () async {
                          if (driverController.selectedCarType.value.isEmpty) {
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     content: Text(
                            //       'Please select a car to proceed.',
                            //     ),
                            //     backgroundColor: Colors.red,
                            //   ),
                            // );
                            Get.closeAllSnackbars();
                            Get.snackbar(
                              'Info',
                              'Please select a car before proceeding.',
                              backgroundColor: AppColors.commonBlack,
                              colorText: AppColors.commonWhite,
                            );

                            return;
                          }

                          final result = await driverController
                              .createBookingCar(
                                fromLatitude: _pickupPosition?.latitude ?? 0.0,
                                fromLongitude:
                                    _pickupPosition?.longitude ?? 0.0,
                                toLatitude:
                                    _destinationPosition?.latitude ?? 0.0,
                                toLongitude:
                                    _destinationPosition?.longitude ?? 0.0,
                                customerId: '',
                                context: context,
                              );

                          if (result == null) {
                            final _selectedCarType =
                                driverController.selectedCarType.value;
                            if (isSendSelected) {
                              final carType =
                                  driverController.selectedCarType.value;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ConfirmBooking(

                                        carType: carType,
                                        selectedCarType: _selectedCarType,
                                        pickupData: {
                                          'description': widget.pickupAddress,
                                          'lat':
                                              _pickupPosition?.latitude ?? 0.0,
                                          'lng':
                                              _pickupPosition?.longitude ?? 0.0,
                                        },
                                        destinationData: {
                                          'description':
                                              widget.destinationAddress,
                                          'lat':
                                              _destinationPosition?.latitude ??
                                              0.0,
                                          'lng':
                                              _destinationPosition?.longitude ??
                                              0.0,
                                        },
                                        pickupAddress: widget.pickupAddress,
                                        destinationAddress:
                                            widget.destinationAddress,
                                      ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => RideShareScreen(
                                        selectedCarType: _selectedCarType,
                                        pickupData: {
                                          'description': widget.pickupAddress,
                                          'lat':
                                              _pickupPosition?.latitude ?? 0.0,
                                          'lng':
                                              _pickupPosition?.longitude ?? 0.0,
                                        },
                                        destinationData: {
                                          'description':
                                              widget.destinationAddress,
                                          'lat':
                                              _destinationPosition?.latitude ??
                                              0.0,
                                          'lng':
                                              _destinationPosition?.longitude ??
                                              0.0,
                                        },
                                        pickupAddress: widget.pickupAddress,
                                        destinationAddress:
                                            widget.destinationAddress,
                                      ),
                                ),
                              );
                            }
                          }
                        },

                        text:
                            driverController.selectedCarType.value.isEmpty
                                ? 'Book'
                                : 'Book ${driverController.selectedCarType.value}',
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
