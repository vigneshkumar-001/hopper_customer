import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/api/repository/api_consents.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/uitls/websocket/socket_io_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class OrderConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> pickupData;
  final Map<String, dynamic> destinationData;
  final String pickupAddress;
  final String destinationAddress;
  final double? baseFare;
  final double? serviceFare;

  const OrderConfirmScreen({
    super.key,
    required this.pickupData,
    required this.destinationData,
    required this.pickupAddress,
    required this.destinationAddress,
    this.baseFare,
    this.serviceFare,
  });

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  bool isExpanded = false; // Track dropdown state
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  bool _isDrawingPolyline = false;
  double _currentZoomLevel = 16.0; // Default zoom

  bool isDriverConfirmed = false;
  bool driverStartedRide = false;
  bool destinationReached = false;
  bool _autoFollowEnabled = false;
  Timer? _autoFollowTimer;
  String bookingId = ' ';
  bool _userInteractingWithMap = false;
  final socketService = SocketService();
  GoogleMapController? _mapController;
  LatLng? _pickedPosition;
  double? _lastZoom;
  final double _zoomThreshold = 0.01;
  Marker? _driverMarker;
  Set<Marker> _markers = {};
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _bikeIcon;
  LatLng? _currentPosition;
  LatLng? _customerLatLng;
  LatLng? _customerToLatLang;
  LatLng? _currentDriverLatLng;

  String _address = 'Search...';
  String plateNumber = '';
  String driverName = '';
  double driverRating = 0.0;
  String carDetails = '';
  String CUSTOMERPHONE = '';
  String CARTYPE = '';
  String otp = '';
  double Amount = 0.0;
  Set<Polyline> _polylines = {};
  bool isTripCancelled = false;
  String cancelReason = "";

  Future<void> _loadCustomMarkers() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(52, 52)),
      AppImages.movingCar,
    );
    _bikeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      AppImages.packageBike,
    );
  }

  BitmapDescriptor _iconForVehicleType(String? type) {
    final t = (type ?? '').toLowerCase();
    switch (t) {
      case 'bike':
      case 'two_wheeler':
      case '2w':
      case 'motorbike':
      case 'scooter':
        return _bikeIcon ?? BitmapDescriptor.defaultMarker;
      case 'car':
      case 'sedan':
      case 'hatchback':
      case 'suv':
      default:
        return _carIcon ?? BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _initLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    AppLogger.log.i(_currentPosition);
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
    _loadCustomMarkers().then((_) {
      _setupSocketListeners();
      _initLocation();
      _goToCurrentLocation();
    });
  }

  void _setupSocketListeners() {
    socketService.onConnect(() {
      AppLogger.log.i("✅ Socket connected on booking screen");
    });

    socketService.on('joined-booking', (data) {
      if (!mounted) return;
      AppLogger.log.i("🚕 Joined booking data: $data");
      final vehicle = data['vehicle'] ?? {};
      final String driverId = data['driverId'] ?? '';
      final String driverFullName = data['driverName'] ?? '';
      final String customerPhone = data['customerPhone'].toString() ?? '';
      final double rating =
          double.tryParse(data['driverRating'].toString()) ?? 0.0;
      final String color = vehicle['color'] ?? '';
      final String model = vehicle['model'] ?? '';
      final String brand = vehicle['brand'] ?? '';
      final String serviceType = vehicle['serviceType'] ?? '';
      final bool driverAccepted = data['driver_accept_status'] == true;
      final String type = vehicle['type'] ?? '';
      final String plate = vehicle['plateNumber'] ?? '';
      final customerLoc = data['customerLocation'];
      final amount = data['amount'];

      _customerLatLng = LatLng(
        customerLoc['fromLatitude'],
        customerLoc['fromLongitude'],
      );
      _customerToLatLang = LatLng(
        customerLoc['toLatitude'],
        customerLoc['toLongitude'],
      );

      setState(() {
        plateNumber = plate;
        driverName = '$driverFullName ⭐ $rating';
        carDetails = '$color - $brand';
        isDriverConfirmed = driverAccepted;
        CUSTOMERPHONE = customerPhone;
        CARTYPE = serviceType;
        Amount = amount;
      });

      AppLogger.log.i("🚕 Joined booking data: $data");
      AppLogger.log.i("🚕 driverAccepted ==  $driverAccepted");

      // Start real-time tracking
      if (driverId.trim().isNotEmpty) {
        AppLogger.log.i("📍 Tracking driver: $driverId");
        socketService.emit('track-driver', {'driverId': driverId.trim()});
      }
    });

    socketService.on('driver-location', (data) {
      AppLogger.log.i('📦 driver-location-updated: $data');

      final newDriverLatLng = LatLng(data['latitude'], data['longitude']);

      if (_currentDriverLatLng == null) {
        _currentDriverLatLng = newDriverLatLng;
        _updateDriverMarker(newDriverLatLng, 0);
        return;
      }

      // ✅ Animate movement
      _animateCarTo(_currentDriverLatLng!, newDriverLatLng);

      if (!driverStartedRide && _customerLatLng != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: newDriverLatLng,
          customerLatLng: _customerLatLng!,
        );
      }

      // ✅ CASE 2: After ride starts → Draw polyline to drop
      if (driverStartedRide && _customerToLatLang != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: newDriverLatLng,
          customerLatLng: _customerToLatLang!,
        );
      }

      // ✅ Update current driver position
      _currentDriverLatLng = newDriverLatLng;
    });

    socketService.on('driver-arrived', (data) {
      AppLogger.log.i("driver-arrived: $data");
    });

    socketService.on('otp-generated', (data) {
      if (!mounted) return;
      final otpGenerated = data['otpCode'];
      setState(() {
        otp = otpGenerated;
      });

      AppLogger.log.i("otp-generated: $data");
    });

    socketService.on('ride-started', (data) {
      final bool status = data['status'] == true;
      AppLogger.log.i("ride-started: $data");

      driverStartedRide = status; // don't wait for setState

      if (!mounted) return;
      setState(() {}); // only for UI like info card updates

      if (status &&
          _currentDriverLatLng != null &&
          _customerToLatLang != null) {
        final dropMarker = Marker(
          markerId: const MarkerId("drop_marker"),
          position: _customerToLatLang!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Destination"),
        );

        setState(() {
          _markers = {if (_driverMarker != null) _driverMarker!, dropMarker};
        });

        _drawPolylineFromDriverToCustomer(
          driverLatLng: _currentDriverLatLng!,
          customerLatLng: _customerToLatLang!,
        );
      }
    });
    socketService.on('driver-reached-destination', (data) {
      final String bookingId =
          driverSearchController.carBooking.value!.bookingId;
      final status = data['status'];
      final amount = data['amount'];
      if (status == true || status.toString() == 'status') {
        if (!mounted) return;
        setState(() {
          destinationReached = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Get.to(() => PaymentScreen(bookingId: bookingId, amount: Amount));
        });

        AppLogger.log.i("driver_reached,$data");
      }
    });
    socketService.on('customer-cancelled', (data) async {
      AppLogger.log.i('customer-cancelled : $data');

      if (data != null && data['status'] == true) {
        if (!mounted) return;

        setState(() {
          isTripCancelled = true;
          cancelReason =
              data['reason'] ?? "Driver had to cancel due to an emergency";
        });

        // Optional: Automatically go back after showing UI for some time
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        Get.offAll(() => HomeScreens());
      }
    });
    socketService.on('driver-cancelled', (data) async {
      AppLogger.log.i('driver-cancelled : $data');

      if (data != null && data['status'] == true) {
        if (!mounted) return;

        setState(() {
          isTripCancelled = true;
          cancelReason =
              data['reason'] ?? "Driver had to cancel due to an emergency";
        });

        // Optional: Automatically go back after showing UI for some time
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        Get.offAll(() => HomeScreens());
      }
    });

    // 🔶 Optional fallback (if using 'tracked-driver-location' too)
    // socketService.on('tracked-driver-location', (data) {
    //   AppLogger.log.i("📡 tracked-driver-location received: $data");
    // });
  }

  void _updateDriverMarker(LatLng position, double bearing) {
    final newMarker = Marker(
      markerId: const MarkerId("driver_marker"),
      position: position,
      rotation: bearing,
      icon: _iconForVehicleType(CARTYPE),
      anchor: const Offset(0.5, 0.5),
      flat: true,
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "driver_marker");
      _markers.add(newMarker);
      _driverMarker = newMarker;
    });
  }

  Future<void> _animateCarTo(LatLng from, LatLng to) async {
    if (!mounted || _mapController == null) return;

    const int steps = 60; // number of animation steps
    const int durationMs = 1200; // total animation duration
    final int stepMs = (durationMs / steps).round();

    double currentBearing = _driverMarker?.rotation ?? 0;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;

      await Future.delayed(Duration(milliseconds: stepMs));

      final t = i / steps;
      final lat = _lerp(from.latitude, to.latitude, t);
      final lng = _lerp(from.longitude, to.longitude, t);
      final intermediate = LatLng(lat, lng);

      // Smooth bearing calculation
      double newBearing = _getBearing(from, to);
      final bearing = _lerpAngle(currentBearing, newBearing, t);

      // Update marker only once per step
      _updateDriverMarker(intermediate, bearing);

      // Move camera occasionally for smoothness
      if (_autoFollowEnabled && i % 10 == 0) {
        try {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: intermediate,
                zoom: _currentZoomLevel,
                tilt: 45,
                bearing: bearing,
              ),
            ),
          );
        } catch (e) {
          AppLogger.log.e("⛔ animateCamera error: $e");
        }
      }
    }

    _currentDriverLatLng = to; // update current driver position
  }

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  double _lerpAngle(double start, double end, double t) {
    double difference = end - start;
    while (difference < -180) difference += 360;
    while (difference > 180) difference -= 360;
    return start + difference * t;
  }

  double _getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final lon2 = end.longitude * math.pi / 180;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = (math.atan2(y, x) * 180 / math.pi + 360) % 360;

    // Smooth bearing over updates
    if (_driverMarker != null) {
      double prevBearing = _driverMarker!.rotation;
      bearing = _lerpAngle(prevBearing, bearing, 0.2); // smoothing factor
    }

    return bearing;
  }

  Future<void> _drawPolylineFromDriverToCustomer({
    required LatLng driverLatLng,
    required LatLng customerLatLng,
  }) async {
    if (_isDrawingPolyline) return;
    _isDrawingPolyline = true;

    String apiKey = ApiConsents.googleMapApiKey;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLatLng.latitude},${driverLatLng.longitude}&destination=${customerLatLng.latitude},${customerLatLng.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (!mounted) return;
    if (data['status'] == 'OK') {
      final encoded = data['routes'][0]['overview_polyline']['points'];
      final points = _decodePolyline(encoded);
      if (!mounted) return;
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId(
              driverStartedRide ? "driver_to_drop" : "driver_to_pickup",
            ),
            points: points,
            color: Colors.black,
            width: 4,
          ),
        };
      });
    } else {
      print("❗ Error fetching directions: ${data['status']}");
    }
    _isDrawingPolyline = false;
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

  final DriverSearchController driverSearchController = Get.put(
    DriverSearchController(),
  );
  void _onCameraMove(CameraPosition position) {
    _currentZoomLevel = position.zoom;
  }

  @override
  Widget build(BuildContext context) {
    _startController.text = widget.pickupAddress;
    _destController.text = widget.destinationAddress;
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 550,
            width: double.infinity,
            child: GoogleMap(
              compassEnabled: false,
              onCameraMoveStarted: () {
                _userInteractingWithMap = true;
                _autoFollowEnabled = false;

                _autoFollowTimer?.cancel();

                _autoFollowTimer = Timer(Duration(seconds: 10), () {
                  _autoFollowEnabled = true;
                  _userInteractingWithMap = false;
                });
              },
              onCameraMove: _onCameraMove,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(9.9144908, 78.0970899),
                zoom: _currentZoomLevel,
              ),
              markers: _markers,
              onMapCreated: (controller) async {
                _mapController = controller;
                String style = await DefaultAssetBundle.of(
                  context,
                ).loadString('assets/map_style/map_style1.json');
                _mapController?.setMapStyle(style);

                _autoFollowEnabled = true; // Enable auto-follow
              },
              polylines: _polylines,
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
            key: ValueKey(isDriverConfirmed),
            initialChildSize: isDriverConfirmed ? 0.65 : 0.5,
            minChildSize: 0.4,
            maxChildSize: isDriverConfirmed ? 0.9 : 0.80,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    if (!isDriverConfirmed) ...[
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
                              readOnly: true,
                              Style: TextStyle(
                                fontSize: 12,
                                color: AppColors.commonBlack.withOpacity(0.6),
                                overflow: TextOverflow.ellipsis,
                              ),
                              controller: _startController,
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.circleStart,
                              title: 'Search for an address or landmark',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 17,
                            ),
                            const Divider(
                              height: 0,
                              color: AppColors.containerColor,
                            ),
                            CustomTextFields.plainTextField(
                              readOnly: true,
                              Style: TextStyle(
                                fontSize: 12,
                                color: AppColors.commonBlack.withOpacity(0.6),
                                overflow: TextOverflow.ellipsis,
                              ),
                              controller: _destController,
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.rectangleDest,
                              title: 'Enter destination',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 17,
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
                        onTap: () {
                          // setState(() {
                          //   isDriverConfirmed = !isDriverConfirmed;
                          // });
                          AppButtons.showCancelRideBottomSheet(
                            context,
                            onConfirmCancel: (String selectedReason) {
                              driverSearchController.cancelRide(
                                bookingId:
                                    driverSearchController
                                        .carBooking
                                        .value!
                                        .bookingId,
                                selectedReason: selectedReason,
                                context: context,
                              );
                            },
                          );
                        },
                        text: 'Cancel Ride',
                      ),
                    ] else ...[
                      /* if (isTripCancelled)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Your trip has been cancelled",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cancelReason,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      Center(
                        child: CustomTextFields.textWithImage(
                          fontSize: 20,
                          imageSize: 24,
                          fontWeight: FontWeight.w600,
                          text:
                              destinationReached
                                  ? 'Ride Completed'
                                  : driverStartedRide
                                  ? 'Ride in Progress'
                                  : 'Your ride is confirmed',
                          colors: AppColors.commonBlack,
                          rightImagePath: AppImages.clrTick,
                        ),
                      ),*/
                      if (isTripCancelled)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Your trip has been cancelled",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cancelReason,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // RIDE COMPLETED / IN PROGRESS / CONFIRMED UI
                        Center(
                          child: CustomTextFields.textWithImage(
                            fontSize: 20,
                            imageSize: 24,
                            fontWeight: FontWeight.w600,
                            text:
                                destinationReached
                                    ? 'Ride Completed'
                                    : driverStartedRide
                                    ? 'Ride in Progress'
                                    : 'Your ride is confirmed',
                            colors: AppColors.commonBlack,
                            rightImagePath: AppImages.clrTick,
                          ),
                        ),

                      SizedBox(height: 12),
                      Row(
                        children: [
                          Column(
                            spacing: 5,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextFields.textWithStylesSmall(
                                plateNumber,
                                colors: AppColors.commonBlack,
                                fontWeight: FontWeight.w500,
                              ),
                              CustomTextFields.textWithStylesSmall(
                                '${driverName}',
                                colors: AppColors.commonBlack,
                                fontWeight: FontWeight.w500,
                              ),
                              CustomTextFields.textWithStylesSmall(
                                carDetails,
                                fontSize: 12,
                                colors: AppColors.carTypeColor,
                              ),
                            ],
                          ),
                          Spacer(),
                          Image.asset(
                            CARTYPE == 'sedan'
                                ? AppImages.sedan
                                : AppImages.luxuryCar,
                            height: 50,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: AppColors.containerColor1,
                            ),

                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () async {
                                  final phoneNumber = 'tel:$CUSTOMERPHONE';
                                  AppLogger.log.i(phoneNumber);
                                  final Uri url = Uri.parse(phoneNumber);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    print('Could not launch dialer');
                                  }
                                },
                                child: Image.asset(
                                  AppImages.call,

                                  height: 20,
                                  width: 20,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),

                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatScreen(
                                          bookingId:
                                              driverSearchController
                                                  .carBooking
                                                  .value!
                                                  .bookingId,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.containerColor1,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      CustomTextFields.textWithStylesSmall(
                                        colors: AppColors.commonBlack,
                                        'Message your driver',
                                      ),
                                      Spacer(),
                                      Image.asset(
                                        AppImages.send,
                                        height: 16,
                                        width: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.commonWhite,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CustomTextFields.textWithImage(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          colors: AppColors.commonBlack,
                                          text: 'Total Fare',
                                          rightImagePath:
                                              AppImages.nBlackCurrency,
                                          rightImagePathText: ' $Amount',
                                        ),

                                        Spacer(),
                                        otp == ''
                                            ? SizedBox.shrink()
                                            : Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color:
                                                    AppColors
                                                        .userChatContainerColor,
                                              ),
                                              child:
                                                  CustomTextFields.textWithStyles600(
                                                    'OTP - $otp',
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.commonWhite,
                                                  ),
                                            ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            isExpanded = !isExpanded;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            CustomTextFields.textWithStylesSmall(
                                              'View Details',
                                              colors:
                                                  AppColors.changeButtonColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            const SizedBox(width: 10),
                                            AnimatedRotation(
                                              turns: isExpanded ? 0.5 : 0,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              child: Image.asset(
                                                AppImages.dropDown,
                                                height: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      switchInCurve: Curves.easeInOut,
                                      switchOutCurve: Curves.easeInOut,
                                      transitionBuilder: (child, animation) {
                                        return SizeTransition(
                                          sizeFactor: animation,
                                          axisAlignment: -1, // expand downwards
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child:
                                          isExpanded
                                              ? Column(
                                                key: const ValueKey("expanded"),
                                                children: [
                                                  const SizedBox(height: 10),

                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          top: 10,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: AppColors
                                                            .commonBlack
                                                            .withOpacity(0.1),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          "Fare Breakdown",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 5,
                                                        ),

                                                        /// Base fare
                                                        Row(
                                                          children: [
                                                            CustomTextFields.textWithStylesSmall(
                                                              'Base Fare',
                                                            ),
                                                            const Spacer(),
                                                            CustomTextFields.textWithImage(
                                                              colors:
                                                                  AppColors
                                                                      .commonBlack,
                                                              text:
                                                                  widget
                                                                      .baseFare
                                                                      .toString() ??
                                                                  '0',
                                                              imagePath:
                                                                  AppImages
                                                                      .nBlackCurrency,
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Row(
                                                          children: [
                                                            CustomTextFields.textWithStylesSmall(
                                                              'Service Fare',
                                                            ),
                                                            const Spacer(),
                                                            CustomTextFields.textWithImage(
                                                              colors:
                                                                  AppColors
                                                                      .commonBlack,
                                                              text:
                                                                  widget
                                                                      .serviceFare
                                                                      .toString() ??
                                                                  '0',
                                                              imagePath:
                                                                  AppImages
                                                                      .nBlackCurrency,
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                ],
                                              )
                                              : const SizedBox.shrink(
                                                key: ValueKey("collapsed"),
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 5),

                              // Divider(color: AppColors.containerColor),

                              /*ListTile(
                                leading: Image.asset(
                                  AppImages.cash,
                                  height: 24,
                                  width: 24,
                                ),
                                title: CustomTextFields.textWithStylesSmall(
                                  "Cash Payment",
                                  fontSize: 15,
                                  colors: AppColors.commonBlack,
                                  fontWeight: FontWeight.w500,
                                ),

                                trailing: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: AppColors.resendBlue.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                  child: CustomTextFields.textWithStyles600(
                                    fontSize: 10,
                                    color: AppColors.changeButtonColor,
                                    'Change',
                                  ),
                                ),
                                onTap: () {},
                              ),
                              ListTile(
                                leading: Image.asset(
                                  AppImages.digiPay,
                                  height: 32,
                                  width: 32,
                                ),
                                title: CustomTextFields.textWithStylesSmall(
                                  "Pay using card, UPI & more",
                                  fontSize: 15,
                                  colors: AppColors.commonBlack,
                                  fontWeight: FontWeight.w500,
                                ),

                                subtitle: CustomTextFields.textWithStylesSmall(
                                  'Pay during the ride to avoid cash payments',
                                  fontSize: 10,
                                ),
                                trailing: Image.asset(
                                  AppImages.rightArrow,
                                  height: 20,
                                  color: AppColors.commonBlack,
                                  width: 20,
                                ),
                                onTap: () {
                                  final String bookingId =
                                      driverSearchController
                                          .carBooking
                                          .value!
                                          .bookingId;
                                  print(bookingId);
                                  Get.to(
                                    () => PaymentScreen(
                                      bookingId: bookingId,
                                      amount: Amount,
                                    ),
                                  );
                                },
                              ),*/
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.containerColor1,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 5,
                            children: [
                              CustomTextFields.textWithStyles600(
                                'Directions to reach',
                                fontSize: 14,
                              ),
                              CustomTextFields.textWithStylesSmall(
                                'Help your driver partner reach you faster',
                                fontSize: 12,
                              ),
                              CustomTextFields.textWithStylesSmall(
                                'Add Direction',
                                fontSize: 12,
                                colors: AppColors.resendBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        ),
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
                              readOnly: true,
                              Style: TextStyle(
                                fontSize: 12,
                                color: AppColors.commonBlack.withOpacity(0.6),
                                overflow: TextOverflow.ellipsis,
                              ),
                              controller: _startController,
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.circleStart,
                              title: 'Search for an address or landmark',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 17,
                            ),
                            const Divider(
                              height: 0,
                              color: AppColors.containerColor,
                            ),
                            CustomTextFields.plainTextField(
                              readOnly: true,
                              Style: TextStyle(
                                fontSize: 12,
                                color: AppColors.commonBlack.withOpacity(0.6),
                                overflow: TextOverflow.ellipsis,
                              ),
                              controller: _destController,
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.rectangleDest,
                              title: 'Enter destination',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 17,
                            ),
                            const Divider(
                              height: 0,
                              color: AppColors.containerColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomTextFields.textWithImage(
                                    onTap:
                                        otp.isNotEmpty
                                            ? null
                                            : () {
                                              // setState(() {
                                              //   isDriverConfirmed = !isDriverConfirmed;
                                              // });
                                              AppButtons.showCancelRideBottomSheet(
                                                context,
                                                onConfirmCancel: (
                                                  String selectedReason,
                                                ) {
                                                  driverSearchController
                                                      .cancelRide(
                                                        bookingId:
                                                            driverSearchController
                                                                .carBooking
                                                                .value!
                                                                .bookingId,
                                                        selectedReason:
                                                            selectedReason,
                                                        context: context,
                                                      );
                                                },
                                              );
                                            },
                                    text:
                                        otp.isNotEmpty
                                            ? 'Ratings'
                                            : ' Cancel Ride',
                                    fontWeight: FontWeight.w500,
                                    colors: AppColors.cancelRideColor,
                                    imagePath:
                                        otp.isNotEmpty
                                            ? null
                                            : AppImages.cancel,
                                  ),
                                  SizedBox(width: 10),
                                  Container(
                                    height: 24, // Set the height you need
                                    child: VerticalDivider(
                                      color: Colors.grey,
                                      thickness: 1,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  CustomTextFields.textWithImage(
                                    text: 'Support',
                                    fontWeight: FontWeight.w500,
                                    colors: AppColors.cancelRideColor,
                                    imagePath: AppImages.support,
                                  ),

                                  SizedBox(width: 10),
                                  Container(
                                    height: 24,
                                    child: VerticalDivider(
                                      color: Colors.grey,
                                      thickness: 1,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  CustomTextFields.textWithImage(
                                    onTap: () {
                                      final String bookingId =
                                          driverSearchController
                                              .carBooking
                                              .value!
                                              .bookingId;
                                      final url =
                                          "https://hoppr-admin-e7bebfb9fb05.herokuapp.com/ride-tracker/$bookingId";
                                      Share.share(url);
                                    },
                                    text: 'Share',
                                    fontWeight: FontWeight.w500,
                                    colors: AppColors.cancelRideColor,
                                    imagePath: AppImages.support,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
