import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'dart:math';
import 'Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'api/repository/api_consents.dart';

class DummyScreen extends StatefulWidget {
  const DummyScreen({super.key});

  @override
  State<DummyScreen> createState() => _DummyScreenState();
}

class _DummyScreenState extends State<DummyScreen> {
  final DriverSearchController driverSearchController = Get.put(
    DriverSearchController(),
  );
  GoogleMapController? _mapController;
  final socketService = SocketService();

  LatLng? _currentDriverLatLng;
  LatLng? _customerLatLng;
  LatLng? _customerToLatLng;
  bool _isDriverConfirmed = false;
  BitmapDescriptor? _carIcon;
  Marker? _driverMarker;
  bool destinationReached = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool driverStartedRide = false;
  bool _isDrawingPolyline = false;
  bool _autoFollowEnabled = true; // Map will follow driver by default
  LatLng? _customerToLatLang;
  Timer? _autoFollowTimer;
  bool _userInteractingWithMap = false;
  String plateNumber = '';
  String driverName = '';
  double driverRating = 0.0;
  String carDetails = '';
  String CUSTOMERPHONE = '';
  String CARTYPE = '';
  String ProfilePic = '';
  String BookingId = '';
  int? MaxWeight;
  String PickupAddress = '';
  String DropAddress = '';
  bool _isOrderConfirmed = false;
  bool _isEnRoute = false;
  bool _isPackagePickup = false;
  bool _isPackageCollected = false;
  bool _isInTransit = false;
  bool _isOutForDelivery = false;
  String _estimateStt1 = '';
  String _estimateStt2 = '';
  String otp = '';
  final GlobalKey _senderKey = GlobalKey();
  final GlobalKey _receiverKey = GlobalKey();

  double lineHeight = 60;
  void _calculateLineHeight() {
    final senderBox =
        _senderKey.currentContext?.findRenderObject() as RenderBox?;
    final receiverBox =
        _receiverKey.currentContext?.findRenderObject() as RenderBox?;

    if (senderBox != null && receiverBox != null) {
      final senderPos = senderBox.localToGlobal(Offset.zero);
      final receiverPos = receiverBox.localToGlobal(Offset.zero);

      final calculatedHeight = receiverPos.dy - senderPos.dy - 30;
      setState(() {
        lineHeight = calculatedHeight > 0 ? calculatedHeight : 0;
      });
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
    _initLocation();
    _goToCurrentLocation();
    _loadCustomMarker();
    initSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateLineHeight());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _autoFollowTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomMarker() async {
    _carIcon = await BitmapDescriptor.asset(
      height: 70,
      ImageConfiguration(size: const Size(60, 60)),
      AppImages.packageBike, // your car/bike asset
    );
  }

  void initSocket() {
    socketService.onConnect(() {
      AppLogger.log.i("✅ Socket connected on booking screen");
    });

    socketService.on('joined-booking', (data) {
      AppLogger.log.i("📦 Joined booking: $data");
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
      final String profilePic = data['profilePic'];
      final String bookingId = data['bookingId'];
      final int maxWeight = data['maxWeight'];
      final String pickupAddress = data['pickupAddress'];
      final String dropAddress = data['dropAddress'];

      _customerLatLng = LatLng(
        customerLoc['fromLatitude'],
        customerLoc['fromLongitude'],
      );
      _customerToLatLng = LatLng(
        customerLoc['toLatitude'],
        customerLoc['toLongitude'],
      );
      setState(() {
        plateNumber = plate;
        driverName = '$driverFullName ⭐ $rating';
        carDetails = '$color - $brand';
        _isDriverConfirmed = driverAccepted;
        CUSTOMERPHONE = customerPhone;
        CARTYPE = carType;
        ProfilePic = profilePic;
        BookingId = bookingId;
        MaxWeight = maxWeight;
        PickupAddress = pickupAddress;
        DropAddress = dropAddress;
      });

      // Start driver tracking
      if (driverId.trim().isNotEmpty) {
        AppLogger.log.i("📍 Tracking driver: $driverId");
        socketService.emit('track-driver', {'driverId': driverId.trim()});
      }
    });

    socketService.on('driver-location', (data) {
      AppLogger.log.i("🚖 driver-location: $data");

      final newDriverLatLng = LatLng(data['latitude'], data['longitude']);

      if (_currentDriverLatLng == null) {
        _currentDriverLatLng = newDriverLatLng;
        _updateDriverMarker(newDriverLatLng, 0);
        return;
      }

      _animateCarTo(newDriverLatLng);

      if (!driverStartedRide && _customerLatLng != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: newDriverLatLng,
          customerLatLng: _customerLatLng!,
        );
      }

      if (driverStartedRide && _customerToLatLng != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: newDriverLatLng,
          customerLatLng: _customerToLatLng!,
        );
      }
      final basePayload = data['basePayload'] ?? {};
      final estimate = basePayload['getEstimateTime'] ?? {};

      setState(() {
        _isOrderConfirmed = basePayload['orderConfirmationStatus'] ?? false;
        _isEnRoute = basePayload['enRoute'] ?? false;
        _isPackagePickup = basePayload['packagePickup'] ?? false;
        _isPackageCollected = basePayload['packageCollected'] ?? false;
        _isInTransit = basePayload['inTransit'] ?? false;
        _isOutForDelivery = basePayload['outForDelivery'] ?? false;
        _estimateStt1 = estimate['stt1'] ?? '';
        _estimateStt2 = estimate['stt2'] ?? '';
      });
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
      // final String bookingId =
      //     driverSearchController.carBooking.value!.bookingId;
      final status = data['status'];
      final amount = data['amount'];
      if (status == true || status.toString() == 'status') {
        if (!mounted) return;
        setState(() {
          destinationReached = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
        });

        AppLogger.log.i("driver_reached,$data");
      }
    });

