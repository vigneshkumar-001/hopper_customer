import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/api/repository/api_consents.dart';
import 'package:hopper/uitls/netWorkHandling/network_handling_screen.dart';
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
import 'package:share_plus/share_plus.dart';

class DriverPose {
  final LatLng latLng;
  final DateTime t;
  final double? bearing;
  DriverPose(this.latLng, {DateTime? t, this.bearing})
    : t = t ?? DateTime.now();
}

class OrderConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> pickupData;
  final Map<String, dynamic> destinationData;
  final String pickupAddress;
  final String bookingId;
  final String carType;
  final String destinationAddress;
  final double? baseFare;
  final double? serviceFare;
  final double? distanceFare;
  final double? pickupFare;
  final double? bookingFee;
  final double? timeFare;

  const OrderConfirmScreen({
    super.key,
    required this.pickupData,
    required this.bookingId,
    required this.destinationData,
    required this.carType,
    required this.pickupAddress,
    required this.destinationAddress,
    this.baseFare,
    this.serviceFare,
    this.distanceFare,
    this.pickupFare,
    this.bookingFee,
    this.timeFare,
  });

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  // ---------------- UI state ----------------
  bool isExpanded = false;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  bool _isDrawingPolyline = false;
  double _currentZoomLevel = 13.5;

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

  // ---------------- Smooth motion engine ----------------

  final List<DriverPose> _poseQueue = <DriverPose>[];
  bool _isAnimatingSegment = false;
  AnimationController? _moveCtrl;
  double _lastBearing = 0;
  Duration _minSeg = const Duration(milliseconds: 450);
  Duration _maxSeg = const Duration(milliseconds: 1600);
  static const double _autoFollowMinZoom = 15.0;
  static const double _autoFollowMaxZoom = 17.0;
  final Curve _ease = Curves.easeInOutCubic;

  // ---------------- Controllers ----------------
  final DriverSearchController driverSearchController = Get.put(
    DriverSearchController(),
  );

  // ---------------- Lifecycle ----------------
  @override
  void initState() {
    super.initState();
    _moveCtrl = AnimationController(vsync: this);

    _loadCustomMarkers().then((_) {
      _setupSocketListeners();
      _initLocation();
      _goToCurrentLocation();
    });
    startDriverSearch();
  }

  @override
  void dispose() {
    _moveCtrl?.dispose();
    super.dispose();
  }

  // ---------------- Assets / Icons ----------------
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

  // ---------------- Location helpers ----------------
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

  // ---------------- Driver searching UI timing ----------------
  bool isWaitingForDriver = true;
  bool noDriverFound = false;

  void startDriverSearch() {
    isWaitingForDriver = true;
    noDriverFound = false;

    Future.delayed(const Duration( seconds: 40), () async {
      if (!isDriverConfirmed) {
        bool hasDriver = await driverSearchController.noDriverFound(
          context: context,
          bookingId: widget.bookingId,
          status: true,
        );

        if (!mounted) return;
        setState(() {
          isWaitingForDriver = false;
          noDriverFound = !hasDriver;
        });
      }
    });
  }

  // ---------------- Socket listeners ----------------
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
      final String customerPhone = data['customerPhone'].toString();
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
      final amount =
          (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0;

      _customerLatLng = LatLng(
        (customerLoc['fromLatitude'] as num).toDouble(),
        (customerLoc['fromLongitude'] as num).toDouble(),
      );
      _customerToLatLang = LatLng(
        (customerLoc['toLatitude'] as num).toDouble(),
        (customerLoc['toLongitude'] as num).toDouble(),
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

      // Start real-time tracking
      if (driverId.trim().isNotEmpty) {
        AppLogger.log.i("📍 Tracking driver: $driverId");
        socketService.emit('track-driver', {'driverId': driverId.trim()});
      }
    });

    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  SMOOTH POSE-QUEUE HANDLER  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    socketService.on('driver-location', (data) {
      AppLogger.log.i('📦 driver-location-updated: $data');

      final lat = (data['latitude'] as num).toDouble();
      final lng = (data['longitude'] as num).toDouble();
      final ts =
          (data['timestamp'] is int)
              ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
              : DateTime.now();
      final srvBearing =
          (data['bearing'] != null)
              ? (data['bearing'] as num).toDouble()
              : null;

      // small jitter guard (ignore sub-meter hops)
      if (_currentDriverLatLng != null) {
        final jitter = Geolocator.distanceBetween(
          _currentDriverLatLng!.latitude,
          _currentDriverLatLng!.longitude,
          lat,
          lng,
        );
        if (jitter < 0.8) {
          return;
        }
      }

      final pose = DriverPose(LatLng(lat, lng), t: ts, bearing: srvBearing);
      _poseQueue.add(pose);

      if (!driverStartedRide && _customerLatLng != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: pose.latLng,
          customerLatLng: _customerLatLng!,
        );
      }
      if (driverStartedRide && _customerToLatLang != null) {
        _drawPolylineFromDriverToCustomer(
          driverLatLng: pose.latLng,
          customerLatLng: _customerToLatLang!,
        );
      }

      _pumpMotion();
    });

    socketService.on('driver-arrived', (data) {
      AppLogger.log.i("driver-arrived: $data");
    });

    socketService.on('otp-generated', (data) {
      if (!mounted) return;
      final otpGenerated = data['otpCode'].toString();
      setState(() {
        otp = otpGenerated;
      });
      AppLogger.log.i("otp-generated: $data");
    });

    socketService.on('ride-started', (data) {
      final bool status = data['status'] == true;
      AppLogger.log.i("ride-started: $data");

      driverStartedRide = status;
      if (!mounted) return;
      setState(() {});

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
      if (status == true) {
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
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        Get.offAll(() => HomeScreens());
      }
    });
  }

  // ---------------- Smooth motion core ----------------
  void _pumpMotion() {
    if (_isAnimatingSegment) return;

    // If marker not placed yet, seed with the first pose
    if (_currentDriverLatLng == null && _poseQueue.isNotEmpty) {
      final first = _poseQueue.removeAt(0);
      _currentDriverLatLng = first.latLng;
      _lastBearing = _driverMarker?.rotation ?? 0;
      _updateDriverMarker(first.latLng, _lastBearing);
    }

    if (_poseQueue.isEmpty || _currentDriverLatLng == null) return;

    final LatLng from = _currentDriverLatLng!;
    final DriverPose toPose = _poseQueue.removeAt(0);
    final LatLng to = toPose.latLng;

    final dist = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    final dtMs = toPose.t.difference(DateTime.now()).inMilliseconds.abs();

    // Base duration scales with distance, blended with cadence if server timestamp present
    int dur = (450 + (dist - 30).clamp(0, 3000) * 0.25).toInt();
    if (dtMs > 0) {
      dur = ((dur * 0.6) + (dtMs * 0.4)).toInt();
    }
    final segDur = Duration(
      milliseconds: dur.clamp(_minSeg.inMilliseconds, _maxSeg.inMilliseconds),
    );

    final targetBearing = (toPose.bearing ?? _getBearing(from, to));
    final startBearing = _lastBearing;
    final bearingDelta = _shortestAngleDelta(startBearing, targetBearing);

    _isAnimatingSegment = true;

    _moveCtrl!
      ..duration = segDur
      ..removeListener(_tickDummy) // make sure not duplicated
      ..addListener(() => _onTick(from, to, startBearing, bearingDelta))
      ..forward(from: 0).whenComplete(() {
        _currentDriverLatLng = to;
        _lastBearing = _normalizeAngle(startBearing + bearingDelta);
        _updateDriverMarker(to, _lastBearing);

        _isAnimatingSegment = false;

        // Coalesce tiny hops to remove jitter
        if (_poseQueue.length >= 2) {
          for (int i = _poseQueue.length - 2; i >= 0; i--) {
            final a = _poseQueue[i].latLng;
            final b = _poseQueue[i + 1].latLng;
            final d = Geolocator.distanceBetween(
              a.latitude,
              a.longitude,
              b.latitude,
              b.longitude,
            );
            if (d < 2.0) {
              _poseQueue.removeAt(i);
            }
          }
        }
        if (_poseQueue.isNotEmpty) _pumpMotion();
      });
  }

  // Used only to removeListener safely
  void _tickDummy() {}

  void _onTick(
    LatLng from,
    LatLng to,
    double startBearing,
    double bearingDelta,
  ) {
    final t = _ease.transform(_moveCtrl!.value);
    final lat = _lerp(from.latitude, to.latitude, t);
    final lng = _lerp(from.longitude, to.longitude, t);
    final pos = LatLng(lat, lng);
    final bearing = _normalizeAngle(startBearing + bearingDelta * t);

    _updateDriverMarker(pos, bearing);

    if (_autoFollowEnabled && _mapController != null) {
      final zoom = _currentZoomLevel.clamp(
        _autoFollowMinZoom,
        _autoFollowMaxZoom,
      );
      try {
        // use moveCamera inside animation for tight coupling & low jank
        _mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pos, zoom: zoom, tilt: 50, bearing: bearing),
          ),
        );
      } catch (_) {}
    }
  }

  // ---------------- Map & markers ----------------
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

  // ---------------- Polyline ----------------
  Future<void> _drawPolylineFromDriverToCustomer({
    required LatLng driverLatLng,
    required LatLng customerLatLng,
  }) async {
    if (_isDrawingPolyline) return;
    _isDrawingPolyline = true;

    final apiKey = ApiConsents.googleMapApiKey;
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
      debugPrint("❗ Error fetching directions: ${data['status']}");
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

  // ---------------- Math helpers ----------------
  double _lerp(double start, double end, double t) => start + (end - start) * t;

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

  double _normalizeAngle(double a) {
    a %= 360.0;
    if (a < 0) a += 360.0;
    return a;
  }

  // returns signed delta in [-180, +180] to go shortest way
  double _shortestAngleDelta(double from, double to) {
    double diff = _normalizeAngle(to) - _normalizeAngle(from);
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  // ---------------- Map callbacks ----------------
  void _onCameraMove(CameraPosition position) {
    _currentZoomLevel = position.zoom;
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    _startController.text = widget.pickupAddress;
    _destController.text = widget.destinationAddress;

    return NoInternetOverlay(
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
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
                    _autoFollowTimer = Timer(const Duration(seconds: 8), () {
                      _autoFollowEnabled = true;
                      _userInteractingWithMap = false;
                    });
                  },
                  onCameraMove: _onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target:
                        _currentPosition ?? const LatLng(9.9144908, 78.0970899),
                    zoom: _currentZoomLevel,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) async {
                    _mapController = controller;
                    String style = await DefaultAssetBundle.of(
                      context,
                    ).loadString('assets/map_style/map_style1.json');
                    _mapController?.setMapStyle(style);
                    _autoFollowEnabled = true; // Enable auto-follow on start
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
                top: 50,
                right: 15,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: AppColors.emergencyColor,
                  ),
                  child: CustomTextFields.textWithStyles600(
                    'Emergency',
                    color: AppColors.commonWhite,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                top: 350,
                right: 10,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),

              // ---------------- Bottom Sheet (unchanged UI, just kept intact) ----------------
              DraggableScrollableSheet(
                key: ValueKey(isDriverConfirmed),
                initialChildSize: isDriverConfirmed ? 0.65 : 0.5,
                minChildSize: 0.4,
                maxChildSize: isDriverConfirmed ? 0.9 : 0.80,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (!isDriverConfirmed && isWaitingForDriver) ...[
                          waitingForDriverUI(),
                        ] else if (!isDriverConfirmed && noDriverFound) ...[
                          noDriverFoundUI(),
                        ] else ...[
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
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Your trip has been cancelled",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
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

                          const SizedBox(height: 12),
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
                                    driverName,
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
                              const Spacer(),
                              Image.asset(
                                CARTYPE == 'sedan'
                                    ? AppImages.sedan
                                    : AppImages.luxuryCar,
                                height: 50,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: AppColors.containerColor1,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: () async {
                                      final phoneNumber = 'tel:$CUSTOMERPHONE';
                                      AppLogger.log.i(phoneNumber);
                                      final Uri url = Uri.parse(phoneNumber);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        debugPrint('Could not launch dialer');
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
                              const SizedBox(width: 10),

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
                                            'Message your driver',
                                            colors: AppColors.commonBlack,
                                          ),
                                          const Spacer(),
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
                          const SizedBox(height: 20),

                          // ----- Fare Box -----
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.commonWhite,
                              boxShadow: const [
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
                                            const Spacer(),
                                            otp.isEmpty
                                                ? const SizedBox.shrink()
                                                : Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                        color:
                                                            AppColors
                                                                .commonWhite,
                                                      ),
                                                ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: InkWell(
                                            onTap:
                                                () => setState(
                                                  () =>
                                                      isExpanded = !isExpanded,
                                                ),
                                            child: Row(
                                              children: [
                                                CustomTextFields.textWithStylesSmall(
                                                  'View Details',
                                                  colors:
                                                      AppColors
                                                          .changeButtonColor,
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
                                          transitionBuilder: (
                                            child,
                                            animation,
                                          ) {
                                            return SizeTransition(
                                              sizeFactor: animation,
                                              axisAlignment: -1,
                                              child: FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child:
                                              isExpanded
                                                  ? Column(
                                                    key: const ValueKey(
                                                      "expanded",
                                                    ),
                                                    children: [
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
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
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
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
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),

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
                                                                      (widget.baseFare ??
                                                                              0)
                                                                          .toString(),
                                                                  imagePath:
                                                                      AppImages
                                                                          .nBlackCurrency,
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                CustomTextFields.textWithStylesSmall(
                                                                  'Distance Fare',
                                                                ),
                                                                const Spacer(),
                                                                CustomTextFields.textWithImage(
                                                                  colors:
                                                                      AppColors
                                                                          .commonBlack,
                                                                  text:
                                                                      (widget.distanceFare ??
                                                                              0)
                                                                          .toString(),
                                                                  imagePath:
                                                                      AppImages
                                                                          .nBlackCurrency,
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                CustomTextFields.textWithStylesSmall(
                                                                  'Pickup Fare',
                                                                ),
                                                                const Spacer(),
                                                                CustomTextFields.textWithImage(
                                                                  colors:
                                                                      AppColors
                                                                          .commonBlack,
                                                                  text:
                                                                      (widget.pickupFare ??
                                                                              0)
                                                                          .toString(),
                                                                  imagePath:
                                                                      AppImages
                                                                          .nBlackCurrency,
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                CustomTextFields.textWithStylesSmall(
                                                                  'Booking Fee',
                                                                ),
                                                                const Spacer(),
                                                                CustomTextFields.textWithImage(
                                                                  colors:
                                                                      AppColors
                                                                          .commonBlack,
                                                                  text:
                                                                      (widget.bookingFee ??
                                                                              0)
                                                                          .toString(),
                                                                  imagePath:
                                                                      AppImages
                                                                          .nBlackCurrency,
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                CustomTextFields.textWithStylesSmall(
                                                                  'Time Fare',
                                                                ),
                                                                const Spacer(),
                                                                CustomTextFields.textWithImage(
                                                                  colors:
                                                                      AppColors
                                                                          .commonBlack,
                                                                  text:
                                                                      (widget.timeFare ??
                                                                              0)
                                                                          .toString(),
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
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                    ],
                                                  )
                                                  : const SizedBox.shrink(
                                                    key: ValueKey("collapsed"),
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: () {
                              print(widget.bookingId);
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder:
                              //         (context) => PaymentScreen(
                              //           bookingId: widget.bookingId,
                              //           amount: 1500,
                              //         ),
                              //   ),
                              // );
                            },
                            child: Container(
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
                          ),
                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
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
                                  controller: _startController,
                                  containerColor: AppColors.commonWhite,
                                  leadingImage: AppImages.circleStart,
                                  title: 'Search for an address or landmark',
                                  hintStyle: const TextStyle(fontSize: 11),
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
                                  controller: _destController,
                                  containerColor: AppColors.commonWhite,
                                  leadingImage: AppImages.rectangleDest,
                                  title: 'Enter destination',
                                  hintStyle: const TextStyle(fontSize: 11),
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
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        height: 24,
                                        child: VerticalDivider(
                                          color: Colors.grey,
                                          thickness: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      CustomTextFields.textWithImage(
                                        text: 'Support',
                                        fontWeight: FontWeight.w500,
                                        colors: AppColors.cancelRideColor,
                                        imagePath: AppImages.support,
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        height: 24,
                                        child: VerticalDivider(
                                          color: Colors.grey,
                                          thickness: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
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
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Small UI fragments ----------------
  Widget waitingForDriverUI() {
    return Column(
      children: [
        const Text(
          'Looking for the best drivers for you',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          borderRadius: BorderRadius.circular(10),
          minHeight: 7,
          backgroundColor: AppColors.linearIndicatorColor.withOpacity(0.2),
          color: AppColors.linearIndicatorColor,
        ),
        const SizedBox(height: 20),
        Image.asset(
          AppImages.confirmCar,
          height: 100,
          width: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
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
                hintStyle: const TextStyle(fontSize: 11),
                imgHeight: 17,
              ),
              const Divider(height: 0, color: AppColors.containerColor),
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
                hintStyle: const TextStyle(fontSize: 11),
                imgHeight: 17,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButtons.button(
          hasBorder: true,
          borderColor: AppColors.commonBlack.withOpacity(0.2),
          buttonColor: AppColors.commonWhite,
          textColor: AppColors.cancelRideColor,
          onTap: () {
            AppButtons.showCancelRideBottomSheet(
              context,
              onConfirmCancel: (String selectedReason) {
                driverSearchController.cancelRide(
                  bookingId: driverSearchController.carBooking.value!.bookingId,
                  selectedReason: selectedReason,
                  context: context,
                );
              },
            );
          },
          text: 'Cancel Ride',
        ),
      ],
    );
  }

  Widget noDriverFoundUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
          const SizedBox(height: 20),
          const Text(
            "No Drivers Found",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We couldn’t find any available drivers nearby.\nPlease try again in a few minutes.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          AppButtons.button(
            buttonColor: Colors.blue,
            textColor: Colors.white,
            text: "Try Again",
            onTap: () async {
              setState(() {
                isWaitingForDriver = true;
                noDriverFound = false;
              });

              final allData = driverSearchController.carBooking.value;
              String? result = await driverSearchController.sendDriverRequest(
                carType: widget.carType,
                pickupLatitude: allData?.fromLatitude ?? 0.0,
                pickupLongitude: allData?.fromLongitude ?? 0.0,
                dropLatitude: allData?.toLatitude ?? 0.0,
                dropLongitude: allData?.toLongitude ?? 0.0,
                bookingId: allData?.bookingId.toString() ?? '',
                context: context,
              );
              if (result != null) {
                startDriverSearch();
              }
            },
          ),
        ],
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:math' as math;
// import 'package:hopper/Core/Consents/app_texts.dart';
// import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
// import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
// import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
// import 'package:hopper/api/repository/api_consents.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:math';
//
// import 'package:flutter/foundation.dart';
// import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';
// import 'package:http/http.dart' as http;
//
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:hopper/Core/Consents/app_colors.dart';
// import 'package:hopper/Core/Utility/app_buttons.dart';
// import 'package:hopper/Core/Utility/app_images.dart';
// import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
// import 'package:hopper/uitls/websocket/socket_io_client.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:hopper/Core/Consents/app_logger.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:share_plus/share_plus.dart';
//
// class OrderConfirmScreen extends StatefulWidget {
//   final Map<String, dynamic> pickupData;
//   final Map<String, dynamic> destinationData;
//   final String pickupAddress;
//   final String bookingId;
//   final String carType;
//   final String destinationAddress;
//   final double? baseFare;
//   final double? serviceFare;
//   final double? distanceFare;
//   final double? pickupFare;
//   final double? bookingFee;
//   final double? timeFare;
//
//   const OrderConfirmScreen({
//     super.key,
//     required this.pickupData,
//     required this.bookingId,
//     required this.destinationData,
//     required this.carType,
//     required this.pickupAddress,
//     required this.destinationAddress,
//     this.baseFare,
//     this.serviceFare,
//     this.distanceFare,
//     this.pickupFare,
//     this.bookingFee,
//     this.timeFare,
//   });
//
//   @override
//   State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
// }
//
// class _OrderConfirmScreenState extends State<OrderConfirmScreen>
//     with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
//   @override
//   bool get wantKeepAlive => true;
//   bool isExpanded = false; // Track dropdown state
//   final TextEditingController _startController = TextEditingController();
//   final TextEditingController _destController = TextEditingController();
//   bool _isDrawingPolyline = false;
//   double _currentZoomLevel = 13.5; // Default zoom
//
//   bool isDriverConfirmed = false;
//   bool driverStartedRide = false;
//   bool destinationReached = false;
//   bool _autoFollowEnabled = false;
//   Timer? _autoFollowTimer;
//   String bookingId = ' ';
//   bool _userInteractingWithMap = false;
//   final socketService = SocketService();
//   GoogleMapController? _mapController;
//   LatLng? _pickedPosition;
//   double? _lastZoom;
//   final double _zoomThreshold = 0.01;
//   Marker? _driverMarker;
//   Set<Marker> _markers = {};
//   BitmapDescriptor? _carIcon;
//   BitmapDescriptor? _bikeIcon;
//   LatLng? _currentPosition;
//   LatLng? _customerLatLng;
//   LatLng? _customerToLatLang;
//   LatLng? _currentDriverLatLng;
//
//   String _address = 'Search...';
//   String plateNumber = '';
//   String driverName = '';
//   double driverRating = 0.0;
//   String carDetails = '';
//   String CUSTOMERPHONE = '';
//   String CARTYPE = '';
//   String otp = '';
//   double Amount = 0.0;
//   Set<Polyline> _polylines = {};
//   bool isTripCancelled = false;
//   String cancelReason = "";
//
//   Future<void> _loadCustomMarkers() async {
//     _carIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(52, 52)),
//       AppImages.movingCar,
//     );
//     _bikeIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(48, 48)),
//       AppImages.packageBike,
//     );
//   }
//
//   BitmapDescriptor _iconForVehicleType(String? type) {
//     final t = (type ?? '').toLowerCase();
//     switch (t) {
//       case 'bike':
//       case 'two_wheeler':
//       case '2w':
//       case 'motorbike':
//       case 'scooter':
//         return _bikeIcon ?? BitmapDescriptor.defaultMarker;
//       case 'car':
//       case 'sedan':
//       case 'hatchback':
//       case 'suv':
//       default:
//         return _carIcon ?? BitmapDescriptor.defaultMarker;
//     }
//   }
//
//   Future<void> _initLocation() async {
//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       _currentPosition = LatLng(position.latitude, position.longitude);
//     });
//     AppLogger.log.i(_currentPosition);
//   }
//
//   void _goToCurrentLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//
//     final latLng = LatLng(position.latitude, position.longitude);
//
//     _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
//   }
//
//   bool isWaitingForDriver = true;
//   bool noDriverFound = false;
//   void startDriverSearch() {
//     isWaitingForDriver = true;
//     noDriverFound = false;
//
//     Future.delayed(Duration(minutes: 1), () async {
//       if (!isDriverConfirmed) {
//         bool hasDriver = await driverSearchController.noDriverFound(
//           context: context,
//           bookingId: widget.bookingId,
//           status: true,
//         );
//
//         setState(() {
//           isWaitingForDriver = false;
//           noDriverFound = !hasDriver; // noDriverFound = true when no driver
//         });
//       }
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCustomMarkers().then((_) {
//       _setupSocketListeners();
//       _initLocation();
//       _goToCurrentLocation();
//     });
//     startDriverSearch();
//   }
//
//   void _setupSocketListeners() {
//     socketService.onConnect(() {
//       AppLogger.log.i("✅ Socket connected on booking screen");
//     });
//
//     socketService.on('joined-booking', (data) {
//       if (!mounted) return;
//       AppLogger.log.i("🚕 Joined booking data: $data");
//       final vehicle = data['vehicle'] ?? {};
//       final String driverId = data['driverId'] ?? '';
//       final String driverFullName = data['driverName'] ?? '';
//       final String customerPhone = data['customerPhone'].toString() ?? '';
//       final double rating =
//           double.tryParse(data['driverRating'].toString()) ?? 0.0;
//       final String color = vehicle['color'] ?? '';
//       final String model = vehicle['model'] ?? '';
//       final String brand = vehicle['brand'] ?? '';
//       final String serviceType = vehicle['serviceType'] ?? '';
//       final bool driverAccepted = data['driver_accept_status'] == true;
//       final String type = vehicle['type'] ?? '';
//       final String plate = vehicle['plateNumber'] ?? '';
//       final customerLoc = data['customerLocation'];
//       final amount = data['amount'];
//
//       _customerLatLng = LatLng(
//         customerLoc['fromLatitude'],
//         customerLoc['fromLongitude'],
//       );
//       _customerToLatLang = LatLng(
//         customerLoc['toLatitude'],
//         customerLoc['toLongitude'],
//       );
//
//       setState(() {
//         plateNumber = plate;
//         driverName = '$driverFullName ⭐ $rating';
//         carDetails = '$color - $brand';
//         isDriverConfirmed = driverAccepted;
//         CUSTOMERPHONE = customerPhone;
//         CARTYPE = serviceType;
//         Amount = amount;
//       });
//
//       AppLogger.log.i("🚕 Joined booking data: $data");
//       AppLogger.log.i("🚕 driverAccepted ==  $driverAccepted");
//
//       // Start real-time tracking
//       if (driverId.trim().isNotEmpty) {
//         AppLogger.log.i("📍 Tracking driver: $driverId");
//         socketService.emit('track-driver', {'driverId': driverId.trim()});
//       }
//     });
//
//     socketService.on('driver-location', (data) {
//       AppLogger.log.i('📦 driver-location-updated: $data');
//
//       final newDriverLatLng = LatLng(data['latitude'], data['longitude']);
//
//       if (_currentDriverLatLng == null) {
//         _currentDriverLatLng = newDriverLatLng;
//         _updateDriverMarker(newDriverLatLng, 0);
//         return;
//       }
//
//       // ✅ Animate movement
//       _animateCarTo(_currentDriverLatLng!, newDriverLatLng);
//
//       if (!driverStartedRide && _customerLatLng != null) {
//         _drawPolylineFromDriverToCustomer(
//           driverLatLng: newDriverLatLng,
//           customerLatLng: _customerLatLng!,
//         );
//       }
//
//       // ✅ CASE 2: After ride starts → Draw polyline to drop
//       if (driverStartedRide && _customerToLatLang != null) {
//         _drawPolylineFromDriverToCustomer(
//           driverLatLng: newDriverLatLng,
//           customerLatLng: _customerToLatLang!,
//         );
//       }
//
//       // ✅ Update current driver position
//       _currentDriverLatLng = newDriverLatLng;
//     });
//
//     socketService.on('driver-arrived', (data) {
//       AppLogger.log.i("driver-arrived: $data");
//     });
//
//     socketService.on('otp-generated', (data) {
//       if (!mounted) return;
//       final otpGenerated = data['otpCode'];
//       setState(() {
//         otp = otpGenerated;
//       });
//
//       AppLogger.log.i("otp-generated: $data");
//     });
//
//     socketService.on('ride-started', (data) {
//       final bool status = data['status'] == true;
//       AppLogger.log.i("ride-started: $data");
//
//       driverStartedRide = status; // don't wait for setState
//
//       if (!mounted) return;
//       setState(() {}); // only for UI like info card updates
//
//       if (status &&
//           _currentDriverLatLng != null &&
//           _customerToLatLang != null) {
//         final dropMarker = Marker(
//           markerId: const MarkerId("drop_marker"),
//           position: _customerToLatLang!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: const InfoWindow(title: "Destination"),
//         );
//
//         setState(() {
//           _markers = {if (_driverMarker != null) _driverMarker!, dropMarker};
//         });
//
//         _drawPolylineFromDriverToCustomer(
//           driverLatLng: _currentDriverLatLng!,
//           customerLatLng: _customerToLatLang!,
//         );
//       }
//     });
//     socketService.on('driver-reached-destination', (data) {
//       final String bookingId =
//           driverSearchController.carBooking.value!.bookingId;
//       final status = data['status'];
//       final amount = data['amount'];
//       if (status == true || status.toString() == 'status') {
//         if (!mounted) return;
//         setState(() {
//           destinationReached = true;
//         });
//         Future.delayed(const Duration(seconds: 2), () {
//           if (!mounted) return;
//           Get.to(() => PaymentScreen(bookingId: bookingId, amount: Amount));
//         });
//
//         AppLogger.log.i("driver_reached,$data");
//       }
//     });
//     socketService.on('customer-cancelled', (data) async {
//       AppLogger.log.i('customer-cancelled : $data');
//
//       if (data != null && data['status'] == true) {
//         if (!mounted) return;
//
//         setState(() {
//           isTripCancelled = true;
//           cancelReason =
//               data['reason'] ?? "Driver had to cancel due to an emergency";
//         });
//
//         // Optional: Automatically go back after showing UI for some time
//         await Future.delayed(const Duration(seconds: 3));
//         if (!mounted) return;
//         Get.offAll(() => HomeScreens());
//       }
//     });
//     socketService.on('driver-cancelled', (data) async {
//       AppLogger.log.i('driver-cancelled : $data');
//
//       if (data != null && data['status'] == true) {
//         if (!mounted) return;
//
//         setState(() {
//           isTripCancelled = true;
//           cancelReason =
//               data['reason'] ?? "Driver had to cancel due to an emergency";
//         });
//
//         // Optional: Automatically go back after showing UI for some time
//         await Future.delayed(const Duration(seconds: 3));
//         if (!mounted) return;
//         Get.offAll(() => HomeScreens());
//       }
//     });
//
//     // 🔶 Optional fallback (if using 'tracked-driver-location' too)
//     // socketService.on('tracked-driver-location', (data) {
//     //   AppLogger.log.i("📡 tracked-driver-location received: $data");
//     // });
//   }
//
//   void _updateDriverMarker(LatLng position, double bearing) {
//     final newMarker = Marker(
//       markerId: const MarkerId("driver_marker"),
//       position: position,
//       rotation: bearing,
//       icon: _iconForVehicleType(CARTYPE),
//       anchor: const Offset(0.5, 0.5),
//       flat: true,
//     );
//
//     setState(() {
//       _markers.removeWhere((m) => m.markerId.value == "driver_marker");
//       _markers.add(newMarker);
//       _driverMarker = newMarker;
//     });
//   }
//
//   Future<void> _animateCarTo(LatLng from, LatLng to) async {
//     if (!mounted || _mapController == null) return;
//
//     final distance = Geolocator.distanceBetween(
//       from.latitude,
//       from.longitude,
//       to.latitude,
//       to.longitude,
//     );
//     final steps = (distance / 5).ceil().clamp(30, 60);
//     final durationMs = 800;
//     final stepMs = (durationMs / steps).round();
//
//     double currentBearing = _driverMarker?.rotation ?? _getBearing(from, to);
//     double newBearing = _getBearing(from, to);
//
//     for (int i = 1; i <= steps; i++) {
//       if (!mounted) return;
//
//       await Future.delayed(Duration(milliseconds: stepMs));
//
//       final t = i / steps;
//       final lat = _lerp(from.latitude, to.latitude, t);
//       final lng = _lerp(from.longitude, to.longitude, t);
//       final intermediate = LatLng(lat, lng);
//
//       final bearing = _lerpAngle(currentBearing, newBearing, t);
//
//       _updateDriverMarker(intermediate, bearing);
//
//       if (_autoFollowEnabled) {
//         try {
//           _mapController?.animateCamera(
//             CameraUpdate.newCameraPosition(
//               CameraPosition(
//                 target: intermediate,
//                 zoom: _currentZoomLevel.clamp(15.0, 17.0),
//                 tilt: 50,
//                 bearing: bearing,
//               ),
//             ),
//           );
//         } catch (e) {
//           debugPrint("⛔ animateCamera error: $e");
//         }
//       }
//     }
//
//     _currentDriverLatLng = to;
//   }
//
//   double _lerp(double start, double end, double t) {
//     return start + (end - start) * t;
//   }
//
//   double _lerpAngle(double start, double end, double t) {
//     double difference = end - start;
//     if (difference.abs() > 180) {
//       if (end > start) {
//         start += 360;
//       } else {
//         end += 360;
//       }
//     }
//     return (start + (end - start) * t) % 360;
//   }
//
//   double _getBearing(LatLng start, LatLng end) {
//     final lat1 = start.latitude * math.pi / 180;
//     final lon1 = start.longitude * math.pi / 180;
//     final lat2 = end.latitude * math.pi / 180;
//     final lon2 = end.longitude * math.pi / 180;
//
//     final dLon = lon2 - lon1;
//     final y = math.sin(dLon) * math.cos(lat2);
//     final x =
//         math.cos(lat1) * math.sin(lat2) -
//         math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
//
//     final bearing = math.atan2(y, x);
//     return (bearing * 180 / math.pi + 360) % 360;
//   }
//
//   Future<void> _drawPolylineFromDriverToCustomer({
//     required LatLng driverLatLng,
//     required LatLng customerLatLng,
//   }) async {
//     if (_isDrawingPolyline) return;
//     _isDrawingPolyline = true;
//
//     String apiKey = ApiConsents.googleMapApiKey;
//
//     final url =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLatLng.latitude},${driverLatLng.longitude}&destination=${customerLatLng.latitude},${customerLatLng.longitude}&key=$apiKey';
//
//     final response = await http.get(Uri.parse(url));
//     final data = json.decode(response.body);
//     if (!mounted) return;
//     if (data['status'] == 'OK') {
//       final encoded = data['routes'][0]['overview_polyline']['points'];
//       final points = _decodePolyline(encoded);
//       if (!mounted) return;
//       setState(() {
//         _polylines = {
//           Polyline(
//             polylineId: PolylineId(
//               driverStartedRide ? "driver_to_drop" : "driver_to_pickup",
//             ),
//             points: points,
//             color: Colors.black,
//             width: 4,
//           ),
//         };
//       });
//     } else {
//       print("❗ Error fetching directions: ${data['status']}");
//     }
//     _isDrawingPolyline = false;
//   }
//
//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> points = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;
//
//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lat += dlat;
//
//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lng += dlng;
//
//       points.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//
//     return points;
//   }
//
//   final DriverSearchController driverSearchController = Get.put(
//     DriverSearchController(),
//   );
//   void _onCameraMove(CameraPosition position) {
//     _currentZoomLevel = position.zoom;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     _startController.text = widget.pickupAddress;
//     _destController.text = widget.destinationAddress;
//     super.build(context);
//     return WillPopScope(
//       onWillPop: () async {
//         return await false;
//       },
//       child: Scaffold(
//         body: Stack(
//           children: [
//             SizedBox(
//               height: 550,
//               width: double.infinity,
//               child: GoogleMap(
//                 compassEnabled: false,
//                 onCameraMoveStarted: () {
//                   _userInteractingWithMap = true;
//                   _autoFollowEnabled = false;
//
//                   _autoFollowTimer?.cancel();
//
//                   _autoFollowTimer = Timer(Duration(seconds: 10), () {
//                     _autoFollowEnabled = true;
//                     _userInteractingWithMap = false;
//                   });
//                 },
//                 onCameraMove: _onCameraMove,
//                 initialCameraPosition: CameraPosition(
//                   target: _currentPosition ?? LatLng(9.9144908, 78.0970899),
//                   zoom: _currentZoomLevel,
//                 ),
//                 markers: _markers,
//                 onMapCreated: (controller) async {
//                   _mapController = controller;
//                   String style = await DefaultAssetBundle.of(
//                     context,
//                   ).loadString('assets/map_style/map_style1.json');
//                   _mapController?.setMapStyle(style);
//
//                   _autoFollowEnabled = true; // Enable auto-follow
//                 },
//                 polylines: _polylines,
//                 myLocationEnabled: true,
//                 myLocationButtonEnabled: false,
//                 zoomControlsEnabled: false,
//                 gestureRecognizers: {
//                   Factory<OneSequenceGestureRecognizer>(
//                     () => EagerGestureRecognizer(),
//                   ),
//                 },
//               ),
//             ),
//
//             Positioned(
//               top: 350,
//               right: 10,
//               child: FloatingActionButton(
//                 mini: true,
//                 backgroundColor: Colors.white,
//                 onPressed: _goToCurrentLocation,
//                 child: Icon(Icons.my_location, color: Colors.black),
//               ),
//             ),
//
//             DraggableScrollableSheet(
//               key: ValueKey(isDriverConfirmed),
//               initialChildSize: isDriverConfirmed ? 0.65 : 0.5,
//               minChildSize: 0.4,
//               maxChildSize: isDriverConfirmed ? 0.9 : 0.80,
//               builder: (context, scrollController) {
//                 return Container(
//                   padding: EdgeInsets.symmetric(horizontal: 15),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(20),
//                     ),
//                   ),
//                   child: ListView(
//                     physics: BouncingScrollPhysics(),
//                     controller: scrollController,
//                     children: [
//                       Center(
//                         child: Container(
//                           width: 40,
//                           height: 4,
//                           margin: EdgeInsets.only(top: 8),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[400],
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       if (!isDriverConfirmed && isWaitingForDriver) ...[
//                         // Text(
//                         //   textAlign: TextAlign.center,
//                         //   'Looking for the best drivers for you',
//                         //   style: TextStyle(
//                         //     fontSize: 18,
//                         //     fontWeight: FontWeight.bold,
//                         //   ),
//                         // ),
//                         // SizedBox(height: 12),
//                         // LinearProgressIndicator(
//                         //   borderRadius: BorderRadius.circular(10),
//                         //   minHeight: 7,
//                         //   backgroundColor: AppColors.linearIndicatorColor
//                         //       .withOpacity(0.2),
//                         //   color: AppColors.linearIndicatorColor,
//                         // ),
//                         // SizedBox(height: 20),
//                         // Image.asset(
//                         //   AppImages.confirmCar,
//                         //   height: 100,
//                         //   width: 100,
//                         //   fit: BoxFit.contain,
//                         // ),
//                         // SizedBox(height: 20),
//                         // Container(
//                         //   decoration: BoxDecoration(
//                         //     color: Colors.white,
//                         //     borderRadius: BorderRadius.circular(12),
//                         //     boxShadow: [
//                         //       BoxShadow(
//                         //         color: Colors.black12,
//                         //         blurRadius: 8,
//                         //         offset: Offset(0, 4),
//                         //       ),
//                         //     ],
//                         //   ),
//                         //   child: Column(
//                         //     children: [
//                         //       CustomTextFields.plainTextField(
//                         //         readOnly: true,
//                         //         Style: TextStyle(
//                         //           fontSize: 12,
//                         //           color: AppColors.commonBlack.withOpacity(0.6),
//                         //           overflow: TextOverflow.ellipsis,
//                         //         ),
//                         //         controller: _startController,
//                         //         containerColor: AppColors.commonWhite,
//                         //         leadingImage: AppImages.circleStart,
//                         //         title: 'Search for an address or landmark',
//                         //         hintStyle: TextStyle(fontSize: 11),
//                         //         imgHeight: 17,
//                         //       ),
//                         //       const Divider(
//                         //         height: 0,
//                         //         color: AppColors.containerColor,
//                         //       ),
//                         //       CustomTextFields.plainTextField(
//                         //         readOnly: true,
//                         //         Style: TextStyle(
//                         //           fontSize: 12,
//                         //           color: AppColors.commonBlack.withOpacity(0.6),
//                         //           overflow: TextOverflow.ellipsis,
//                         //         ),
//                         //         controller: _destController,
//                         //         containerColor: AppColors.commonWhite,
//                         //         leadingImage: AppImages.rectangleDest,
//                         //         title: 'Enter destination',
//                         //         hintStyle: TextStyle(fontSize: 11),
//                         //         imgHeight: 17,
//                         //       ),
//                         //     ],
//                         //   ),
//                         // ),
//                         // SizedBox(height: 20),
//                         // AppButtons.button(
//                         //   hasBorder: true,
//                         //   borderColor: AppColors.commonBlack.withOpacity(0.2),
//                         //   buttonColor: AppColors.commonWhite,
//                         //   textColor: AppColors.cancelRideColor,
//                         //   onTap: () {
//                         //     // setState(() {
//                         //     //   isDriverConfirmed = !isDriverConfirmed;
//                         //     // });
//                         //     AppButtons.showCancelRideBottomSheet(
//                         //       context,
//                         //       onConfirmCancel: (String selectedReason) {
//                         //         driverSearchController.cancelRide(
//                         //           bookingId:
//                         //               driverSearchController
//                         //                   .carBooking
//                         //                   .value!
//                         //                   .bookingId,
//                         //           selectedReason: selectedReason,
//                         //           context: context,
//                         //         );
//                         //       },
//                         //     );
//                         //   },
//                         //   text: 'Cancel Ride',
//                         // ),
//                         waitingForDriverUI(),
//                       ] else if (!isDriverConfirmed && noDriverFound) ...[
//                         noDriverFoundUI(),
//                       ] else ...[
//                         if (isTripCancelled)
//                           Container(
//                             padding: const EdgeInsets.all(10),
//                             margin: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.red.shade50,
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.red.shade200),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.cancel, color: Colors.red),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         "Your trip has been cancelled",
//                                         style: TextStyle(
//                                           color: Colors.red,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         cancelReason,
//                                         style: const TextStyle(
//                                           color: Colors.red,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         else
//                           Center(
//                             child: CustomTextFields.textWithImage(
//                               fontSize: 20,
//                               imageSize: 24,
//                               fontWeight: FontWeight.w600,
//                               text:
//                                   destinationReached
//                                       ? 'Ride Completed'
//                                       : driverStartedRide
//                                       ? 'Ride in Progress'
//                                       : 'Your ride is confirmed',
//                               colors: AppColors.commonBlack,
//                               rightImagePath: AppImages.clrTick,
//                             ),
//                           ),
//
//                         SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Column(
//                               spacing: 5,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 CustomTextFields.textWithStylesSmall(
//                                   plateNumber,
//                                   colors: AppColors.commonBlack,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 CustomTextFields.textWithStylesSmall(
//                                   '${driverName}',
//                                   colors: AppColors.commonBlack,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 CustomTextFields.textWithStylesSmall(
//                                   carDetails,
//                                   fontSize: 12,
//                                   colors: AppColors.carTypeColor,
//                                 ),
//                               ],
//                             ),
//                             Spacer(),
//                             Image.asset(
//                               CARTYPE == 'sedan'
//                                   ? AppImages.sedan
//                                   : AppImages.luxuryCar,
//                               height: 50,
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: 20),
//                         Row(
//                           children: [
//                             Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(50),
//                                 color: AppColors.containerColor1,
//                               ),
//
//                               child: Padding(
//                                 padding: EdgeInsets.all(8.0),
//                                 child: InkWell(
//                                   onTap: () async {
//                                     final phoneNumber = 'tel:$CUSTOMERPHONE';
//                                     AppLogger.log.i(phoneNumber);
//                                     final Uri url = Uri.parse(phoneNumber);
//                                     if (await canLaunchUrl(url)) {
//                                       await launchUrl(url);
//                                     } else {
//                                       print('Could not launch dialer');
//                                     }
//                                   },
//                                   child: Image.asset(
//                                     AppImages.call,
//
//                                     height: 20,
//                                     width: 20,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 10),
//
//                             Expanded(
//                               child: InkWell(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder:
//                                           (context) => ChatScreen(
//                                             bookingId:
//                                                 driverSearchController
//                                                     .carBooking
//                                                     .value!
//                                                     .bookingId,
//                                           ),
//                                     ),
//                                   );
//                                 },
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(20),
//                                     color: AppColors.containerColor1,
//                                   ),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Row(
//                                       children: [
//                                         CustomTextFields.textWithStylesSmall(
//                                           colors: AppColors.commonBlack,
//                                           'Message your driver',
//                                         ),
//                                         Spacer(),
//                                         Image.asset(
//                                           AppImages.send,
//                                           height: 16,
//                                           width: 16,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: 20),
//                         Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.commonWhite,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black12,
//                                 blurRadius: 8,
//                                 offset: Offset(0, 4),
//                               ),
//                             ],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.only(top: 20),
//                             child: Column(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       Row(
//                                         children: [
//                                           CustomTextFields.textWithImage(
//                                             fontWeight: FontWeight.w700,
//                                             fontSize: 16,
//                                             colors: AppColors.commonBlack,
//                                             text: 'Total Fare',
//                                             rightImagePath:
//                                                 AppImages.nBlackCurrency,
//                                             rightImagePathText: ' $Amount',
//                                           ),
//
//                                           Spacer(),
//                                           otp == ''
//                                               ? SizedBox.shrink()
//                                               : Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                   horizontal: 10,
//                                                   vertical: 6,
//                                                 ),
//                                                 decoration: BoxDecoration(
//                                                   borderRadius:
//                                                       BorderRadius.circular(6),
//                                                   color:
//                                                       AppColors
//                                                           .userChatContainerColor,
//                                                 ),
//                                                 child:
//                                                     CustomTextFields.textWithStyles600(
//                                                       'OTP - $otp',
//                                                       fontSize: 16,
//                                                       color:
//                                                           AppColors.commonWhite,
//                                                     ),
//                                               ),
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8.0,
//                                         ),
//                                         child: InkWell(
//                                           onTap: () {
//                                             setState(() {
//                                               isExpanded = !isExpanded;
//                                             });
//                                           },
//                                           child: Row(
//                                             children: [
//                                               CustomTextFields.textWithStylesSmall(
//                                                 'View Details',
//                                                 colors:
//                                                     AppColors.changeButtonColor,
//                                                 fontSize: 13,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                               const SizedBox(width: 10),
//                                               AnimatedRotation(
//                                                 turns: isExpanded ? 0.5 : 0,
//                                                 duration: const Duration(
//                                                   milliseconds: 300,
//                                                 ),
//                                                 child: Image.asset(
//                                                   AppImages.dropDown,
//                                                   height: 16,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//
//                                       AnimatedSwitcher(
//                                         duration: const Duration(
//                                           milliseconds: 300,
//                                         ),
//                                         switchInCurve: Curves.easeInOut,
//                                         switchOutCurve: Curves.easeInOut,
//                                         transitionBuilder: (child, animation) {
//                                           return SizeTransition(
//                                             sizeFactor: animation,
//                                             axisAlignment:
//                                                 -1, // expand downwards
//                                             child: FadeTransition(
//                                               opacity: animation,
//                                               child: child,
//                                             ),
//                                           );
//                                         },
//                                         child:
//                                             isExpanded
//                                                 ? Column(
//                                                   key: const ValueKey(
//                                                     "expanded",
//                                                   ),
//                                                   children: [
//                                                     const SizedBox(height: 10),
//
//                                                     Container(
//                                                       margin:
//                                                           const EdgeInsets.only(
//                                                             top: 10,
//                                                           ),
//                                                       padding:
//                                                           const EdgeInsets.all(
//                                                             10,
//                                                           ),
//                                                       decoration: BoxDecoration(
//                                                         border: Border.all(
//                                                           color: AppColors
//                                                               .commonBlack
//                                                               .withOpacity(0.1),
//                                                         ),
//                                                         borderRadius:
//                                                             BorderRadius.circular(
//                                                               8,
//                                                             ),
//                                                       ),
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .start,
//                                                         children: [
//                                                           const Text(
//                                                             "Fare Breakdown",
//                                                             style: TextStyle(
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                             height: 5,
//                                                           ),
//
//                                                           /// Base fare
//                                                           Row(
//                                                             children: [
//                                                               CustomTextFields.textWithStylesSmall(
//                                                                 'Base Fare',
//                                                               ),
//                                                               const Spacer(),
//                                                               CustomTextFields.textWithImage(
//                                                                 colors:
//                                                                     AppColors
//                                                                         .commonBlack,
//                                                                 text:
//                                                                     widget
//                                                                         .baseFare
//                                                                         .toString() ??
//                                                                     '0',
//                                                                 imagePath:
//                                                                     AppImages
//                                                                         .nBlackCurrency,
//                                                               ),
//                                                             ],
//                                                           ),
//
//                                                           Row(
//                                                             children: [
//                                                               CustomTextFields.textWithStylesSmall(
//                                                                 'Distance Fare',
//                                                               ),
//                                                               const Spacer(),
//                                                               CustomTextFields.textWithImage(
//                                                                 colors:
//                                                                     AppColors
//                                                                         .commonBlack,
//                                                                 text:
//                                                                     widget
//                                                                         .distanceFare
//                                                                         .toString() ??
//                                                                     '0',
//                                                                 imagePath:
//                                                                     AppImages
//                                                                         .nBlackCurrency,
//                                                               ),
//                                                             ],
//                                                           ),
//                                                           Row(
//                                                             children: [
//                                                               CustomTextFields.textWithStylesSmall(
//                                                                 'Pickup Fare',
//                                                               ),
//                                                               const Spacer(),
//                                                               CustomTextFields.textWithImage(
//                                                                 colors:
//                                                                     AppColors
//                                                                         .commonBlack,
//                                                                 text:
//                                                                     widget
//                                                                         .pickupFare
//                                                                         .toString() ??
//                                                                     '0',
//                                                                 imagePath:
//                                                                     AppImages
//                                                                         .nBlackCurrency,
//                                                               ),
//                                                             ],
//                                                           ),
//                                                           Row(
//                                                             children: [
//                                                               CustomTextFields.textWithStylesSmall(
//                                                                 'Booking Fee',
//                                                               ),
//                                                               const Spacer(),
//                                                               CustomTextFields.textWithImage(
//                                                                 colors:
//                                                                     AppColors
//                                                                         .commonBlack,
//                                                                 text:
//                                                                     widget
//                                                                         .bookingFee
//                                                                         .toString() ??
//                                                                     '0',
//                                                                 imagePath:
//                                                                     AppImages
//                                                                         .nBlackCurrency,
//                                                               ),
//                                                             ],
//                                                           ),
//                                                           Row(
//                                                             children: [
//                                                               CustomTextFields.textWithStylesSmall(
//                                                                 'Time Fare',
//                                                               ),
//                                                               const Spacer(),
//                                                               CustomTextFields.textWithImage(
//                                                                 colors:
//                                                                     AppColors
//                                                                         .commonBlack,
//                                                                 text:
//                                                                     widget
//                                                                         .timeFare
//                                                                         .toString() ??
//                                                                     '0',
//                                                                 imagePath:
//                                                                     AppImages
//                                                                         .nBlackCurrency,
//                                                               ),
//                                                             ],
//                                                           ),
//
//                                                           const SizedBox(
//                                                             height: 10,
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 10),
//                                                   ],
//                                                 )
//                                                 : const SizedBox.shrink(
//                                                   key: ValueKey("collapsed"),
//                                                 ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(height: 5),
//
//                                 // Divider(color: AppColors.containerColor),
//
//                                 /*ListTile(
//                                   leading: Image.asset(
//                                     AppImages.cash,
//                                     height: 24,
//                                     width: 24,
//                                   ),
//                                   title: CustomTextFields.textWithStylesSmall(
//                                     "Cash Payment",
//                                     fontSize: 15,
//                                     colors: AppColors.commonBlack,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//
//                                   trailing: Container(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 5,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(5),
//                                       color: AppColors.resendBlue.withOpacity(
//                                         0.1,
//                                       ),
//                                     ),
//                                     child: CustomTextFields.textWithStyles600(
//                                       fontSize: 10,
//                                       color: AppColors.changeButtonColor,
//                                       'Change',
//                                     ),
//                                   ),
//                                   onTap: () {},
//                                 ),
//                                 ListTile(
//                                   leading: Image.asset(
//                                     AppImages.digiPay,
//                                     height: 32,
//                                     width: 32,
//                                   ),
//                                   title: CustomTextFields.textWithStylesSmall(
//                                     "Pay using card, UPI & more",
//                                     fontSize: 15,
//                                     colors: AppColors.commonBlack,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//
//                                   subtitle: CustomTextFields.textWithStylesSmall(
//                                     'Pay during the ride to avoid cash payments',
//                                     fontSize: 10,
//                                   ),
//                                   trailing: Image.asset(
//                                     AppImages.rightArrow,
//                                     height: 20,
//                                     color: AppColors.commonBlack,
//                                     width: 20,
//                                   ),
//                                   onTap: () {
//                                     final String bookingId =
//                                         driverSearchController
//                                             .carBooking
//                                             .value!
//                                             .bookingId;
//                                     print(bookingId);
//                                     Get.to(
//                                       () => PaymentScreen(
//                                         bookingId: bookingId,
//                                         amount: Amount,
//                                       ),
//                                     );
//                                   },
//                                 ),*/
//                               ],
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         GestureDetector(
//                           onTap: () {
//                             // Navigator.push(
//                             //   context,
//                             //   MaterialPageRoute(
//                             //     builder:
//                             //         (context) => PaymentScreen(
//                             //           bookingId: widget.bookingId,
//                             //           amount: 1500,
//                             //         ),
//                             //   ),
//                             // );
//                           },
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: AppColors.containerColor1,
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(15),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 spacing: 5,
//                                 children: [
//                                   CustomTextFields.textWithStyles600(
//                                     'Directions to reach',
//                                     fontSize: 14,
//                                   ),
//                                   CustomTextFields.textWithStylesSmall(
//                                     'Help your driver partner reach you faster',
//                                     fontSize: 12,
//                                   ),
//                                   CustomTextFields.textWithStylesSmall(
//                                     'Add Direction',
//                                     fontSize: 12,
//                                     colors: AppColors.resendBlue,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black12,
//                                 blurRadius: 8,
//                                 offset: Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               CustomTextFields.plainTextField(
//                                 readOnly: true,
//                                 Style: TextStyle(
//                                   fontSize: 12,
//                                   color: AppColors.commonBlack.withOpacity(0.6),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 controller: _startController,
//                                 containerColor: AppColors.commonWhite,
//                                 leadingImage: AppImages.circleStart,
//                                 title: 'Search for an address or landmark',
//                                 hintStyle: TextStyle(fontSize: 11),
//                                 imgHeight: 17,
//                               ),
//                               const Divider(
//                                 height: 0,
//                                 color: AppColors.containerColor,
//                               ),
//                               CustomTextFields.plainTextField(
//                                 readOnly: true,
//                                 Style: TextStyle(
//                                   fontSize: 12,
//                                   color: AppColors.commonBlack.withOpacity(0.6),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 controller: _destController,
//                                 containerColor: AppColors.commonWhite,
//                                 leadingImage: AppImages.rectangleDest,
//                                 title: 'Enter destination',
//                                 hintStyle: TextStyle(fontSize: 11),
//                                 imgHeight: 17,
//                               ),
//                               const Divider(
//                                 height: 0,
//                                 color: AppColors.containerColor,
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 15,
//                                   vertical: 15,
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     CustomTextFields.textWithImage(
//                                       onTap:
//                                           otp.isNotEmpty
//                                               ? null
//                                               : () {
//                                                 // setState(() {
//                                                 //   isDriverConfirmed = !isDriverConfirmed;
//                                                 // });
//                                                 AppButtons.showCancelRideBottomSheet(
//                                                   context,
//                                                   onConfirmCancel: (
//                                                     String selectedReason,
//                                                   ) {
//                                                     driverSearchController
//                                                         .cancelRide(
//                                                           bookingId:
//                                                               driverSearchController
//                                                                   .carBooking
//                                                                   .value!
//                                                                   .bookingId,
//                                                           selectedReason:
//                                                               selectedReason,
//                                                           context: context,
//                                                         );
//                                                   },
//                                                 );
//                                               },
//                                       text:
//                                           otp.isNotEmpty
//                                               ? 'Ratings'
//                                               : ' Cancel Ride',
//                                       fontWeight: FontWeight.w500,
//                                       colors: AppColors.cancelRideColor,
//                                       imagePath:
//                                           otp.isNotEmpty
//                                               ? null
//                                               : AppImages.cancel,
//                                     ),
//                                     SizedBox(width: 10),
//                                     Container(
//                                       height: 24, // Set the height you need
//                                       child: VerticalDivider(
//                                         color: Colors.grey,
//                                         thickness: 1,
//                                       ),
//                                     ),
//                                     SizedBox(width: 10),
//                                     CustomTextFields.textWithImage(
//                                       text: 'Support',
//                                       fontWeight: FontWeight.w500,
//                                       colors: AppColors.cancelRideColor,
//                                       imagePath: AppImages.support,
//                                     ),
//
//                                     SizedBox(width: 10),
//                                     Container(
//                                       height: 24,
//                                       child: VerticalDivider(
//                                         color: Colors.grey,
//                                         thickness: 1,
//                                       ),
//                                     ),
//                                     SizedBox(width: 10),
//                                     CustomTextFields.textWithImage(
//                                       onTap: () {
//                                         final String bookingId =
//                                             driverSearchController
//                                                 .carBooking
//                                                 .value!
//                                                 .bookingId;
//                                         final url =
//                                             "https://hoppr-admin-e7bebfb9fb05.herokuapp.com/ride-tracker/$bookingId";
//                                         Share.share(url);
//                                       },
//                                       text: 'Share',
//                                       fontWeight: FontWeight.w500,
//                                       colors: AppColors.cancelRideColor,
//                                       imagePath: AppImages.support,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                       ],
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget waitingForDriverUI() {
//     return Column(
//       children: [
//         Text(
//           textAlign: TextAlign.center,
//           'Looking for the best drivers for you',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 12),
//         LinearProgressIndicator(
//           borderRadius: BorderRadius.circular(10),
//           minHeight: 7,
//           backgroundColor: AppColors.linearIndicatorColor.withOpacity(0.2),
//           color: AppColors.linearIndicatorColor,
//         ),
//         SizedBox(height: 20),
//         Image.asset(
//           AppImages.confirmCar,
//           height: 100,
//           width: 100,
//           fit: BoxFit.contain,
//         ),
//         SizedBox(height: 20),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 8,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               CustomTextFields.plainTextField(
//                 readOnly: true,
//                 Style: TextStyle(
//                   fontSize: 12,
//                   color: AppColors.commonBlack.withOpacity(0.6),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 controller: _startController,
//                 containerColor: AppColors.commonWhite,
//                 leadingImage: AppImages.circleStart,
//                 title: 'Search for an address or landmark',
//                 hintStyle: TextStyle(fontSize: 11),
//                 imgHeight: 17,
//               ),
//               const Divider(height: 0, color: AppColors.containerColor),
//               CustomTextFields.plainTextField(
//                 readOnly: true,
//                 Style: TextStyle(
//                   fontSize: 12,
//                   color: AppColors.commonBlack.withOpacity(0.6),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 controller: _destController,
//                 containerColor: AppColors.commonWhite,
//                 leadingImage: AppImages.rectangleDest,
//                 title: 'Enter destination',
//                 hintStyle: TextStyle(fontSize: 11),
//                 imgHeight: 17,
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 20),
//         AppButtons.button(
//           hasBorder: true,
//           borderColor: AppColors.commonBlack.withOpacity(0.2),
//           buttonColor: AppColors.commonWhite,
//           textColor: AppColors.cancelRideColor,
//           onTap: () {
//             // setState(() {
//             //   isDriverConfirmed = !isDriverConfirmed;
//             // });
//             AppButtons.showCancelRideBottomSheet(
//               context,
//               onConfirmCancel: (String selectedReason) {
//                 driverSearchController.cancelRide(
//                   bookingId: driverSearchController.carBooking.value!.bookingId,
//                   selectedReason: selectedReason,
//                   context: context,
//                 );
//               },
//             );
//           },
//           text: 'Cancel Ride',
//         ),
//       ],
//     );
//   }
//
//   Widget noDriverFoundUI() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
//           const SizedBox(height: 20),
//           const Text(
//             "No Drivers Found",
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.redAccent,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             "We couldn’t find any available drivers nearby.\nPlease try again in a few minutes.",
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           const SizedBox(height: 30),
//           AppButtons.button(
//             buttonColor: Colors.blue,
//             textColor: Colors.white,
//             text: "Try Again",
//             onTap: () async {
//               setState(() {
//                 isWaitingForDriver = true;
//                 noDriverFound = false;
//               });
//
//               final allData = driverSearchController.carBooking.value;
//               setState(() {
//                 isWaitingForDriver = true;
//                 noDriverFound = false;
//               });
//               String? result = await driverSearchController.sendDriverRequest(
//                 carType: widget.carType ?? '',
//                 pickupLatitude: allData?.fromLatitude ?? 0.0,
//                 pickupLongitude: allData?.fromLongitude ?? 0.0,
//                 dropLatitude: allData?.toLatitude ?? 0.0,
//                 dropLongitude: allData?.toLongitude ?? 0.0,
//                 bookingId: allData?.bookingId.toString() ?? '',
//                 context: context,
//               );
//               if (result != null) {
//                 startDriverSearch();
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
