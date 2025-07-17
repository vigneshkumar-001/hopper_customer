import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
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

  bool isDriverConfirmed = false;
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
  LatLng? _currentDriverLatLng;

  String _address = 'Search...';
  String plateNumber = '';
  String driverName = '';
  double driverRating = 0.0;
  String carDetails = '';
  Set<Polyline> _polylines = {};

  Future<void> _loadCustomMarker() async {
    _carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      AppImages.movingCar,
    );
  }

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

  /*  @override
  void initState() {
    super.initState();
    socketService.onConnect(() {
      AppLogger.log.i("✅ Socket connected on booking screen");
    });

    // Listen for driver accepted
    socketService.on('driver-accepted', (data) {
      if (!mounted) return;

      final String bookingId = data['bookingId'] ?? '';
      final String status = data['status'] ?? '';
      final String driverId = data['driverId'] ?? '';
      final String userId = data['userId'] ?? '';

      AppLogger.log.i("👉 status: $status");
      AppLogger.log.i(
        "✅ Driver accepted: bookingId=$bookingId, driverId=$driverId, userId=$userId,status=$status",
      );
      if (status == "SUCCESS") {
        AppLogger.log.i("🎉 Driver accepted the ride!");
      }

      // Emit join-booking after driver accepts
      socketService.emit('join-booking', {
        'bookingId': bookingId,
        'userId': driverId,
      });
    });

    // ✅ Correct Flutter way to handle joined-booking event
    socketService.on('joined-booking', (data) {
      if (!mounted) return;

      final vehicle = data['vehicle'] ?? {};
      final String driverId = data['driverId'] ?? '';
      final String driverFullName = data['driverName'] ?? '';
      final double rating =
          double.tryParse(data['driverRating'].toString()) ?? 0.0;
      final String color = vehicle['color'] ?? '';
      final String model = vehicle['model'] ?? '';
      final bool driverAccepted = data['driver_accept_status'] == true;
      final String type = vehicle['type'] ?? '';
      final String plate = vehicle['plateNumber'] ?? '';
      final driverLoc = data['driverLocation'];
      final customerLoc = data['customerLocation'];

      final driverLatLng = LatLng(
        driverLoc['latitude'],
        driverLoc['longitude'],
      );

      final customerLatLng = LatLng(
        customerLoc['fromLatitude'],
        customerLoc['fromLongitude'],
      );

      // _drawPolylineFromDriverToCustomer(
      //   driverLatLng: driverLatLng,
      //   customerLatLng: customerLatLng,
      // );
      _driverMarker = Marker(
        markerId: const MarkerId("driver_marker"),
        position: driverLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      setState(() {
        plateNumber = plate;
        driverName = '$driverFullName ⭐ $rating';
        carDetails = '$color - $type $model';
        isDriverConfirmed = driverAccepted;
        _markers.add(_driverMarker!);
      });
      AppLogger.log.i("🚕 Joined booking data: $data");
      AppLogger.log.i("🚕 driverAccepted ==  $driverAccepted");

      // You can store joined bookings in your local state if needed
      // Example: _joinedBookingIds.add(bookingId);

      if (driverId != null && driverId.trim().isNotEmpty) {
        AppLogger.log.i("📍 Tracking driver: $driverId");
        socketService.emit('track-driver', {'driverId': driverId.trim()});
      }
    });
    socketService.on('tracked-driver-location', (data) {
      if (!mounted) return;

      final updatedDriverLatLng = LatLng(data['latitude'], data['longitude']);
      _drawPolylineFromDriverToCustomer(
        driverLatLng: updatedDriverLatLng,
        customerLatLng: _customerLatLng!,
      );

      _driverMarker = _driverMarker!.copyWith(
        positionParam: updatedDriverLatLng,
      );
      setState(() {
        _markers
          ..removeWhere((m) => m.markerId == const MarkerId("driver_marker"))
          ..add(_driverMarker!);
      });
      // Optional: check if the location has changed meaningfully
      if (_currentDriverLatLng != null &&
          _currentDriverLatLng == updatedDriverLatLng) {
        return;
      }

      _currentDriverLatLng = updatedDriverLatLng;

      // Redraw polyline from updated driver location to customer
      _drawPolylineFromDriverToCustomer(
        driverLatLng: updatedDriverLatLng,
        customerLatLng: _customerLatLng!,
      );
    });
    socketService.on('driver-location', (data) {
      AppLogger.log.i('📦 driver-location-updated: $data');
    });
    _initLocation();
    _goToCurrentLocation();
  }*/
  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    socketService.onConnect(() {
      AppLogger.log.i("✅ Socket connected on booking screen");
    });

    // 🔶 Step 1: Driver Accepted
    socketService.on('driver-accepted', (data) {
      if (!mounted) return;

      final String bookingId = data['bookingId'] ?? '';
      final String status = data['status'] ?? '';
      final String driverId = data['driverId'] ?? '';

      AppLogger.log.i(
        "✅ Driver accepted: bookingId=$bookingId, driverId=$driverId, status=$status",
      );

      if (status == "SUCCESS" && driverId.trim().isNotEmpty) {
        socketService.emit('join-booking', {
          'bookingId': bookingId,
          'userId': driverId,
        });
      }
    });

    socketService.on('joined-booking', (data) {
      if (!mounted) return;

      final vehicle = data['vehicle'] ?? {};
      final String driverId = data['driverId'] ?? '';
      final String driverFullName = data['driverName'] ?? '';
      final double rating =
          double.tryParse(data['driverRating'].toString()) ?? 0.0;
      final String color = vehicle['color'] ?? '';
      final String model = vehicle['model'] ?? '';
      final bool driverAccepted = data['driver_accept_status'] == true;
      final String type = vehicle['type'] ?? '';
      final String plate = vehicle['plateNumber'] ?? '';
      final customerLoc = data['customerLocation'];

      _customerLatLng = LatLng(
        customerLoc['fromLatitude'],
        customerLoc['fromLongitude'],
      );

      setState(() {
        plateNumber = plate;
        driverName = '$driverFullName ⭐ $rating';
        carDetails = '$color - $type $model';
        isDriverConfirmed = driverAccepted;
      });

      AppLogger.log.i("🚕 Joined booking data: $data");
      AppLogger.log.i("🚕 driverAccepted ==  $driverAccepted");

      // Start real-time tracking
      if (driverId.trim().isNotEmpty) {
        AppLogger.log.i("📍 Tracking driver: $driverId");
        socketService.emit('track-driver', {'driverId': driverId.trim()});
      }
    });

    // socketService.on('joined-booking', (data) {
    //   if (!mounted) return;
    //
    //   final vehicle = data['vehicle'] ?? {};
    //   final String driverId = data['driverId'] ?? '';
    //   final String driverNameStr = data['driverName'] ?? '';
    //   final double rating = double.tryParse(data['driverRating'].toString()) ?? 0.0;
    //   final String color = vehicle['color'] ?? '';
    //   final String model = vehicle['model'] ?? '';
    //   final String type = vehicle['type'] ?? '';
    //   final String plate = vehicle['plateNumber'] ?? '';
    //   final bool driverAccepted = data['driver_accept_status'] == true;
    //   final driverLoc = data['driverLocation'];
    //   final customerLoc = data['customerLocation'];
    //
    //   final LatLng driverLatLng = LatLng(
    //     driverLoc['latitude'],
    //     driverLoc['longitude'],
    //   );
    //
    //   final LatLng customerLatLng = LatLng(
    //     customerLoc['fromLatitude'],
    //     customerLoc['fromLongitude'],
    //   );
    //
    //   _customerLatLng = customerLatLng;
    //   _currentDriverLatLng = driverLatLng;
    //
    //   _driverMarker = Marker(
    //     markerId: const MarkerId("driver_marker"),
    //     position: driverLatLng,
    //     icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    //
    //   );
    //
    //   setState(() {
    //     plateNumber = plate;
    //     driverName = '$driverNameStr ⭐ $rating';
    //     carDetails = '$color - $type $model';
    //     isDriverConfirmed = driverAccepted;
    //     _markers.add(_driverMarker!);
    //   });
    //
    //   _drawPolylineFromDriverToCustomer(
    //     driverLatLng: driverLatLng,
    //     customerLatLng: customerLatLng,
    //   );
    //
    //   if (driverId.trim().isNotEmpty) {
    //     AppLogger.log.i("📍 Start tracking driver: $driverId");
    //     socketService.emit('track-driver', {'driverId': driverId.trim()});
    //   }
    // });

    // 🔶 Step 3: Real-Time Driver Location Update
    // 🔶 Step 3: Real-Time Driver Location Update
    socketService.on('driver-location', (data) {
      AppLogger.log.i('📦 driver-location-updated: $data');

      final newDriverLatLng = LatLng(data['latitude'], data['longitude']);

      if (_currentDriverLatLng == null) {
        // First time assigning driver's current location
        _currentDriverLatLng = newDriverLatLng;

        _updateDriverMarker(newDriverLatLng, 0);
        return;
      }

      // Animate movement and rotation
      _animateCarTo(_currentDriverLatLng!, newDriverLatLng);
    });

    // 🔶 Optional fallback (if using 'tracked-driver-location' too)
    socketService.on('tracked-driver-location', (data) {
      AppLogger.log.i("📡 tracked-driver-location received: $data");
    });

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

    setState(() {
      _markers
        ..removeWhere((m) => m.markerId == const MarkerId("driver_marker"))
        ..add(_driverMarker!);
    });
  }

  Future<void> _animateCarTo(LatLng from, LatLng to) async {
    const steps = 20;
    const duration = Duration(milliseconds: 800);
    final interval = duration.inMilliseconds ~/ steps;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: interval));

      final lat = _lerp(from.latitude, to.latitude, i / steps);
      final lng = _lerp(from.longitude, to.longitude, i / steps);
      final intermediate = LatLng(lat, lng);

      double bearing = _getBearing(from, intermediate);

      _updateDriverMarker(intermediate, bearing);
    }

    _currentDriverLatLng = to;

    if (_customerLatLng != null) {
      _drawPolylineFromDriverToCustomer(
        driverLatLng: _currentDriverLatLng!,
        customerLatLng: _customerLatLng!,
      );
    }
  }

  double _getBearing(LatLng from, LatLng to) {
    double lat1 = from.latitude * (pi / 180);
    double lon1 = from.longitude * (pi / 180);
    double lat2 = to.latitude * (pi / 180);
    double lon2 = to.longitude * (pi / 180);

    double dLon = lon2 - lon1;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x);

    // Convert to degrees and normalize to 0-360
    return (bearing * (180 / pi) + 360) % 360;
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  Future<void> _drawPolylineFromDriverToCustomer({
    required LatLng driverLatLng,
    required LatLng customerLatLng,
  }) async {
    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLatLng.latitude},${driverLatLng.longitude}&destination=${customerLatLng.latitude},${customerLatLng.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final encoded = data['routes'][0]['overview_polyline']['points'];
      final points = _decodePolyline(encoded);

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("driver_to_customer"),
            points: points,
            color: Colors.black,
            width: 4,
          ),
        };
      });
    } else {
      print("❗ Error fetching directions: ${data['status']}");
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
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
                              leadingImage: AppImages.dart,
                              title: 'Search for an address or landmark',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
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
                              leadingImage: AppImages.dart,
                              title: 'Enter destination',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
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
                          setState(() {
                            isDriverConfirmed = !isDriverConfirmed;
                          });
                        },
                        text: 'Cancel Ride',
                      ),
                    ] else ...[
                      Center(
                        child: CustomTextFields.textWithImage(
                          fontSize: 20,
                          imageSize: 24,
                          fontWeight: FontWeight.w600,
                          text: 'Your ride is confirmed',
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
                                'Black color - Toyota Corolla',
                                fontSize: 12,
                                colors: AppColors.carTypeColor,
                              ),
                            ],
                          ),
                          Spacer(),
                          Image.asset(AppImages.confirmCar, height: 50),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            CustomTextFields.textWithImage(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              colors: AppColors.commonBlack,
                              text: 'Total Fare',
                              rightImagePath: AppImages.nBlackCurrency,
                              rightImagePathText: ' 73',
                            ),

                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.orange[100],
                              ),
                              child: Text(
                                "KJA978AZ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

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
                            color: AppColors.resendBlue.withOpacity(0.2),
                          ),
                          child: Text('Change'),
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
                        onTap: () {},
                      ),
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
                              leadingImage: AppImages.dart,
                              title: 'Search for an address or landmark',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
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
                              leadingImage: AppImages.dart,
                              title: 'Enter destination',
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
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
                                children: [
                                  CustomTextFields.textWithImage(
                                    onTap: () {
                                      setState(() {
                                        isDriverConfirmed = !isDriverConfirmed;
                                      });
                                    },
                                    text: ' Cancel Ride',
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