    socketService.on('driver-reached-destination', (data) {
      AppLogger.log.i("✅ Driver reached destination: $data");
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
  }

  // ================================
  // 🚖 DRIVER MARKER UPDATES
  // ================================
  Future<void> _animateCarTo(LatLng newLatLng) async {
    final oldLatLng = _currentDriverLatLng!;
    final bearing = _getBearing(oldLatLng, newLatLng);

    // Animate marker
    final marker = Marker(
      markerId: const MarkerId("driver"),
      position: newLatLng,
      rotation: bearing,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "driver");
      _markers.add(marker);
      _driverMarker = marker;
    });

    // Animate camera with car if auto-follow enabled
    if (_autoFollowEnabled && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newLatLng,
            zoom: 16,
            tilt: 60,
            bearing: bearing,
          ),
        ),
      );
    }

    _currentDriverLatLng = newLatLng;
  }

  void _updateDriverMarker(LatLng latLng, double bearing) {
    final marker = Marker(
      markerId: const MarkerId("driver"),
      position: latLng,
      rotation: bearing,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "driver");
      _markers.add(marker);
      _driverMarker = marker;
    });
  }

  double _getBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (pi / 180.0);
    double lon1 = start.longitude * (pi / 180.0);
    double lat2 = end.latitude * (pi / 180.0);
    double lon2 = end.longitude * (pi / 180.0);

    double dLon = lon2 - lon1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x);
    bearing = bearing * (180 / pi);
    return (bearing + 360) % 360;
  }

  // ================================
  // 🚏 POLYLINE DRAWING
  // ================================
  Future<void> _drawPolylineFromDriverToCustomer({
    required LatLng driverLatLng,
    required LatLng customerLatLng,
  }) async
  {
    if (_isDrawingPolyline) return;
    _isDrawingPolyline = true;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLatLng.latitude},${driverLatLng.longitude}&destination=${customerLatLng.latitude},${customerLatLng.longitude}&key=${ApiConsents.googleMapApiKey}';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final encoded = data['routes'][0]['overview_polyline']['points'];
      final points = _decodePolyline(encoded);

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
      debugPrint("❌ Error fetching directions: ${data['status']}");
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
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // ================================
  // 📍 UI
  // ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 550,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    _currentDriverLatLng ?? const LatLng(9.9144908, 78.0970899),
                zoom: 16,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,

              onMapCreated: (controller) async {
                _mapController = controller;
                String style = await DefaultAssetBundle.of(
                  context,
                ).loadString('assets/map_style/map_style1.json');
                _mapController?.setMapStyle(style);
              },
              onCameraMoveStarted: () {
                _userInteractingWithMap = true;
                _autoFollowEnabled = false;

                _autoFollowTimer?.cancel();
                _autoFollowTimer = Timer(const Duration(seconds: 10), () {
                  _autoFollowEnabled = true;
                  _userInteractingWithMap = false;
                });
              },
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
          // Positioned(
          //   top: 330,
          //   right: 10,
          //   child: Container(
          //     padding: const EdgeInsets.all(6),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(6),
          //       color: Colors.white,
          //       boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black26)],
          //     ),
          //     child: Column(
          //       children: const [
          //         Text(
          //           "10:39",
          //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          //         ),
          //         Text(
          //           "minutes remaining",
          //           style: TextStyle(fontSize: 12, color: Colors.grey),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          DraggableScrollableSheet(
            key: ValueKey(_isDriverConfirmed),

            initialChildSize: _isDriverConfirmed ? 0.55 : 0.5,
            minChildSize: 0.5,
            maxChildSize: _isDriverConfirmed ? 0.90 : 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(color: Colors.white),
                child: SafeArea(
                  top: false,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(top: 15),
                    children: [
                      SizedBox(height: 20),
                      if (!_isDriverConfirmed) ...[
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
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
                                    color: AppColors.commonBlack.withOpacity(
                                      0.6,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

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
                                    color: AppColors.commonBlack.withOpacity(
                                      0.6,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  containerColor: AppColors.commonWhite,
                                  leadingImage: AppImages.rectangleDest,
                                  title: 'Enter destination',
                                  hintStyle: TextStyle(fontSize: 11),
                                  imgHeight: 17,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: AppButtons.button(
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
                                    bookingId: BookingId,
                                    selectedReason: selectedReason,
                                    context: context,
                                  );
                                },
                              );
                            },
                            text: 'Cancel Ride',
                          ),
                        ),
                      ] else ...[
                        Center(
                          child: CustomTextFields.textWithImage(
                            imageColors: AppColors.walletCurrencyColor,
                            imagePath:
                                _isDriverConfirmed ? null : AppImages.clrTick,
                            colors: AppColors.commonBlack,
                            imageSize: 24,
                            fontWeight: FontWeight.w700,
                            text:
                                _isDriverConfirmed
                                    ? 'Pickup in Progress'
                                    : '  Your order is confirmed',
                            fontSize: 16,
                          ),
                        ),

                        Divider(thickness: 2, color: AppColors.dividerColor1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    spacing: 5,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextFields.textWithStylesSmall(
                                        'PKG - ${BookingId}',
                                        colors: AppColors.commonBlack,
                                        fontWeight: FontWeight.w500,
                                      ),

                                      Row(
                                        children: [
                                          ClipOval(
                                            child: Image.network(
                                              ProfilePic,
                                              fit: BoxFit.cover,
                                              height: 40,
                                              width: 40,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          CustomTextFields.textWithStylesSmall(
                                            fontSize: 15,
                                            driverName,
                                            colors: AppColors.commonBlack,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          // SizedBox(width: 5),
                                          // Image.asset(
                                          //   AppImages.star,
                                          //   width: 13,
                                          //   height: 13,
                                          // ),
                                          // SizedBox(width: 5),
                                          // CustomTextFields.textWithStyles600(
                                          //   '4.5',
                                          // ),
                                        ],
                                      ),
                                      CustomTextFields.textWithStylesSmall(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        'Vehicle: Bike ($plateNumber)',
                                        colors:
                                            AppColors.rideShareContainerColor2,
                                      ),
                                    ],
                                  ),
                                  Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: AppColors.chatCallContainerColor,
                                    ),

                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () async {
                                          const phoneNumber = 'tel:8248191110';
                                          AppLogger.log.i(phoneNumber);
                                          final Uri url = Uri.parse(
                                            phoneNumber,
                                          );
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          } else {
                                            print('Could not launch dialer');
                                          }
                                        },
                                        child: Image.asset(
                                          AppImages.chatCall,
                                          height: 20,
                                          width: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: AppColors.chatBlueColor,
                                    ),

                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () async {
                                          Get.to(ChatScreen(bookingId: ''));
                                        },
                                        child: Image.asset(
                                          AppImages.chat,
                                          height: 20,
                                          width: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(''),

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
                                              AppColors.userChatContainerColor,
                                        ),
                                        child:
                                            CustomTextFields.textWithStyles600(
                                              'OTP - $otp',
                                              fontSize: 12,
                                              color: AppColors.commonWhite,
                                            ),
                                      ),
                                ],
                              ),
                              SizedBox(height: 20),

                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.chatBlueColor.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 17,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset(
                                              AppImages.direction,
                                              height: 20,
                                              width: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            CustomTextFields.textWithStyles600(
                                              _estimateStt1,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const SizedBox(width: 30),
                                            Expanded(
                                              child:
                                                  CustomTextFields.textWithStylesSmall(
                                                    maxLines: 2,
                                                    fontWeight: FontWeight.w500,
                                                    colors:
                                                        _isDriverConfirmed
                                                            ? AppColors
                                                                .changeButtonColor
                                                            : AppColors
                                                                .greyDark,
                                                    _estimateStt2,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 25),
                              _isOrderConfirmed && !_isPackageCollected
                                  ? PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrTick1,
                                    title: 'Order Confirmed',
                                    subTitle: 'Courier En Route',
                                  )
                                  : PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrTick1,
                                    title: 'Package Collected',
                                    subTitle: '3:45 PM • From Madurai, TN',
                                  ),
                              const SizedBox(height: 10),
                              _isEnRoute && !_isInTransit
                                  ? PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrDirection,
                                    title: 'Courier En Route',
                                    subTitle: 'Completed',
                                  )
                                  : PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrBox1,
                                    title: 'In Transit',
                                    subTitle: 'Completed • To Chennai, TN',
                                  ),
                              const SizedBox(height: 10),
                              _isPackagePickup && !_isOutForDelivery
                                  ? PackageContainer.pickUpFields(
                                    title1: 'Ready',
                                    imagePath: AppImages.box,
                                    title: 'Package Pickup',
                                    subTitle: 'Ready for Pickup',
                                  )
                                  : PackageContainer.pickUpFields(
                                    title1: 'Ready',
                                    imagePath: AppImages.clrHome,
                                    title: 'Out for Delivery',
                                    subTitle: 'Attempting delivery',
                                  ),

                              SizedBox(height: 15),
                              Divider(color: AppColors.dividerColor1),

                              Row(
                                children: [
                                  CustomTextFields.textWithStylesSmall(
                                    'Order ID',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    colors: AppColors.commonBlack,
                                  ),
                                  Spacer(),
                                  CustomTextFields.textWithStylesSmall(
                                    'PKG- ${BookingId}',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    colors: AppColors.commonBlack,
                                  ),
                                  SizedBox(width: 10),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        // Handle tap
                                      },
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // Match with Material
                                      splashColor: Colors.blue.withOpacity(
                                        0.3,
                                      ), // Splash effect color
                                      highlightColor: Colors.blue.withOpacity(
                                        0.1,
                                      ), // Highlight color on tap down
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset(
                                          AppImages.paste,
                                          height: 15,
                                          width: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  CustomTextFields.textWithStylesSmall(
                                    'Package Weight',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    colors: AppColors.commonBlack,
                                  ),
                                  Spacer(),
                                  CustomTextFields.textWithStylesSmall(
                                    '${MaxWeight} kg',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    colors: AppColors.commonBlack,
                                  ),
                                ],
                              ),
                              Divider(color: AppColors.dividerColor1),
                              SizedBox(height: 10),

                              const SizedBox(height: 12),
                              Stack(
                                children: [
                                  Card(
                                    elevation: 5,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        // Pickup Address
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Icon(
                                                  Icons.circle,
                                                  color: Colors.green,
                                                  size: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Pickup Address',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      PickupAddress,
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Divider(
                                          height: 0,
                                          color: Colors.grey[200],
                                        ),

                                        // Delivery Address
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 5,
                                                ),
                                                child: Icon(
                                                  Icons.circle,
                                                  color: Colors.orange,
                                                  size: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Delivery Address',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      DropAddress,
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Divider(
                                          height: 0,
                                          color: Colors.grey[300],
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 35,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  AppLogger.log.i(BookingId);

                                                  AppButtons.showPackageCancelBottomSheet(
                                                    context,
                                                    onConfirmCancel: (
                                                      String selectedReason,
                                                    ) {
                                                      driverSearchController
                                                          .cancelRide(
                                                            bookingId:
                                                                BookingId.toString(),
                                                            selectedReason:
                                                                selectedReason,
                                                            context: context,
                                                          );
                                                    },
                                                  );
                                                },
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.close,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      'Cancel Courier',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height:
                                                      24, // Set the height you need
                                                  child: VerticalDivider(
                                                    color: Colors.grey,
                                                    thickness: 1,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    AppImages.support,
                                                    height: 15,
                                                    width: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    ' Support',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Positioned(
                                    top: 37,
                                    left: 25,
                                    child: DottedLine(
                                      direction: Axis.vertical,
                                      lineLength: 80,
                                      dashLength: 4,
                                      dashColor: AppColors.dotLineColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: 5,
                                color: AppColors.commonWhite,
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
                                              rightImagePath:
                                                  AppImages.nBlackCurrency,
                                              rightImagePathText: ' 73',
                                            ),

                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: AppColors.commonBlack,
                                              ),
                                              child:
                                                  CustomTextFields.textWithStyles600(
                                                    'PKG - ${BookingId}',
                                                    color:
                                                        AppColors.commonWhite,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(color: AppColors.dividerColor1),

                                      ListTile(
                                        leading: Image.asset(
                                          AppImages.cash,
                                          height: 24,
                                          width: 24,
                                        ),
                                        title:
                                            CustomTextFields.textWithStylesSmall(
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
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            color: AppColors.resendBlue
                                                .withOpacity(0.1),
                                          ),
                                          child:
                                              CustomTextFields.textWithStyles600(
                                                fontSize: 10,
                                                color:
                                                    AppColors.changeButtonColor,
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
                                        title:
                                            CustomTextFields.textWithStylesSmall(
                                              "Pay using card, UPI & more",
                                              fontSize: 15,
                                              colors: AppColors.commonBlack,
                                              fontWeight: FontWeight.w500,
                                            ),

                                        subtitle:
                                            CustomTextFields.textWithStylesSmall(
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
                                          // Get.to(() => PaymentScreen());
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/*class _DummyScreenState extends State<DummyScreen> {
  GoogleMapController? _mapController;
  final socketService = SocketService();
  LatLng? _lastDriverPosition;
  LatLng? _currentPosition;
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _carIcon;
  Set<Marker> _markers = {};
  bool _isDriverConfirmed = false;
  Marker? _driverMarker;
  bool driverStartedRide = false;
  bool destinationReached = false;
  bool _autoFollowEnabled = false;
  bool _isDrawingPolyline = false;
  bool _isOrderConfirmed = false;
  bool _isEnRoute = false;
  bool _isPackagePickup = false;
  bool _isPackageCollected = false;
  bool _isInTransit = false;
  bool _isOutForDelivery = false;
  String _estimateStt1 = '';
  String _estimateStt2 = '';

  LatLng? _customerLatLng;
  LatLng? _customerToLatLang;
  String plateNumber = '';
  String driverName = '';
  double driverRating = 0.0;
  String carDetails = '';
  String CUSTOMERPHONE = '';
  String CARTYPE = '';
  String ProfilePic = '';
  String BookingId = '';
  int? MaxWeight;
  String PickupAddress = '';
  String DropAddress = '';
  String otp = '';
  LatLng? _currentDriverLatLng;
  Future<void> _loadCustomMarker() async {
    _carIcon = await BitmapDescriptor.asset(
      height: 60,
      ImageConfiguration(size: Size(52, 52)),
      AppImages.packageBike,
    );
  }

  final GlobalKey _senderKey = GlobalKey();
  final GlobalKey _receiverKey = GlobalKey();

  double lineHeight = 60;
  void _calculateLineHeight() {
    final senderBox =
        _senderKey.currentContext?.findRenderObject() as RenderBox?;
    final receiverBox =
        _receiverKey.currentContext?.findRenderObject() as RenderBox?;

    if (senderBox != null && receiverBox != null) {
      final senderPos = senderBox.localToGlobal(Offset.zero);
      final receiverPos = receiverBox.localToGlobal(Offset.zero);

      final calculatedHeight = receiverPos.dy - senderPos.dy - 30;
      setState(() {
        lineHeight = calculatedHeight > 0 ? calculatedHeight : 0;
      });
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
    _initLocation();
    _goToCurrentLocation();
    _loadCustomMarker();
    initSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateLineHeight());
  }

  void initSocket() {
    socketService.onConnect(() {
      AppLogger.log.i("✅ Socket connected on booking screen");
    });

    socketService.on('joined-booking', (data) {
      if (!mounted) return;
      AppLogger.log.i("Package Joined booking data: $data");
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
      final String profilePic = data['profilePic'];
      final String bookingId = data['bookingId'];
      final int maxWeight = data['maxWeight'];
      final String pickupAddress = data['pickupAddress'];
      final String dropAddress = data['dropAddress'];

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
        _isDriverConfirmed = driverAccepted;
        CUSTOMERPHONE = customerPhone;
        CARTYPE = carType;
        ProfilePic = profilePic;
        BookingId = bookingId;
        MaxWeight = maxWeight;
        PickupAddress = pickupAddress;
        DropAddress = dropAddress;
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

      _animateCarTo(_currentDriverLatLng!);

      if (!driverStartedRide && _customerLatLng != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: newDriverLatLng,
          customerLatLng: _customerLatLng!,
        );
      }

      if (driverStartedRide && _customerToLatLang != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: newDriverLatLng,
          customerLatLng: _customerToLatLang!,
        );
      }

      _currentDriverLatLng = newDriverLatLng;

      // 📦 Extract flags
      final basePayload = data['basePayload'] ?? {};
      final estimate = basePayload['getEstimateTime'] ?? {};

      setState(() {
        _isOrderConfirmed = basePayload['orderConfirmationStatus'] ?? false;
        _isEnRoute = basePayload['enRoute'] ?? false;
        _isPackagePickup = basePayload['packagePickup'] ?? false;
        _isPackageCollected = basePayload['packageCollected'] ?? false;
        _isInTransit = basePayload['inTransit'] ?? false;
        _isOutForDelivery = basePayload['outForDelivery'] ?? false;
        _estimateStt1 = estimate['stt1'] ?? '';
        _estimateStt2 = estimate['stt2'] ?? '';
      });
    });

    */
/*   socketService.on('driver-location', (data) {
      AppLogger.log.i('📦 driver-location-updated: $data');

      final newDriverLatLng = LatLng(data['latitude'], data['longitude']);

      if (_currentDriverLatLng == null) {
        _currentDriverLatLng = newDriverLatLng;
        _updateDriverMarker(newDriverLatLng, 0);
        return;
      }

      // ✅ Animate movement
      _animateCarTo(_currentDriverLatLng!);

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
    });*/
/*

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
      // final String bookingId =
      //     driverSearchController.carBooking.value!.bookingId;
      final status = data['status'];
      final amount = data['amount'];
      if (status == true || status.toString() == 'status') {
        if (!mounted) return;
        setState(() {
          destinationReached = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
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
  }

  double getRotation(LatLng start, LatLng end) {
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

  Future<void> _animateCarTo(LatLng newPosition) async {
    if (_carIcon == null) return;

    if (_lastDriverPosition == null) {
      _lastDriverPosition = newPosition;
      _updateDriverMarker(newPosition, 0);
      return;
    }

    final distance = Geolocator.distanceBetween(
      _lastDriverPosition!.latitude,
      _lastDriverPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    if (distance < 2) return; // ignore jitter

    final rotation = getRotation(_lastDriverPosition!, newPosition);

    // Animate marker position
    const steps = 25;
    final latStep =
        (newPosition.latitude - _lastDriverPosition!.latitude) / steps;
    final lngStep =
        (newPosition.longitude - _lastDriverPosition!.longitude) / steps;

    for (int i = 0; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 50), () {
        final lat = _lastDriverPosition!.latitude + (latStep * i);
        final lng = _lastDriverPosition!.longitude + (lngStep * i);

        final pos = LatLng(lat, lng);
        _updateDriverMarker(pos, rotation);

        if (_autoFollowEnabled) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
        }
      });
    }

    _lastDriverPosition = newPosition;
  }
  */
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
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
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
  }*/
/*

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

  Future<void> _drawPolylineFromDriverToCustomer({
    required LatLng driverLatLng,
    required LatLng customerLatLng,
  }) async
  {
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
  bool _userInteractingWithMap = false;
  Timer? _autoFollowTimer;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          */
/* SizedBox(
            height: 550,
            width: double.infinity,
            child: GoogleMap(
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
          ),*/
/*
          SizedBox(
            height: 550,
            width: double.infinity,
            child: GoogleMap(
              onCameraMoveStarted: () {
                _userInteractingWithMap = true;
                _autoFollowEnabled = false;

                _autoFollowTimer?.cancel();

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
              zoomControlsEnabled: true,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
          Positioned(
            top: 330,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: AppColors.commonWhite,
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    CustomTextFields.textWithStyles600(
                      '10:39',
                      fontSize: 18,
                      color: AppColors.walletCurrencyColor,
                    ),
                    CustomTextFields.textWithStylesSmall('minutes remaining'),
                  ],
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            key: ValueKey(_isDriverConfirmed),

            initialChildSize: _isDriverConfirmed ? 0.55 : 0.5,
            minChildSize: 0.5,
            maxChildSize: _isDriverConfirmed ? 0.90 : 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(color: Colors.white),
                child: SafeArea(
                  top: false,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(top: 15),
                    children: [
                      SizedBox(height: 20),
                      if (!_isDriverConfirmed) ...[
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
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
                                    color: AppColors.commonBlack.withOpacity(
                                      0.6,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

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
                                    color: AppColors.commonBlack.withOpacity(
                                      0.6,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  containerColor: AppColors.commonWhite,
                                  leadingImage: AppImages.rectangleDest,
                                  title: 'Enter destination',
                                  hintStyle: TextStyle(fontSize: 11),
                                  imgHeight: 17,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: AppButtons.button(
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
                                    bookingId: BookingId,
                                    selectedReason: selectedReason,
                                    context: context,
                                  );
                                },
                              );
                            },
                            text: 'Cancel Ride',
                          ),
                        ),
                      ] else ...[
                        Center(
                          child: CustomTextFields.textWithImage(
                            imageColors: AppColors.walletCurrencyColor,
                            imagePath:
                                _isDriverConfirmed ? null : AppImages.clrTick,
                            colors: AppColors.commonBlack,
                            imageSize: 24,
                            fontWeight: FontWeight.w700,
                            text:
                                _isDriverConfirmed
                                    ? 'Pickup in Progress'
                                    : '  Your order is confirmed',
                            fontSize: 16,
                          ),
                        ),

                        Divider(thickness: 2, color: AppColors.dividerColor1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    spacing: 5,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextFields.textWithStylesSmall(
                                        'PKG - ${BookingId}',
                                        colors: AppColors.commonBlack,
                                        fontWeight: FontWeight.w500,
                                      ),

                                      Row(
                                        children: [
                                          ClipOval(
                                            child: Image.network(
                                              ProfilePic,
                                              fit: BoxFit.cover,
                                              height: 40,
                                              width: 40,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          CustomTextFields.textWithStylesSmall(
                                            fontSize: 15,
                                            driverName,
                                            colors: AppColors.commonBlack,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          // SizedBox(width: 5),
                                          // Image.asset(
                                          //   AppImages.star,
                                          //   width: 13,
                                          //   height: 13,
                                          // ),
                                          // SizedBox(width: 5),
                                          // CustomTextFields.textWithStyles600(
                                          //   '4.5',
                                          // ),
                                        ],
                                      ),
                                      CustomTextFields.textWithStylesSmall(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        'Vehicle: Bike ($plateNumber)',
                                        colors:
                                            AppColors.rideShareContainerColor2,
                                      ),
                                    ],
                                  ),
                                  Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: AppColors.chatCallContainerColor,
                                    ),

                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () async {
                                          const phoneNumber = 'tel:8248191110';
                                          AppLogger.log.i(phoneNumber);
                                          final Uri url = Uri.parse(
                                            phoneNumber,
                                          );
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          } else {
                                            print('Could not launch dialer');
                                          }
                                        },
                                        child: Image.asset(
                                          AppImages.chatCall,
                                          height: 20,
                                          width: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: AppColors.chatBlueColor,
                                    ),

                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () async {
                                          Get.to(ChatScreen(bookingId: ''));
                                        },
                                        child: Image.asset(
                                          AppImages.chat,
                                          height: 20,
                                          width: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(''),

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
                                              AppColors.userChatContainerColor,
                                        ),
                                        child:
                                            CustomTextFields.textWithStyles600(
                                              'OTP - $otp',
                                              fontSize: 12,
                                              color: AppColors.commonWhite,
                                            ),
                                      ),
                                ],
                              ),
                              SizedBox(height: 20),

                              */
/* GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isDriverConfirmed = !_isDriverConfirmed;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.chatBlueColor.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 17,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset(
                                              AppImages.direction,
                                              height: 20,
                                              width: 20,
                                            ),
                                            SizedBox(width: 10),
                                            CustomTextFields.textWithStyles600(
                                              _isDriverConfirmed
                                                  ? 'Attempting delivery now'
                                                  : 'Estimated Pickup Time',
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(''),
                                            SizedBox(width: 30),
                                            CustomTextFields.textWithStylesSmall(
                                              fontWeight: FontWeight.w500,
                                              colors:
                                                  _isDriverConfirmed
                                                      ? AppColors
                                                          .changeButtonColor
                                                      : AppColors.greyDark,
                                              _isDriverConfirmed
                                                  ? "Delivering now• Distance remaining: 0.0 km"
                                                  : 'Expected pickup: 3:45 PM - 4:15 PM',
                                              fontSize: 12,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),*/
/*
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.chatBlueColor.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 17,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset(
                                              AppImages.direction,
                                              height: 20,
                                              width: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            CustomTextFields.textWithStyles600(
                                              _estimateStt1,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const SizedBox(width: 30),
                                            Expanded(
                                              child:
                                                  CustomTextFields.textWithStylesSmall(
                                                    maxLines: 2,
                                                    fontWeight: FontWeight.w500,
                                                    colors:
                                                        _isDriverConfirmed
                                                            ? AppColors
                                                                .changeButtonColor
                                                            : AppColors
                                                                .greyDark,
                                                    _estimateStt2,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 25),
                              _isOrderConfirmed && !_isPackageCollected
                                  ? PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrTick1,
                                    title: 'Order Confirmed',
                                    subTitle: 'Courier En Route',
                                  )
                                  : PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrTick1,
                                    title: 'Package Collected',
                                    subTitle: '3:45 PM • From Madurai, TN',
                                  ),
                              const SizedBox(height: 10),
                              _isEnRoute && !_isInTransit
                                  ? PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrDirection,
                                    title: 'Courier En Route',
                                    subTitle: 'Completed',
                                  )
                                  : PackageContainer.pickUpFields(
                                    imagePath: AppImages.clrBox1,
                                    title: 'In Transit',
                                    subTitle: 'Completed • To Chennai, TN',
                                  ),
                              const SizedBox(height: 10),
                              _isPackagePickup && !_isOutForDelivery
                                  ? PackageContainer.pickUpFields(
                                    title1: 'Ready',
                                    imagePath: AppImages.box,
                                    title: 'Package Pickup',
                                    subTitle: 'Ready for Pickup',
                                  )
                                  : PackageContainer.pickUpFields(
                                    title1: 'Ready',
                                    imagePath: AppImages.clrHome,
                                    title: 'Out for Delivery',
                                    subTitle: 'Attempting delivery',
                                  ),

                              */
/*    if (_isDriverConfirmed) ...[
                                CustomTextFields.textWithStyles700(
                                  'Pickup Progress',
                                  fontSize: 16,
                                ),
                                SizedBox(height: 10),

                                PackageContainer.pickUpFields(
                                  imagePath: AppImages.clrTick1,
                                  title: 'Order Confirmed',
                                  subTitle: 'Courier En Route',
                                ),
                                SizedBox(height: 15),

                                PackageContainer.pickUpFields(
                                  imagePath: AppImages.clrDirection,
                                  title: 'Courier En Route',
                                  subTitle: 'Completed',
                                ),
                                SizedBox(height: 15),

                                PackageContainer.pickUpFields(
                                  title1: 'Ready',
                                  imagePath: AppImages.box,
                                  title: 'Package Pickup',
                                  subTitle: 'Ready for Pickup',
                                ),
                              ]
                              else ...[
                                CustomTextFields.textWithStyles700(
                                  'Delivery Time',
                                  fontSize: 16,
                                ),
                                SizedBox(height: 10),

                                PackageContainer.pickUpFields(
                                  imagePath: AppImages.clrTick1,
                                  title: 'Package Collected',
                                  subTitle: '3:45 PM • From Madurai, TN',
                                ),
                                SizedBox(height: 15),

                                PackageContainer.pickUpFields(
                                  imagePath: AppImages.clrBox1,
                                  title: 'In Transit',
                                  subTitle: 'Completed • To Chennai, TN',
                                ),
                                SizedBox(height: 15),

                                PackageContainer.pickUpFields(
                                  title1: 'Ready',
                                  imagePath: AppImages.clrHome,
                                  title: 'Out for Delivery',
                                  subTitle: 'Attempting delivery',
                                ),
                              ],*/
/*
                              SizedBox(height: 15),
                              Divider(color: AppColors.dividerColor1),

                              Row(
                                children: [
                                  CustomTextFields.textWithStylesSmall(
                                    'Order ID',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    colors: AppColors.commonBlack,
                                  ),
                                  Spacer(),
                                  CustomTextFields.textWithStylesSmall(
                                    'PKG- ${BookingId}',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    colors: AppColors.commonBlack,
                                  ),
                                  SizedBox(width: 10),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        // Handle tap
                                      },
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ), // Match with Material
                                      splashColor: Colors.blue.withOpacity(
                                        0.3,
                                      ), // Splash effect color
                                      highlightColor: Colors.blue.withOpacity(
                                        0.1,
                                      ), // Highlight color on tap down
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset(
                                          AppImages.paste,
                                          height: 15,
                                          width: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  CustomTextFields.textWithStylesSmall(
                                    'Package Weight',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    colors: AppColors.commonBlack,
                                  ),
                                  Spacer(),
                                  CustomTextFields.textWithStylesSmall(
                                    '${MaxWeight} kg',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    colors: AppColors.commonBlack,
                                  ),
                                ],
                              ),
                              Divider(color: AppColors.dividerColor1),
                              SizedBox(height: 10),

                              const SizedBox(height: 12),
                              Stack(
                                children: [
                                  Card(
                                    elevation: 5,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        // Pickup Address
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Icon(
                                                  Icons.circle,
                                                  color: Colors.green,
                                                  size: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Pickup Address',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      PickupAddress,
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Divider(
                                          height: 0,
                                          color: Colors.grey[200],
                                        ),

                                        // Delivery Address
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 5,
                                                ),
                                                child: Icon(
                                                  Icons.circle,
                                                  color: Colors.orange,
                                                  size: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Delivery Address',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      DropAddress,
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Divider(
                                          height: 0,
                                          color: Colors.grey[300],
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 35,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  AppLogger.log.i(BookingId);

                                                  AppButtons.showPackageCancelBottomSheet(
                                                    context,
                                                    onConfirmCancel: (
                                                      String selectedReason,
                                                    ) {
                                                      driverSearchController
                                                          .cancelRide(
                                                            bookingId:
                                                                BookingId.toString(),
                                                            selectedReason:
                                                                selectedReason,
                                                            context: context,
                                                          );
                                                    },
                                                  );
                                                },
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.close,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      'Cancel Courier',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height:
                                                      24, // Set the height you need
                                                  child: VerticalDivider(
                                                    color: Colors.grey,
                                                    thickness: 1,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    AppImages.support,
                                                    height: 15,
                                                    width: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    ' Support',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Positioned(
                                    top: 37,
                                    left: 25,
                                    child: DottedLine(
                                      direction: Axis.vertical,
                                      lineLength: 80,
                                      dashLength: 4,
                                      dashColor: AppColors.dotLineColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: 5,
                                color: AppColors.commonWhite,
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
                                              rightImagePath:
                                                  AppImages.nBlackCurrency,
                                              rightImagePathText: ' 73',
                                            ),

                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: AppColors.commonBlack,
                                              ),
                                              child:
                                                  CustomTextFields.textWithStyles600(
                                                    'PKG - ${BookingId}',
                                                    color:
                                                        AppColors.commonWhite,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(color: AppColors.dividerColor1),

                                      ListTile(
                                        leading: Image.asset(
                                          AppImages.cash,
                                          height: 24,
                                          width: 24,
                                        ),
                                        title:
                                            CustomTextFields.textWithStylesSmall(
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
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            color: AppColors.resendBlue
                                                .withOpacity(0.1),
                                          ),
                                          child:
                                              CustomTextFields.textWithStyles600(
                                                fontSize: 10,
                                                color:
                                                    AppColors.changeButtonColor,
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
                                        title:
                                            CustomTextFields.textWithStylesSmall(
                                              "Pay using card, UPI & more",
                                              fontSize: 15,
                                              colors: AppColors.commonBlack,
                                              fontWeight: FontWeight.w500,
                                            ),

                                        subtitle:
                                            CustomTextFields.textWithStylesSmall(
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
                                          // Get.to(() => PaymentScreen());
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}*/
