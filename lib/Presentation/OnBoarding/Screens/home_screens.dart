// import 'dart:convert';
// import 'package:hopper/TutorialService_widgets.dart';
// import 'dart:async';
// import 'dart:math' as math;
// import 'dart:math';
// import 'package:flutter_compass/flutter_compass.dart';
// import 'package:hopper/Core/Utility/app_showcase_key.dart';
// import 'package:hopper/Presentation/BookRide/Screens/book_map_screen.dart';
// import 'package:hopper/Presentation/Drawer/screens/drawer_screen.dart';
// import 'package:hopper/Presentation/OnBoarding/models/recent_location_model.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:hopper/Core/Consents/app_colors.dart';
// import 'package:hopper/Core/Consents/app_logger.dart';
// import 'package:hopper/Core/Consents/app_texts.dart';
// import 'package:hopper/Core/Utility/app_images.dart';
//
// import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
// import 'package:hopper/Presentation/BookRide/Screens/search_screen.dart';
// import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';
// import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
// import 'package:hopper/Presentation/OnBoarding/models/popular_address_model.dart';
//
// import 'package:hopper/uitls/netWorkHandling/network_handling_screen.dart';
// import 'dart:ui' as ui;
// import 'package:flutter/services.dart' show rootBundle;
//
// import 'package:hopper/uitls/websocket/socket_io_client.dart';
//
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../api/repository/api_consents.dart';
//
//
//
//
//
// class HomeScreens extends StatefulWidget {
//   const HomeScreens({super.key});
//
//   @override
//   State<HomeScreens> createState() => _HomeScreensState();
// }
//
// class _HomeScreensState extends State<HomeScreens>
//     with AutomaticKeepAliveClientMixin {
//   GoogleMapController? _mapController;
//   final socketService = SocketService();
//
//   LatLng? _currentPosition;
//   String customerId = '';
//   bool _isCameraMoving = false;
//   String _address = 'Search...';
//   BitmapDescriptor?
//   _customIcon; // (unused in map below, keep if you plan to use)
//   LatLng? _pickedPosition;
//   double _heading = 0.0;
//   StreamSubscription<CompassEvent>? _compassStream;
//   double? _lastZoom;
//   List<PopularPlace> _popularPlaces = [];
//   List<RecentLocation> _recentLocations = [];
//
//   bool _isZooming = false;
//
//   // --- Driver markers / icons / animation state ---
//   BitmapDescriptor? _carIcon, _bikeIcon;
//   final BitmapDescriptor _fallbackIcon = BitmapDescriptor.defaultMarker;
//
//   final Map<String, Marker> _driverMarkers = {};
//   final Map<String, String> _driverTypes = {}; // driverId -> "car" | "bike"
//   final Map<String, LatLng> _lastPos = {}; // driverId -> last drawn pos
//   final Map<String, Timer> _moveTimers = {}; // driverId -> animation timer
//   final Map<String, DateTime> _lastEventAt = {}; // driverId -> last server ts
//
//   // thresholds
//   final double _zoomThreshold = 0.01;
//   final double _moveThreshold = 0.00005;
//
//   // -------------------- LOCATION / UI HELPERS --------------------
//
//   void _goToCurrentLocation() async {
//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     final latLng = LatLng(position.latitude, position.longitude);
//     _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
//   }
//
//   Future<String> _getAddressFromLatLng(LatLng position) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final p = placemarks.first;
//         final value = "${p.name ?? ''}, ${p.subLocality ?? ''}";
//         setState(() => _address = value.isEmpty ? "Unknown Location" : value);
//         return value;
//       }
//       return "Unknown Location";
//     } catch (e) {
//       debugPrint("Error getting address: $e");
//       return "Unknown Location";
//     }
//   }
//
//   Future<void> _initLocation(BuildContext context) async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       Get.snackbar(
//         "Location Disabled",
//         "Please enable location services to use the app.",
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showPermissionDialog(context);
//         return;
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       _showPermissionDialog(context, openSettings: true);
//       return;
//     }
//
//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     final userLatLng = LatLng(position.latitude, position.longitude);
//     setState(() => _currentPosition = userLatLng);
//
//     AppLogger.log.i(
//       "📍 Driver Location: ${position.latitude}, ${position.longitude}",
//     );
//
//     _mapController?.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(target: userLatLng, zoom: 16),
//       ),
//     );
//
//     await _fetchPopularPlaces(userLatLng);
//   }
//
//   Future<void> _loadRecentLocations() async {
//     final prefs = await SharedPreferences.getInstance();
//     final recentList = prefs.getStringList('recent_locations') ?? [];
//     final decoded =
//         recentList.map((jsonStr) {
//           final json = jsonDecode(jsonStr);
//           return RecentLocation.fromJson(json);
//         }).toList();
//
//     setState(() => _recentLocations = decoded);
//   }
//
//   Future<void> _fetchPopularPlaces(LatLng location) async {
//     final apiKey = ApiConsents.googleMapApiKey;
//     final url =
//         'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&rankby=distance&type=bus_station&key=$apiKey';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       final data = json.decode(response.body);
//
//       if (data['status'] == 'OK') {
//         final results = (data['results'] as List);
//         setState(() {
//           _popularPlaces =
//               results.take(2).map((place) {
//                 final displayName = "${place['name']}, ${place['vicinity']}";
//                 return PopularPlace(
//                   name: displayName,
//                   address: place['vicinity'],
//                   lat: place['geometry']['location']['lat'],
//                   lng: place['geometry']['location']['lng'],
//                 );
//               }).toList();
//         });
//       } else {
//         debugPrint('Google Places API error: ${data['status']}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching popular places: $e');
//     }
//   }
//
//   void _showPermissionDialog(
//     BuildContext context, {
//     bool openSettings = false,
//   }) {
//     showDialog(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             title: const Text("Permission Required"),
//             content: Text(
//               openSettings
//                   ? "Location permission is permanently denied. Please enable it in settings."
//                   : "Location permission is required to continue.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Cancel"),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   if (openSettings) {
//                     Geolocator.openAppSettings();
//                   } else {
//                     Geolocator.requestPermission();
//                   }
//                 },
//                 child: const Text("Allow"),
//               ),
//             ],
//           ),
//     );
//   }
//
//   // -------------------- AUTH / INIT --------------------
//
//   Future<void> loadCustomerId() async {
//     final prefs = await SharedPreferences.getInstance();
//     customerId = prefs.getString('customer_Id') ?? '';
//     if (customerId.isEmpty) {
//       AppLogger.log.w('⚠️ No customer ID found in shared preferences.');
//     } else {
//       AppLogger.log.i('✅ Loaded customerId = $customerId');
//     }
//   }
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize your socket and compass normally
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeSocketAndData();
//       _startCompassListener();
//     });
//
//     // Trigger tutorial separately with async + delay + mounted check
//     Future.microtask(() async {
//       final prefs = await SharedPreferences.getInstance();
//       bool isShown = prefs.getBool("homeTutorialShown") ?? false;
//
//       if (mounted && !isShown) {
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted) {
//             TutorialService.showTutorial(context);
//           }
//         });
//       }
//     });
//   }
//
//   void _startCompassListener() {
//     _compassStream = FlutterCompass.events?.listen((event) {
//       if (event.heading != null) {
//         setState(() {
//           _heading = event.heading!;
//         });
//       }
//     });
//   }
//
//   Future<void> _initializeSocketAndData() async {
//     await loadCustomerId();
//     final userId = customerId;
//
//     // 1) Init socket & register
//     socketService.initSocket(
//       'https://hoppr-face-two-dbe557472d7f.herokuapp.com',
//     );
//
//     socketService.onConnect(() {
//       socketService.registerUser(userId);
//       socketService.onReconnect(() {
//         AppLogger.log.i("🔄 Reconnected");
//         socketService.registerUser(customerId); // re-register after reconnect
//       });
//     });
//
//     socketService.on('registered', (data) {
//       AppLogger.log.i("✅ Registered → $data");
//     });
//
//     // 2) Driver updates (car/bike + animation + timestamp ordering)
//     socketService.on('nearby-driver-update', (data) {
//       AppLogger.log.i("nearby-driver-update → $data");
//       if (!mounted) return;
//
//       final String driverId = data['driverId'].toString();
//       final double lat = (data['latitude'] as num).toDouble();
//       final double lng = (data['longitude'] as num).toDouble();
//       final String rideType =
//           (data['rideType'] ??
//                   data['serviceType'] ??
//                   data['vehicleType'] ??
//                   data['type'] ??
//                   'car')
//               .toString();
//
//       // Timestamp ordering
//       final String tsRaw = data['timestamp']?.toString() ?? '';
//       final DateTime eventAt =
//           (tsRaw.isNotEmpty ? DateTime.tryParse(tsRaw) : null)?.toUtc() ??
//           DateTime.now().toUtc();
//
//       final lastAt = _lastEventAt[driverId];
//       if (lastAt != null && eventAt.isBefore(lastAt)) {
//         AppLogger.log.w(
//           '⏭️ Stale update ignored for $driverId (eventAt=$eventAt < lastAt=$lastAt)',
//         );
//         return;
//       }
//       _lastEventAt[driverId] = eventAt;
//
//       // Optional server heading/bearing
//       final dynamic hRaw = data['bearing'] ?? data['heading'];
//       final double? serverHeading = (hRaw is num) ? hRaw.toDouble() : null;
//
//       _driverTypes[driverId] = rideType;
//
//       _animateDriverTo(
//         driverId: driverId,
//         to: LatLng(lat, lng),
//         serviceType: rideType, // "Bike" / "Car"
//         serverHeading: serverHeading,
//       );
//     });
//
//     // 3) Remove driver (also clear timers/state)
//     socketService.on('remove-nearby-driver', (data) {
//       AppLogger.log.i("📍 remove-nearby-driver: $data");
//       final String driverId = data['driverId'].toString();
//       if (!mounted) return;
//
//       _moveTimers.remove(driverId)?.cancel();
//       setState(() {
//         _driverMarkers.remove(driverId);
//       });
//       _lastPos.remove(driverId);
//       _driverTypes.remove(driverId);
//       _lastEventAt.remove(driverId);
//     });
//
//     // 4) Load icons (crisp), location, recents
//     await _loadDriverIcons();
//     await _initLocation(context);
//     await _loadRecentLocations();
//   }
//
//   Future<BitmapDescriptor> _bitmapFromAssetSized(
//     String assetPath, {
//     required double widthDp,
//   }) async {
//     // Convert dp to pixels for the current device
//     final dpr = MediaQuery.devicePixelRatioOf(context);
//     final targetWidthPx = (widthDp * dpr).round();
//
//     final byteData = await rootBundle.load(assetPath);
//
//     // Decode image with target size for smooth scaling
//     final codec = await ui.instantiateImageCodec(
//       byteData.buffer.asUint8List(),
//       targetWidth: targetWidthPx,
//     );
//
//     final frame = await codec.getNextFrame();
//
//     final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
//
//     return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
//   }
//
//   Future<void> _loadDriverIcons() async {
//     _carIcon = await _bitmapFromAssetSized(AppImages.movingCar, widthDp: 26);
//     _bikeIcon = await _bitmapFromAssetSized(AppImages.packageBike, widthDp: 30);
//
//     if (!mounted) return;
//
//     setState(() {
//       _driverMarkers.updateAll((id, old) {
//         final t = _driverTypes[id] ?? 'car';
//         return old.copyWith(iconParam: _iconForRideType(t));
//       });
//     });
//   }
//
//   BitmapDescriptor _iconForRideType(String? raw) {
//     final t = (raw ?? '').trim().toLowerCase();
//     switch (t) {
//       case 'bike':
//       case 'two_wheeler':
//       case '2w':
//       case 'motorbike':
//       case 'scooter':
//         return _bikeIcon ?? _fallbackIcon;
//       case 'car':
//       case 'sedan':
//       case 'hatchback':
//       case 'suv':
//       default:
//         return _carIcon ?? _fallbackIcon;
//     }
//   }
//
//   double _haversineMeters(LatLng from, LatLng to) {
//     const double R = 6371000; // Earth radius in meters
//     final dLat = _degreesToRadians(to.latitude - from.latitude);
//     final dLng = _degreesToRadians(to.longitude - from.longitude);
//     final a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(from.latitude)) *
//             cos(_degreesToRadians(to.latitude)) *
//             sin(dLng / 2) *
//             sin(dLng / 2);
//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return R * c;
//   }
//
//   double _degreesToRadians(double degrees) => degrees * pi / 180;
//   double? _bearingBetween(LatLng from, LatLng to) {
//     final lat1 = _degreesToRadians(from.latitude);
//     final lon1 = _degreesToRadians(from.longitude);
//     final lat2 = _degreesToRadians(to.latitude);
//     final lon2 = _degreesToRadians(to.longitude);
//
//     final dLon = lon2 - lon1;
//     final y = sin(dLon) * cos(lat2);
//     final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
//
//     return (atan2(y, x) * 180 / pi + 360) % 360;
//   }
//
//   void _animateDriverTo({
//     required String driverId,
//     required LatLng to,
//     required String serviceType,
//     double? serverHeading,
//   }) {
//     final from = _lastPos[driverId] ?? to;
//     final meters = _haversineMeters(from, to);
//
//     if (meters < 0.5) {
//       _updateDriverMarkerPosition(
//         driverId,
//         to,
//         serverHeading ?? _bearingBetween(from, to) ?? _heading,
//         serviceType,
//       );
//       return;
//     }
//
//     _moveTimers.remove(driverId)?.cancel();
//
//     final durationMs = meters.clamp(500, 1500).toInt();
//     const stepMs = 33;
//     final steps = (durationMs / stepMs).clamp(1, 120).round();
//
//     int i = 0;
//     final startHeading = _driverMarkers[driverId]?.rotation ?? 0.0;
//
//     // ✅ compute proper bearing
//     final computedBearing = _bearingBetween(from, to);
//     final endHeading = serverHeading ?? computedBearing ?? startHeading;
//
//     _moveTimers[driverId] = Timer.periodic(
//       const Duration(milliseconds: stepMs),
//       (timer) {
//         i++;
//         double t = (i / steps).clamp(0.0, 1.0);
//         t = _easeInOutCubic(t);
//
//         final pos = _lerpLatLng(from, to, t);
//         final rot = _lerpAngleDeg(startHeading, endHeading, t);
//
//         _updateDriverMarkerPosition(driverId, pos, rot, serviceType);
//
//         if (t >= 1.0) {
//           timer.cancel();
//           _moveTimers.remove(driverId);
//         }
//       },
//     );
//   }
//
//   void _updateDriverMarkerPosition(
//     String driverId,
//     LatLng pos,
//     double rotation,
//     String serviceType,
//   ) {
//     _driverMarkers[driverId] = Marker(
//       markerId: MarkerId(driverId),
//       position: pos,
//       icon: _iconForRideType(serviceType),
//       anchor: const Offset(0.5, 0.5),
//       flat: true,
//       rotation: (rotation + 360) % 360, // ✅ normalize rotation
//     );
//     _lastPos[driverId] = pos;
//
//     if (mounted) setState(() {});
//   }
//
//   double _easeInOutCubic(double t) {
//     return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
//   }
//
//   LatLng _lerpLatLng(LatLng a, LatLng b, double t) {
//     final lat = a.latitude + (b.latitude - a.latitude) * t;
//     final lng = a.longitude + (b.longitude - a.longitude) * t;
//     return LatLng(lat, lng);
//   }
//
//   double _lerpAngleDeg(double start, double end, double t) {
//     double delta = (end - start) % 360;
//     if (delta > 180) delta -= 360;
//     return (start + delta * t) % 360;
//   }
//
//   @override
//   void dispose() {
//     _compassStream?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return NoInternetOverlay(
//       child: Scaffold(
//         extendBodyBehindAppBar: true,
//         backgroundColor: Colors.white,
//         body: NotificationListener<ScrollNotification>(
//           onNotification: (_) => true,
//           child: CustomScrollView(
//             physics: const BouncingScrollPhysics(),
//             slivers: [
//               SliverAppBar(
//                 backgroundColor: Colors.white,
//                 expandedHeight: 300,
//                 automaticallyImplyLeading: false,
//                 pinned: true,
//                 elevation: 0,
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Stack(
//                     children: [
//                       GoogleMap(
//                         initialCameraPosition: const CameraPosition(
//                           target: LatLng(0, 0),
//                           zoom: 16,
//                         ),
//                         markers: {
//                           ..._driverMarkers.values.toSet(),
//                           // add current marker if you want
//                         },
//                         onMapCreated: (controller) async {
//                           _mapController = controller;
//                           _initLocation(context);
//                           final style = await DefaultAssetBundle.of(
//                             context,
//                           ).loadString('assets/map_style/map_style1.json');
//                           _mapController?.setMapStyle(style);
//                         },
//                         onCameraMove: (CameraPosition position) {
//                           _pickedPosition = position.target;
//                           if (_lastZoom != null &&
//                               (position.zoom - _lastZoom!).abs() >
//                                   _zoomThreshold) {
//                             _lastZoom = position.zoom; // zooming — ignore
//                             return;
//                           }
//                           _lastZoom = position.zoom;
//                         },
//                         onCameraIdle: () async {
//                           final bounds =
//                               await _mapController?.getVisibleRegion();
//                           if (bounds != null) {
//                             final centerLat =
//                                 (bounds.northeast.latitude +
//                                     bounds.southwest.latitude) /
//                                 2;
//                             final centerLng =
//                                 (bounds.northeast.longitude +
//                                     bounds.southwest.longitude) /
//                                 2;
//
//                             _currentPosition = LatLng(centerLat, centerLng);
//                             await _getAddressFromLatLng(_currentPosition!);
//                             setState(() {});
//                           }
//                         },
//                         myLocationEnabled: true,
//                         myLocationButtonEnabled: false,
//                         mapToolbarEnabled: false,
//                         zoomControlsEnabled: false,
//                         gestureRecognizers: {
//                           Factory<OneSequenceGestureRecognizer>(
//                             () => EagerGestureRecognizer(),
//                           ),
//                         },
//                       ),
//
//                       // Center pin image overlay (static)
//                       Center(
//                         child: Padding(
//                           padding: const EdgeInsets.only(bottom: 40),
//                           child: Image.asset(
//                             AppImages.pinLocation,
//                             height: 40,
//                             width: 25,
//                           ),
//                         ),
//                       ),
//
//                       // "My location" FAB
//                       const Positioned(
//                         top: 290,
//                         right: 10,
//                         child: _MyLocationFab(),
//                       ),
//
//                       // Top search bar overlay
//                       Positioned(
//                         top: 50,
//                         left: 16,
//                         right: 16,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 10,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: const [
//                               BoxShadow(color: Colors.black12, blurRadius: 4),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               InkWell(
//                                 onTap: () {
//                                   Get.to(DrawerScreen());
//                                 },
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(5.0),
//                                   child: Icon(Icons.menu, size: 20),
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.all(10),
//                                 child: Image.asset(
//                                   AppImages.dart,
//                                   height: 10,
//                                   width: 10,
//                                   color: AppColors.walletCurrencyColor,
//                                 ),
//                               ),
//                               Expanded(
//                                 child: InkWell(
//                                   onTap: () {
//                                     Get.to(BookRideSearchScreen());
//                                   },
//                                   child: Text(
//                                     _address,
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               // const Icon(Icons.favorite_border, size: 20),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Rest of your content...
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 10,
//                   ),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: GestureDetector(
//                               key: ShowcaseKeys.bookButton,
//                               onTap: () => Get.to(BookRideSearchScreen()),
//                               child: PackageContainer.customRideContainer(
//                                 tittle: 'Book Ride',
//                                 subTitle: 'Best Drivers',
//                                 img: AppImages.carImage,
//                                 imgHeight: 25,
//                                 imgWeight: 45,
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(width: 5),
//                           Expanded(
//                             child: GestureDetector(
//                               key: ShowcaseKeys.courierTab,
//                               child: PackageContainer.customRideContainer(
//                                 onTap: () {
//                                   Navigator.pushReplacement(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder:
//                                           (context) =>
//                                               const CommonBottomNavigation(
//                                                 initialIndex: 3,
//                                               ),
//                                     ),
//                                   );
//                                 },
//                                 tittle: 'Courier',
//                                 subTitle: 'Fast Delivery',
//                                 img: AppImages.bikeImage,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//
//                       // Row(
//                       //   mainAxisAlignment: MainAxisAlignment.center,
//                       //   children: [
//                       //     ElevatedButton(
//                       //       onPressed: () {
//                       //         _testTurn(isRight: false); // Left turn
//                       //       },
//                       //       child: const Text("Left Turn"),
//                       //     ),
//                       //     const SizedBox(width: 10),
//                       //     ElevatedButton(
//                       //       onPressed: () {
//                       //         _testTurn(isRight: true); // Right turn
//                       //       },
//                       //       child: const Text("Right Turn"),
//                       //     ),
//                       //   ],
//                       // ),
//                       Card(
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             border: Border.all(color: AppColors.containerColor),
//                             borderRadius: BorderRadius.circular(15),
//                             color: AppColors.commonWhite,
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 12,
//                             ),
//                             child: Column(
//                               children: [
//                                 CustomTextFields.plainTextField(
//                                   autofocus: false,
//                                   onTap: () async {
//                                     final pickupAddress =
//                                         await _getAddressFromLatLng(
//                                           _currentPosition!,
//                                         );
//                                     final pickupData = {
//                                       'description': pickupAddress,
//                                       'lat': _currentPosition!.latitude,
//                                       'lng': _currentPosition!.longitude,
//                                     };
//                                     Get.to(
//                                       BookRideSearchScreen(
//                                         isPickup: false,
//                                         pickupData: pickupData,
//                                       ),
//                                     );
//                                   },
//                                   title: 'Search Destination',
//                                 ),
//                                 const SizedBox(height: 5),
//
//                                 // Recent if >=2 else Popular
//                                 ...((_recentLocations.length >= 2)
//                                     ? List.generate(
//                                       _recentLocations.take(2).length,
//                                       (index) {
//                                         final recent = _recentLocations[index];
//                                         return Column(
//                                           children: [
//                                             InkWell(
//                                               onTap: () async {
//                                                 final pickupAddress =
//                                                     await _getAddressFromLatLng(
//                                                       _currentPosition!,
//                                                     );
//                                                 Get.to(
//                                                   () => BookMapScreen(
//                                                     pickupData: {
//                                                       'name': pickupAddress,
//                                                       'lat':
//                                                           _currentPosition
//                                                               ?.latitude,
//                                                       'lng':
//                                                           _currentPosition
//                                                               ?.longitude,
//                                                     },
//                                                     destinationData: {
//                                                       'lat': recent.lat,
//                                                       'lng': recent.lng,
//                                                     },
//                                                     pickupAddress:
//                                                         pickupAddress,
//                                                     destinationAddress:
//                                                         recent.description,
//                                                   ),
//                                                 );
//                                               },
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                       horizontal: 10,
//                                                       vertical: 10,
//                                                     ),
//                                                 child: Row(
//                                                   children: [
//                                                     Image.asset(
//                                                       AppImages.recentHistory,
//                                                       height: 20,
//                                                       width: 20,
//                                                     ),
//                                                     const SizedBox(width: 10),
//                                                     Expanded(
//                                                       child:
//                                                           CustomTextFields.textWithStylesSmall(
//                                                             recent.description,
//                                                             maxLines: 1,
//                                                             textAlign:
//                                                                 TextAlign.left,
//                                                             colors:
//                                                                 AppColors
//                                                                     .commonBlack,
//                                                             fontWeight:
//                                                                 FontWeight.w500,
//                                                           ),
//                                                     ),
//                                                     const Icon(
//                                                       Icons
//                                                           .keyboard_arrow_right,
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                             if (index != 1)
//                                               Divider(
//                                                 indent: 10,
//                                                 endIndent: 15,
//                                                 color: AppColors.commonBlack
//                                                     .withOpacity(0.1),
//                                               ),
//                                           ],
//                                         );
//                                       },
//                                     )
//                                     : List.generate(_popularPlaces.length, (
//                                       index,
//                                     ) {
//                                       final place = _popularPlaces[index];
//                                       return Column(
//                                         children: [
//                                           InkWell(
//                                             onTap: () async {
//                                               final pickupAddress =
//                                                   await _getAddressFromLatLng(
//                                                     _currentPosition!,
//                                                   );
//                                               Get.to(
//                                                 () => BookMapScreen(
//                                                   pickupData: {
//                                                     'name': pickupAddress,
//                                                     'lat':
//                                                         _currentPosition
//                                                             ?.latitude,
//                                                     'lng':
//                                                         _currentPosition
//                                                             ?.longitude,
//                                                   },
//                                                   destinationData: {
//                                                     'name': place.name,
//                                                     'lat': place.lat,
//                                                     'lng': place.lng,
//                                                   },
//                                                   pickupAddress: pickupAddress,
//                                                   destinationAddress:
//                                                       place.name,
//                                                 ),
//                                               );
//                                             },
//                                             child: Padding(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                     horizontal: 10,
//                                                     vertical: 10,
//                                                   ),
//                                               child: Row(
//                                                 children: [
//                                                   const Icon(Icons.location_on),
//                                                   const SizedBox(width: 10),
//                                                   Expanded(
//                                                     child:
//                                                         CustomTextFields.textWithStylesSmall(
//                                                           place.name,
//                                                           maxLines: 1,
//                                                           textAlign:
//                                                               TextAlign.left,
//                                                           colors:
//                                                               AppColors
//                                                                   .commonBlack,
//                                                           fontWeight:
//                                                               FontWeight.w500,
//                                                         ),
//                                                   ),
//                                                   const Icon(
//                                                     Icons.keyboard_arrow_right,
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ),
//                                           if (index !=
//                                               _popularPlaces.length - 1)
//                                             Divider(
//                                               indent: 10,
//                                               endIndent: 15,
//                                               color: AppColors.commonBlack
//                                                   .withOpacity(0.1),
//                                             ),
//                                         ],
//                                       );
//                                     })),
//
//                                 const SizedBox(height: 5),
//                                 CustomTextFields.textWithStylesSmall(
//                                   AppTexts.tellUsYourDestination,
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//                       Container(
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(15),
//                           color: AppColors.advertisementColor,
//                         ),
//                         child: ListTile(
//                           title: RichText(
//                             text: TextSpan(
//                               children: [
//                                 TextSpan(
//                                   text: 'JUST IN ',
//                                   style: TextStyle(
//                                     color: AppColors.justInColor,
//                                     fontWeight: FontWeight.w900,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 const TextSpan(
//                                   text: 'Now, Pay at the drop location with ',
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontWeight: FontWeight.normal,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 TextSpan(
//                                   text: 'COD',
//                                   style: TextStyle(
//                                     color: AppColors.commonBlack,
//                                     fontWeight: FontWeight.w900,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           trailing: Image.asset(AppImages.advertisement),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   double _degToRad(double d) => d * math.pi / 180.0;
//   double _radToDeg(double r) => r * 180.0 / math.pi;
//
//   double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
// }
//
// // Small FAB extracted for readability
// class _MyLocationFab extends StatelessWidget {
//   const _MyLocationFab();
//
//   @override
//   Widget build(BuildContext context) {
//     final state = context.findAncestorStateOfType<_HomeScreensState>();
//     return FloatingActionButton(
//       mini: true,
//       backgroundColor: Colors.white,
//       onPressed: state?._goToCurrentLocation,
//       child: const Icon(Icons.my_location, color: Colors.black),
//     );
//   }
// }
//
//
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hopper/TutorialService_widgets.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Core/Utility/app_showcase_key.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/Screens/book_map_screen.dart';
import 'package:hopper/Presentation/BookRide/Screens/search_screen.dart';
import 'package:hopper/Presentation/Drawer/screens/drawer_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/package_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:hopper/Presentation/OnBoarding/models/popular_address_model.dart';
import 'package:hopper/Presentation/OnBoarding/models/recent_location_model.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';
import 'package:hopper/api/repository/api_consents.dart';
import 'package:hopper/uber_screen.dart';
import 'package:hopper/uitls/netWorkHandling/network_handling_screen.dart';
import 'package:hopper/uitls/websocket/socket_io_client.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  final socketService = SocketService();

  LatLng? _currentPosition;
  String customerId = '';
  bool _isCameraMoving = false;
  String _address = 'Search...';
  BitmapDescriptor? _customIcon;
  LatLng? _pickedPosition;
  double _heading = 0.0;
  StreamSubscription<CompassEvent>? _compassStream;
  double? _lastZoom;
  List<PopularPlace> _popularPlaces = [];
  List<RecentLocation> _recentLocations = [];

  bool _isZooming = false;

  // Driver markers / icons / animation state
  BitmapDescriptor? _carIcon, _bikeIcon;
  final BitmapDescriptor _fallbackIcon = BitmapDescriptor.defaultMarker;

  final Map<String, Marker> _driverMarkers = {};
  final Map<String, String> _driverTypes = {}; // driverId -> "car" | "bike"
  final Map<String, LatLng> _lastPos = {}; // driverId -> last drawn pos
  final Map<String, Timer> _moveTimers = {}; // driverId -> animation timer
  final Map<String, DateTime> _lastEventAt = {}; // driverId -> last server ts

  // thresholds
  final double _zoomThreshold = 0.01;
  final double _moveThreshold = 0.00005;

  String? _mapStyle;

  @override
  bool get wantKeepAlive => true;
  void _unfocusAll() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();

    _preloadMapStyle(); // preload style safely (no context needed)

    // Initialize your socket and compass after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketAndData();
      _startCompassListener();
    });
  }

  @override
  void dispose() {
    _compassStream?.cancel();
    // cancel any running timers for driver animations
    for (final t in _moveTimers.values) {
      t.cancel();
    }
    _moveTimers.clear();
    super.dispose();
  }

  // -------------------- PRELOADS / INIT --------------------

  Future<void> _preloadMapStyle() async {
    try {
      final style = await rootBundle.loadString(
        'assets/map_style/map_style1.json',
      );
      if (!mounted) return;
      _mapStyle = style;
    } catch (e) {
      debugPrint('Failed to load map style: $e');
    }
  }

  void _startCompassListener() {
    _compassStream = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      if (event.heading != null) {
        setState(() {
          _heading = event.heading!;
        });
      }
    });
  }

  Future<void> _initializeSocketAndData() async {
    await loadCustomerId();
    final userId = customerId;

    // 1) Init socket & register
    socketService.initSocket(
      'https://hoppr-face-two-dbe557472d7f.herokuapp.com',
    );

    socketService.onConnect(() {
      socketService.registerUser(userId);
      socketService.onReconnect(() {
        AppLogger.log.i("🔄 Reconnected");
        socketService.registerUser(customerId); // re-register after reconnect
      });
    });

    socketService.on('registered', (data) {
      AppLogger.log.i("✅ Registered → $data");
    });

    // 2) Driver updates
    socketService.on('nearby-driver-update', (data) {
      if (!mounted) return;
      AppLogger.log.i("nearby-driver-update → $data");

      final String driverId = data['driverId'].toString();
      final double lat = (data['latitude'] as num).toDouble();
      final double lng = (data['longitude'] as num).toDouble();
      final String rideType =
          (data['rideType'] ??
                  data['serviceType'] ??
                  data['vehicleType'] ??
                  data['type'] ??
                  'car')
              .toString();

      final String tsRaw = data['timestamp']?.toString() ?? '';
      final DateTime eventAt =
          (tsRaw.isNotEmpty ? DateTime.tryParse(tsRaw) : null)?.toUtc() ??
          DateTime.now().toUtc();

      final lastAt = _lastEventAt[driverId];
      if (lastAt != null && eventAt.isBefore(lastAt)) {
        AppLogger.log.w(
          '⏭️ Stale update ignored for $driverId (eventAt=$eventAt < lastAt=$lastAt)',
        );
        return;
      }
      _lastEventAt[driverId] = eventAt;

      final dynamic hRaw = data['bearing'] ?? data['heading'];
      final double? serverHeading = (hRaw is num) ? hRaw.toDouble() : null;

      _driverTypes[driverId] = rideType;

      _animateDriverTo(
        driverId: driverId,
        to: LatLng(lat, lng),
        serviceType: rideType,
        serverHeading: serverHeading,
      );
    });

    // 3) Remove driver
    socketService.on('remove-nearby-driver', (data) {
      if (!mounted) return;
      AppLogger.log.i("📍 remove-nearby-driver: $data");
      final String driverId = data['driverId'].toString();

      _moveTimers.remove(driverId)?.cancel();
      setState(() {
        _driverMarkers.remove(driverId);
      });
      _lastPos.remove(driverId);
      _driverTypes.remove(driverId);
      _lastEventAt.remove(driverId);
    });

    // 4) Load icons, location, recents
    await _loadDriverIcons();
    await _initLocation();
    await _loadRecentLocations();
  }

  Future<void> loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    customerId = prefs.getString('customer_Id') ?? '';
    if (customerId.isEmpty) {
      AppLogger.log.w('⚠️ No customer ID found in shared preferences.');
    } else {
      AppLogger.log.i('✅ Loaded customerId = $customerId');
    }
  }

  // -------------------- LOCATION / UI HELPERS --------------------

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      Get.snackbar(
        "Location Disabled",
        "Please enable location services to use the app.",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDialog(openSettings: false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog(openSettings: true);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;

    final userLatLng = LatLng(position.latitude, position.longitude);
    setState(() => _currentPosition = userLatLng);

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: 16),
      ),
    );

    await _fetchPopularPlaces(userLatLng);
  }

  void _showPermissionDialog({bool openSettings = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Permission Required"),
            content: Text(
              openSettings
                  ? "Location permission is permanently denied. Please enable it in settings."
                  : "Location permission is required to continue.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (openSettings) {
                    Geolocator.openAppSettings();
                  } else {
                    Geolocator.requestPermission();
                  }
                },
                child: const Text("Allow"),
              ),
            ],
          ),
    );
  }

  void _goToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final value = "${p.name ?? ''}, ${p.subLocality ?? ''}";
        if (mounted) {
          setState(() => _address = value.isEmpty ? "Unknown Location" : value);
        }
        return value;
      }
      return "Unknown Location";
    } catch (e) {
      debugPrint("Error getting address: $e");
      return "Unknown Location";
    }
  }

  Future<void> _loadRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentList = prefs.getStringList('recent_locations') ?? [];
    final decoded =
        recentList.map((jsonStr) {
          final json = jsonDecode(jsonStr);
          return RecentLocation.fromJson(json);
        }).toList();

    if (mounted) setState(() => _recentLocations = decoded);
  }

  Future<void> _fetchPopularPlaces(LatLng location) async {
    final apiKey = ApiConsents.googleMapApiKey;
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&rankby=distance&type=bus_station&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final results = (data['results'] as List);
        if (!mounted) return;
        setState(() {
          _popularPlaces =
              results.take(2).map((place) {
                final displayName = "${place['name']}, ${place['vicinity']}";
                return PopularPlace(
                  name: displayName,
                  address: place['vicinity'],
                  lat: place['geometry']['location']['lat'],
                  lng: place['geometry']['location']['lng'],
                );
              }).toList();
        });
      } else {
        debugPrint('Google Places API error: ${data['status']}');
      }
    } catch (e) {
      debugPrint('Error fetching popular places: $e');
    }
  }

  // -------------------- MAP ICONS / MARKERS / ANIMATION --------------------

  Future<BitmapDescriptor> _bitmapFromAssetSized(
    String assetPath, {
    required double widthDp,
  }) async {
    // Convert dp to px for current device
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetWidthPx = (widthDp * dpr).round();

    final byteData = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: targetWidthPx,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _loadDriverIcons() async {
    _carIcon = await _bitmapFromAssetSized(AppImages.movingCar, widthDp: 26);
    _bikeIcon = await _bitmapFromAssetSized(AppImages.packageBike, widthDp: 30);

    if (!mounted) return;

    setState(() {
      _driverMarkers.updateAll((id, old) {
        final t = _driverTypes[id] ?? 'car';
        return old.copyWith(iconParam: _iconForRideType(t));
      });
    });
  }

  BitmapDescriptor _iconForRideType(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    switch (t) {
      case 'bike':
      case 'two_wheeler':
      case '2w':
      case 'motorbike':
      case 'scooter':
        return _bikeIcon ?? _fallbackIcon;
      case 'car':
      case 'sedan':
      case 'hatchback':
      case 'suv':
      default:
        return _carIcon ?? _fallbackIcon;
    }
  }

  double _haversineMeters(LatLng from, LatLng to) {
    const double R = 6371000; // meters
    final dLat = _degreesToRadians(to.latitude - from.latitude);
    final dLng = _degreesToRadians(to.longitude - from.longitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(from.latitude)) *
            cos(_degreesToRadians(to.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  double? _bearingBetween(LatLng from, LatLng to) {
    final lat1 = _degreesToRadians(from.latitude);
    final lon1 = _degreesToRadians(from.longitude);
    final lat2 = _degreesToRadians(to.latitude);
    final lon2 = _degreesToRadians(to.longitude);

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  void _animateDriverTo({
    required String driverId,
    required LatLng to,
    required String serviceType,
    double? serverHeading,
  }) {
    final from = _lastPos[driverId] ?? to;
    final meters = _haversineMeters(from, to);

    if (meters < 0.5) {
      _updateDriverMarkerPosition(
        driverId,
        to,
        serverHeading ?? _bearingBetween(from, to) ?? _heading,
        serviceType,
      );
      return;
    }

    _moveTimers.remove(driverId)?.cancel();

    final durationMs = meters.clamp(500, 1500).toInt();
    const stepMs = 33;
    final steps = (durationMs / stepMs).clamp(1, 120).round();

    int i = 0;
    final startHeading = _driverMarkers[driverId]?.rotation ?? 0.0;
    final computedBearing = _bearingBetween(from, to);
    final endHeading = serverHeading ?? computedBearing ?? startHeading;

    _moveTimers[driverId] = Timer.periodic(
      const Duration(milliseconds: stepMs),
      (timer) {
        i++;
        double t = (i / steps).clamp(0.0, 1.0);
        t = _easeInOutCubic(t);

        final pos = _lerpLatLng(from, to, t);
        final rot = _lerpAngleDeg(startHeading, endHeading, t);

        _updateDriverMarkerPosition(driverId, pos, rot, serviceType);

        if (t >= 1.0) {
          timer.cancel();
          _moveTimers.remove(driverId);
        }
      },
    );
  }

  void _updateDriverMarkerPosition(
    String driverId,
    LatLng pos,
    double rotation,
    String serviceType,
  ) {
    _driverMarkers[driverId] = Marker(
      markerId: MarkerId(driverId),
      position: pos,
      icon: _iconForRideType(serviceType),
      anchor: const Offset(0.5, 0.5),
      flat: true,
      rotation: (rotation + 360) % 360,
    );
    _lastPos[driverId] = pos;

    if (mounted) setState(() {});
  }

  double _easeInOutCubic(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;

  LatLng _lerpLatLng(LatLng a, LatLng b, double t) {
    final lat = a.latitude + (b.latitude - a.latitude) * t;
    final lng = a.longitude + (b.longitude - a.longitude) * t;
    return LatLng(lat, lng);
  }

  double _lerpAngleDeg(double start, double end, double t) {
    double delta = (end - start) % 360;
    if (delta > 180) delta -= 360;
    return (start + delta * t) % 360;
  }

  // -------------------- BUILD --------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NoInternetOverlay(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
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
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(0, 0),
                          zoom: 16,
                        ),
                        markers: {..._driverMarkers.values.toSet()},
                        onMapCreated: (controller) async {
                          _mapController = controller;

                          // If we haven't got user location yet, try now
                          if (_currentPosition == null) {
                            await _initLocation();
                          }

                          // Apply preloaded style safely (no context reads here)
                          final style = _mapStyle;
                          if (style != null) {
                            if (!mounted) return;
                            _mapController?.setMapStyle(style);
                          }
                        },
                        onCameraMove: (CameraPosition position) {
                          _pickedPosition = position.target;
                          if (_lastZoom != null &&
                              (position.zoom - _lastZoom!).abs() >
                                  _zoomThreshold) {
                            _lastZoom = position.zoom; // zooming — ignore
                            return;
                          }
                          _lastZoom = position.zoom;
                        },
                        onCameraIdle: () async {
                          if (_mapController == null) return;
                          final bounds =
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
                            if (mounted) setState(() {});
                          }
                        },
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

                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Image.asset(
                            AppImages.pinLocation,
                            height: 40,
                            width: 25,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 290,
                        right: 10,
                        child: _MyLocationFab(onPressed: _goToCurrentLocation),
                      ),

                      // Top search bar overlay
                      Positioned(
                        top: 50,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DrawerScreen(),
                                    ),
                                  );
                                  // Get.to(DrawerScreen());
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(5.0),
                                  child: Icon(Icons.menu, size: 20),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  AppImages.dart,
                                  height: 10,
                                  width: 10,
                                  color: AppColors.walletCurrencyColor,
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Get.to(BookRideSearchScreen());
                                  },
                                  child: Text(
                                    _address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Rest of your content...
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            key: const ValueKey('home_book_expanded'),
                            child: GestureDetector(
                              onTap: () => Get.to(BookRideSearchScreen()),
                              child: PackageContainer.customRideContainer(
                                tittle: 'Book Ride',
                                subTitle: 'Best Drivers',
                                img: AppImages.carImage,
                                imgHeight: 25,
                                imgWeight: 45,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            key: const ValueKey('home_courier_expanded'),
                            child: GestureDetector(
                              child: PackageContainer.customRideContainer(
                                onTap: () {
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const CommonBottomNavigation(
                                                initialIndex: 3,
                                              ),
                                    ),
                                  );
                                },
                                tittle: 'Courier',
                                subTitle: 'Fast Delivery',
                                img: AppImages.bikeImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.containerColor),
                            borderRadius: BorderRadius.circular(15),
                            color: AppColors.commonWhite,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                CustomTextFields.plainTextField(
                                  autofocus: false,
                                  onTap: () async {
                                    if (_currentPosition == null) return;
                                    final pickupAddress =
                                        await _getAddressFromLatLng(
                                          _currentPosition!,
                                        );
                                    final pickupData = {
                                      'description': pickupAddress,
                                      'lat': _currentPosition!.latitude,
                                      'lng': _currentPosition!.longitude,
                                    };
                                    Get.to(
                                      BookRideSearchScreen(
                                        isPickup: false,
                                        pickupData: pickupData,
                                      ),
                                    );
                                  },
                                  title: 'Search Destination',
                                ),
                                const SizedBox(height: 5),

                                // Recent if >=2 else Popular
                                ...((_recentLocations.length >= 2)
                                    ? List.generate(
                                      _recentLocations.take(2).length,
                                      (index) {
                                        final recent = _recentLocations[index];
                                        return Column(
                                          children: [
                                            InkWell(
                                              onTap: () async {
                                                if (_currentPosition == null) {
                                                  await _initLocation();
                                                  if (_currentPosition == null)
                                                    return;
                                                }
                                                final pickupAddress =
                                                    await _getAddressFromLatLng(
                                                      _currentPosition!,
                                                    );
                                                Get.to(
                                                  () => BookMapScreen(
                                                    pickupData: {
                                                      'name': pickupAddress,
                                                      'lat':
                                                          _currentPosition
                                                              ?.latitude,
                                                      'lng':
                                                          _currentPosition
                                                              ?.longitude,
                                                    },
                                                    destinationData: {
                                                      'lat': recent.lat,
                                                      'lng': recent.lng,
                                                    },
                                                    pickupAddress:
                                                        pickupAddress,
                                                    destinationAddress:
                                                        recent.description,
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Image.asset(
                                                      AppImages.recentHistory,
                                                      height: 20,
                                                      width: 20,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child:
                                                          CustomTextFields.textWithStylesSmall(
                                                            recent.description,
                                                            maxLines: 1,
                                                            textAlign:
                                                                TextAlign.left,
                                                            colors:
                                                                AppColors
                                                                    .commonBlack,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                    const Icon(
                                                      Icons
                                                          .keyboard_arrow_right,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (index != 1)
                                              Divider(
                                                indent: 10,
                                                endIndent: 15,
                                                color: AppColors.commonBlack
                                                    .withOpacity(0.1),
                                              ),
                                          ],
                                        );
                                      },
                                    )
                                    : List.generate(_popularPlaces.length, (
                                      index,
                                    ) {
                                      final place = _popularPlaces[index];
                                      return Column(
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              if (_currentPosition == null) {
                                                await _initLocation();
                                                if (_currentPosition == null)
                                                  return;
                                              }
                                              final pickupAddress =
                                                  await _getAddressFromLatLng(
                                                    _currentPosition!,
                                                  );
                                              Get.to(
                                                () => BookMapScreen(
                                                  pickupData: {
                                                    'name': pickupAddress,
                                                    'lat':
                                                        _currentPosition
                                                            ?.latitude,
                                                    'lng':
                                                        _currentPosition
                                                            ?.longitude,
                                                  },
                                                  destinationData: {
                                                    'name': place.name,
                                                    'lat': place.lat,
                                                    'lng': place.lng,
                                                  },
                                                  pickupAddress: pickupAddress,
                                                  destinationAddress:
                                                      place.name,
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10,
                                                  ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.location_on),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child:
                                                        CustomTextFields.textWithStylesSmall(
                                                          place.name,
                                                          maxLines: 1,
                                                          textAlign:
                                                              TextAlign.left,
                                                          colors:
                                                              AppColors
                                                                  .commonBlack,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                  const Icon(
                                                    Icons.keyboard_arrow_right,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (index !=
                                              _popularPlaces.length - 1)
                                            Divider(
                                              indent: 10,
                                              endIndent: 15,
                                              color: AppColors.commonBlack
                                                  .withOpacity(0.1),
                                            ),
                                        ],
                                      );
                                    })),

                                const SizedBox(height: 5),
                                CustomTextFields.textWithStylesSmall(
                                  AppTexts.tellUsYourDestination,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: AppColors.advertisementColor,
                        ),
                        child: ListTile(
                          title: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'JUST IN ',
                                  style: TextStyle(
                                    color: AppColors.justInColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'Now, Pay at the drop location with ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                                TextSpan(
                                  text: 'COD',
                                  style: TextStyle(
                                    color: AppColors.commonBlack,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Image.asset(AppImages.advertisement),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _degToRad(double d) => d * math.pi / 180.0;
  double _radToDeg(double r) => r * 180.0 / math.pi;
  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
}

// Safer FAB: pass a callback instead of searching the tree
class _MyLocationFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const _MyLocationFab({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.white,
      onPressed: onPressed,
      child: const Icon(Icons.my_location, color: Colors.black),
    );
  }
}
