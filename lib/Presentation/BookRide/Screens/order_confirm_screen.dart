import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
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
  const OrderConfirmScreen({
    super.key,
    required this.pickupData,
    required this.destinationData,
    required this.pickupAddress,
    required this.destinationAddress,
  });

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  bool _isDrawingPolyline = false;

  bool isDriverConfirmed = false;
  bool driverStartedRide = false;
  bool destinationReached = false;
  bool _autoFollowEnabled = false;
  Timer? _autoFollowTimer;
    String bookingId= ' ';
  bool _userInteractingWithMap = false;
  final socketService = SocketService();
  GoogleMapController? _mapController;
  LatLng? _pickedPosition;
  double? _lastZoom;
  final double _zoomThreshold = 0.01;
  Marker? _driverMarker;
  Set<Marker> _markers = {};
  BitmapDescriptor? _carIcon;
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
  int Amount = 0;
  Set<Polyline> _polylines = {};

  Future<void> _loadCustomMarker() async {
    _carIcon = await BitmapDescriptor.asset(
      height: 60,
      ImageConfiguration(size: Size(52, 52)),
      AppImages.carHop,
    );
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
    _loadCustomMarker();
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
      final String carType = vehicle['carType'] ?? '';
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
        CARTYPE = carType;
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) =>
                      PaymentScreen(bookingId: bookingId, amount: Amount),
            ),
          );
        });

        AppLogger.log.i("driver_reached,$data");
      }
    });
    socketService.on('customer-cancelled', (data) async {
      AppLogger.log.i('customer-cancelled : $data');

      if (data != null) {
        if (data['status'] == true) {
          Get.offAll(() => HomeScreens());
        }
      }
    });
    socketService.on('driver-cancelled', (data) async {
      AppLogger.log.i('driver-cancelled : $data');

      if (data != null) {
        if (data['status'] == true) {
          Get.offAll(() => HomeScreens());
        }
      }
    });
    // 🔶 Optional fallback (if using 'tracked-driver-location' too)
    // socketService.on('tracked-driver-location', (data) {
    //   AppLogger.log.i("📡 tracked-driver-location received: $data");
    // });

    _initLocation();
    _goToCurrentLocation();
  }

  void _updateDriverMarker(LatLng position, double bearing) {
    _driverMarker = Marker(
      markerId: const MarkerId("driver_marker"),
      position: position,
      rotation: bearing,
      icon:
          _carIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      anchor: const Offset(0.5, 0.5),
      flat: true,
    );

    if (!mounted) return;
    setState(() {
      // 🟢 Remove old marker and add updated one
      _markers = {
        ..._markers.where((m) => m.markerId != const MarkerId("driver_marker")),
        _driverMarker!,
      };
    });
  }

  Future<void> _animateCarTo(LatLng from, LatLng to) async {
    const steps = 10;
    const duration = Duration(milliseconds: 800);
    final interval = duration.inMilliseconds ~/ steps;

    double currentBearing = _driverMarker?.rotation ?? 0;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));

      final lat = _lerp(from.latitude, to.latitude, i / steps);
      final lng = _lerp(from.longitude, to.longitude, i / steps);
      final intermediate = LatLng(lat, lng);
      double newBearing = _getBearing(from, intermediate);

      if ((newBearing - currentBearing).abs() > 10) {
        currentBearing = newBearing;
      }

      _updateDriverMarker(intermediate, currentBearing);

      // ✅ Only auto-move camera if user is not interacting
      if (Geolocator.distanceBetween(
            _currentDriverLatLng!.latitude,
            _currentDriverLatLng!.longitude,
            intermediate.latitude,
            intermediate.longitude,
          ) >
          1) {
        _updateDriverMarker(intermediate, currentBearing);

        if (_autoFollowEnabled) {
          final zoom = await _mapController?.getZoomLevel() ?? 17;

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: intermediate,
                zoom: zoom,
                tilt: 45, // optional
                bearing: currentBearing, // 👈 map rotates with car
              ),
            ),
          );
        }
      }
    }

    _currentDriverLatLng = to;

    if (driverStartedRide && _customerToLatLang != null) {
      await _drawPolylineFromDriverToCustomer(
        driverLatLng: to,
        customerLatLng: _customerToLatLang!,
      );
    } else if (!driverStartedRide && _customerLatLng != null) {
      await _drawPolylineFromDriverToCustomer(
        driverLatLng: to,
        customerLatLng: _customerLatLng!,
      );
    }
  }

  /*  double _getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final lon2 = end.longitude * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }*/
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

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  Future<void> _drawPolylineFromDriverToCustomer({
    required LatLng driverLatLng,
    required LatLng customerLatLng,
  }) async {
    if (_isDrawingPolyline) return; // prevent multiple calls
    _isDrawingPolyline = true;

    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';

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
              onCameraMoveStarted: () {
                _userInteractingWithMap = true;
                _autoFollowEnabled = false;

                _autoFollowTimer?.cancel();

                // Re-enable auto-follow after 10 seconds
                _autoFollowTimer = Timer(Duration(seconds: 10), () {
                  _autoFollowEnabled = true;
                  _userInteractingWithMap = false;
                });
              },

              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(9.9144908, 78.0970899),
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (controller) async {
                _mapController = controller;
                String style = await DefaultAssetBundle.of(
                  context,
                ).loadString('assets/map_style/map_style1.json');
                _mapController?.setMapStyle(style);
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
            maxChildSize: isDriverConfirmed ? 0.9 : 0.75,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
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
                                        (context) =>
                                            ChatScreen(bookingId: bookingId),
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
                                child: Row(
                                  children: [
                                    CustomTextFields.textWithImage(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      colors: AppColors.commonBlack,
                                      text: 'Total Fare',
                                      rightImagePath: AppImages.nBlackCurrency,
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            color:
                                                AppColors
                                                    .userChatContainerColor,
                                          ),
                                          child:
                                              CustomTextFields.textWithStyles600(
                                                'OTP - $otp',
                                                fontSize: 16,
                                                color: AppColors.commonWhite,
                                              ),
                                        ),
                                  ],
                                ),
                              ),
                              Divider(color: AppColors.containerColor),

                              ListTile(
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
                                  Get.to(
                                    () => PaymentScreen(
                                      bookingId: bookingId,
                                      amount: Amount,
                                    ),
                                  );
                                },
                              ),
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
                                    imagePath: AppImages.cancel,
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
                                    height: 24, // Set the height you need
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
