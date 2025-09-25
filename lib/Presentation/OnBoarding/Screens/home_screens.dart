import 'dart:convert';
// import 'dart:convert';
// import 'package:hopper/Presentation/BookRide/Screens/book_map_screen.dart';
// import 'package:hopper/Presentation/OnBoarding/models/recent_location_model.dart';
// import 'package:http/http.dart' as http;
//
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:hopper/Core/Consents/app_colors.dart';
// import 'package:hopper/Core/Consents/app_logger.dart';
// import 'package:hopper/Core/Consents/app_texts.dart';
// import 'package:hopper/Core/Utility/app_images.dart';
// import 'package:hopper/Core/Utility/app_loader.dart';
// import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
// import 'package:hopper/Presentation/BookRide/Screens/search_screen.dart';
//
// import 'package:hopper/Presentation/OnBoarding/Screens/package_screens.dart';
// import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';
// import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
// import 'package:hopper/Presentation/OnBoarding/models/popular_address_model.dart';
// import 'package:hopper/uber_screen.dart';
// import 'package:hopper/uitls/netWorkHandling/network_handling_screen.dart';
//
// import 'package:hopper/uitls/websocket/socket_io_client.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// import 'package:geocoding/geocoding.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../../api/repository/api_consents.dart';
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
//   LatLng? _currentPosition;
//   String customerId = '';
//   bool _isCameraMoving = false;
//   String _address = 'Search...';
//   BitmapDescriptor? _customIcon;
//   LatLng? _pickedPosition;
//
//   double? _lastZoom;
//   List<PopularPlace> _popularPlaces = [];
//   List<RecentLocation> _recentLocations = [];
//
//   bool _isZooming = false;
//   late BitmapDescriptor _carIcon;
//
//   final Map<String, Marker> _driverMarkers = {};
//
//   final double _zoomThreshold = 0.01;
//   final double _moveThreshold = 0.00005;
//
//   Future<void> _loadCustomMarker() async {
//     _carIcon = await BitmapDescriptor.asset(
//       const ImageConfiguration(),
//       AppImages.movingCar,
//       height: 50,
//       width: 40,
//     );
//     setState(() {});
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
//   Future<String> _getAddressFromLatLng(LatLng position) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//
//       if (placemarks.isNotEmpty) {
//         final placemark = placemarks.first;
//         setState(() {
//           _address = "${placemark.name},${placemark.subLocality ?? ''}";
//         });
//         return "${placemark.name ?? ''}, ${placemark.subLocality ?? ''},";
//       } else {
//         return "Unknown Location";
//       }
//     } catch (e) {
//       print("Error getting address: $e");
//       return "Unknown Location";
//     }
//   }
//
//   Future<void> _initLocation(BuildContext context) async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       Get.snackbar(
//         "Location Disabled",
//         "Please enable location services to use the app.",
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showPermissionDialog(context);
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       _showPermissionDialog(context, openSettings: true);
//       return;
//     }
//
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//
//     final userLatLng = LatLng(position.latitude, position.longitude);
//
//     setState(() {
//       _currentPosition = userLatLng;
//     });
//
//     print("📍 Driver Location: ${position.latitude}, ${position.longitude}");
//
//     if (_mapController != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(target: userLatLng, zoom: 16),
//         ),
//       );
//     }
//     await _fetchPopularPlaces(userLatLng);
//   }
//
//   Future<void> _loadRecentLocations() async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> recentList = prefs.getStringList('recent_locations') ?? [];
//
//     List<RecentLocation> decodedList =
//         recentList.map((jsonStr) {
//           final json = jsonDecode(jsonStr);
//           return RecentLocation.fromJson(json);
//         }).toList();
//
//     setState(() {
//       _recentLocations = decodedList;
//     });
//   }
//
//   Future<void> _fetchPopularPlaces(LatLng location) async {
//     // bus_station
//     // train_station
//     // subway_station
//     // transit_station
//     String apiKey = ApiConsents.googleMapApiKey;
//
//     final types = ['bus_station', 'train_station']; // Add more if needed
//     final url =
//         'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&rankby=distance&type=bus_station&key=$apiKey';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       final data = json.decode(response.body);
//
//       if (data['status'] == 'OK') {
//         final results = data['results'] as List;
//         setState(() {
//           _popularPlaces =
//               results.take(2).map((place) {
//                 String displayName = "${place['name']}, ${place['vicinity']}";
//
//                 return PopularPlace(
//                   name: displayName,
//                   address: place['vicinity'],
//                   lat: place['geometry']['location']['lat'],
//                   lng: place['geometry']['location']['lng'],
//                 );
//               }).toList();
//         });
//       } else {
//         print('Google Places API error: ${data['status']}');
//       }
//     } catch (e) {
//       print('Error fetching popular places: $e');
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
//             title: Text("Permission Required"),
//             content: Text(
//               openSettings
//                   ? "Location permission is permanently denied. Please enable it in settings."
//                   : "Location permission is required to continue.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text("Cancel"),
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
//                 child: Text("Allow"),
//               ),
//             ],
//           ),
//     );
//   }
//
//   Future<void> loadCustomerId() async {
//     final prefs = await SharedPreferences.getInstance();
//     customerId = prefs.getString('customer_Id') ?? '';
//
//     if (customerId.isEmpty) {
//       AppLogger.log.w('⚠️ No customer ID found in shared preferences.');
//     } else {
//       AppLogger.log.i('✅ Loaded customerId = $customerId');
//     }
//   }
//
//   @override
//   bool get wantKeepAlive => true;
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeSocketAndData();
//     });
//   }
//
//   Future<void> _initializeSocketAndData() async {
//     await loadCustomerId();
//     final userId = customerId;
//
//     socketService.initSocket(
//       'https://hoppr-face-two-dbe557472d7f.herokuapp.com',
//     );
//
//     socketService.onConnect(() {
//       socketService.registerUser(userId);
//
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
//     socketService.on('nearby-driver-update', (data) {
//       // AppLogger.log.i("📍 Nearby driver update: $data");
//
//       if (!mounted) return;
//
//       final String driverId = data['driverId'];
//       final double lat = data['latitude'];
//       final double lng = data['longitude'];
//
//       final Marker marker = Marker(
//         markerId: MarkerId(driverId),
//         position: LatLng(lat, lng),
//         icon: _carIcon,
//         anchor: const Offset(0.5, 0.5),
//       );
//
//       setState(() {
//         _driverMarkers[driverId] = marker;
//       });
//     });
//     socketService.on('remove-nearby-driver', (data) {
//       AppLogger.log.i("📍remove-nearby-driver: $data");
//
//       final String driverId = data['driverId'];
//       if (!mounted) return;
//       setState(() {
//         _driverMarkers.remove(driverId);
//       });
//     });
//
//     //
//     // socketService.on('tracked-driver-location', (data) {
//     //   AppLogger.log.i('tracked-driver-location: $data');
//     // });
//
//     _loadCustomMarker();
//     _initLocation(context);
//     _loadRecentLocations();
//   }
//
//   Widget build(BuildContext context) {
//     super.build(context);
//     Set<Marker> _markers = {};
//     if (_currentPosition != null) {
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('current'),
//           position: _currentPosition!,
//           icon: _carIcon,
//         ),
//       );
//     }
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
//                         initialCameraPosition: CameraPosition(
//                           target: LatLng(0, 0),
//                           zoom: 16,
//                         ),
//                         markers: {
//                           ..._driverMarkers.values.toSet(),
//                           // Optional: add current location marker
//                         },
//                         // markers: {
//                         //   Marker(
//                         //     markerId: const MarkerId('current'),
//                         //     position: _currentPosition!,
//                         //     icon:
//                         //         _customIcon ??
//                         //         BitmapDescriptor.defaultMarker,
//                         //   ),
//                         // },
//                         onMapCreated: (controller) async {
//                           _mapController = controller;
//                           _initLocation(context);
//                           String style = await DefaultAssetBundle.of(
//                             context,
//                           ).loadString('assets/map_style/map_style1.json');
//                           _mapController!.setMapStyle(style);
//                         },
//                         onCameraMove: (CameraPosition position) {
//                           // Save camera target every frame
//                           _pickedPosition = position.target;
//
//                           // Check if this is a zoom action
//                           if (_lastZoom != null &&
//                               (position.zoom - _lastZoom!).abs() >
//                                   _zoomThreshold) {
//                             // It's zooming — ignore
//                             _lastZoom = position.zoom;
//                             return;
//                           }
//
//                           _lastZoom = position.zoom;
//                         },
//
//                         onCameraIdle: () async {
//                           LatLngBounds? bounds =
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
//
//                         //
//                         // onCameraIdle: () {
//                         //   if (_isCameraMoving &&
//                         //       _currentPosition != null) {
//                         //     _isCameraMoving = false;
//                         //     _getAddressFromLatLng(_currentPosition!);
//                         //     setState(() {
//                         //       // Only update on confirm, or if you want to auto update:
//                         //       // _currentPosition = _pickedPosition;
//                         //     });
//                         //   }
//                         // },
//                         myLocationEnabled: true,
//                         myLocationButtonEnabled: false,
//                         mapToolbarEnabled: false,
//                         zoomControlsEnabled: false,
//
//                         gestureRecognizers: {
//                           Factory<OneSequenceGestureRecognizer>(
//                             () => EagerGestureRecognizer(),
//                           ),
//                         },
//                       ),
//                       Center(
//                         child: Padding(
//                           padding: EdgeInsets.only(bottom: 40),
//                           child: Image.asset(
//                             AppImages.pinLocation,
//                             height: 40,
//                             width: 25,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: 290,
//                         right: 10,
//                         child: FloatingActionButton(
//                           mini: true,
//                           backgroundColor: Colors.white,
//                           onPressed: _goToCurrentLocation,
//
//                           child: const Icon(
//                             Icons.my_location,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: 50,
//                         left: 16,
//                         right: 16,
//                         child: GestureDetector(
//                           onTap: () {
//                             Get.to(BookRideSearchScreen());
//                           },
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 10,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(12),
//                               boxShadow: [
//                                 BoxShadow(color: Colors.black12, blurRadius: 4),
//                               ],
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(Icons.menu, size: 20),
//                                 Padding(
//                                   padding: const EdgeInsets.all(10),
//                                   child: Image.asset(
//                                     AppImages.dart,
//                                     height: 10,
//                                     width: 10,
//                                     color: AppColors.walletCurrencyColor,
//                                   ),
//                                 ),
//
//                                 Expanded(
//                                   child: Text(
//                                     maxLines: 1,
//                                     _address,
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                                 Icon(Icons.favorite_border, size: 20),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
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
//                             child: PackageContainer.customRideContainer(
//                               onTap: () {
//                                 Get.to(BookRideSearchScreen());
//                               },
//                               tittle: 'Book Ride',
//                               subTitle: 'Best Drivers',
//                               img: AppImages.carImage,
//                               imgHeight: 25,
//                               imgWeight: 45,
//                             ),
//                           ),
//                           SizedBox(width: 5),
//                           Expanded(
//                             child: PackageContainer.customRideContainer(
//                               onTap: () {
//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder:
//                                         (context) =>
//                                             const CommonBottomNavigation(
//                                               initialIndex: 3,
//                                             ),
//                                   ),
//                                 );
//                               },
//                               tittle: 'Courier',
//                               subTitle: 'Fast Delivery',
//                               img: AppImages.bikeImage,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 20),
//                       /*Card(
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
//                                   onTap: () {
//                                     Get.to(BookRideSearchScreen());
//                                   },
//                                   title: 'Search Destination',
//                                 ),
//                                 SizedBox(height: 5),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 10,
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Image.asset(
//                                         AppImages.recentHistory,
//                                         height: 20,
//                                         width: 20,
//                                       ),
//                                       SizedBox(width: 10),
//                                       CustomTextFields.textWithStylesSmall(
//                                         textAlign: TextAlign.center,
//
//                                         colors: AppColors.commonBlack,
//
//                                         fontWeight: FontWeight.w500,
//
//                                         'Castleton Ave, Staten Island',
//                                       ),
//
//                                       Spacer(),
//                                       Icon(Icons.keyboard_arrow_right),
//                                     ],
//                                   ),
//                                 ),
//                                 Divider(
//                                   indent: 10,
//                                   endIndent: 15,
//                                   color: AppColors.commonBlack.withOpacity(0.1),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 10,
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Image.asset(
//                                         AppImages.recentHistory,
//                                         height: 20,
//                                         width: 20,
//                                       ),
//                                       SizedBox(width: 10),
//                                       Expanded(
//                                         child:
//                                             CustomTextFields.textWithStylesSmall(
//                                               textAlign: TextAlign.center,
//                                               colors: AppColors.commonBlack,
//
//                                               fontWeight: FontWeight.w500,
//
//                                               'Castleton Ave, Staten Island',
//                                             ),
//                                       ),
//
//                                       Spacer(),
//                                       Icon(Icons.keyboard_arrow_right),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(height: 5),
//                                 CustomTextFields.textWithStylesSmall(
//                                   textAlign: TextAlign.center,
//                                   AppTexts.tellUsYourDestination,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),*/
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
//                                     // 1. Get address from coordinates
//                                     String pickupAddress =
//                                         await _getAddressFromLatLng(
//                                           _currentPosition!,
//                                         );
//
//                                     Map<String, dynamic> pickupData = {
//                                       'description': pickupAddress,
//                                       'lat': _currentPosition!.latitude,
//                                       'lng': _currentPosition!.longitude,
//                                     };
//
//                                     Get.to(
//                                       BookRideSearchScreen(
//                                         isPickup: false,
//                                         pickupData: pickupData,
//                                       ),
//                                     );
//                                   },
//                                   title: 'Search Destination',
//                                 ),
//
//                                 const SizedBox(height: 5),
//
//                                 // ✅ Show recent if >= 2, else show popular
//                                 ...((_recentLocations.length >= 2)
//                                     ? List.generate(
//                                       _recentLocations.take(2).length,
//                                       (index) {
//                                         final recentLocation =
//                                             _recentLocations[index];
//                                         return Column(
//                                           children: [
//                                             InkWell(
//                                               onTap: () async {
//                                                 String pickupAddress =
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
//                                                       'lat': recentLocation.lat,
//                                                       'lng': recentLocation.lng,
//                                                     },
//                                                     pickupAddress:
//                                                         pickupAddress,
//                                                     destinationAddress:
//                                                         recentLocation
//                                                             .description,
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
//                                                             recentLocation
//                                                                 .description,
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
//                                               String pickupAddress =
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
//                       SizedBox(height: 20),
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
//                                 TextSpan(
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
// }
import 'dart:async';
import 'dart:math' as math;

import 'package:hopper/Presentation/BookRide/Screens/book_map_screen.dart';
import 'package:hopper/Presentation/Drawer/screens/drawer_screen.dart';
import 'package:hopper/Presentation/OnBoarding/models/recent_location_model.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/Screens/search_screen.dart';

import 'package:hopper/Presentation/OnBoarding/Screens/package_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:hopper/Presentation/OnBoarding/models/popular_address_model.dart';
import 'package:hopper/uber_screen.dart';
import 'package:hopper/uitls/netWorkHandling/network_handling_screen.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

import 'package:hopper/uitls/websocket/socket_io_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_consents.dart';

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
  BitmapDescriptor?
  _customIcon; // (unused in map below, keep if you plan to use)
  LatLng? _pickedPosition;

  double? _lastZoom;
  List<PopularPlace> _popularPlaces = [];
  List<RecentLocation> _recentLocations = [];

  bool _isZooming = false;

  // --- Driver markers / icons / animation state ---
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

  // -------------------- LOCATION / UI HELPERS --------------------

  void _goToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final latLng = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
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
        setState(() => _address = value.isEmpty ? "Unknown Location" : value);
        return value;
      }
      return "Unknown Location";
    } catch (e) {
      debugPrint("Error getting address: $e");
      return "Unknown Location";
    }
  }

  Future<void> _initLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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
        _showPermissionDialog(context);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog(context, openSettings: true);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final userLatLng = LatLng(position.latitude, position.longitude);
    setState(() => _currentPosition = userLatLng);

    AppLogger.log.i(
      "📍 Driver Location: ${position.latitude}, ${position.longitude}",
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: 16),
      ),
    );

    await _fetchPopularPlaces(userLatLng);
  }

  Future<void> _loadRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentList = prefs.getStringList('recent_locations') ?? [];
    final decoded =
        recentList.map((jsonStr) {
          final json = jsonDecode(jsonStr);
          return RecentLocation.fromJson(json);
        }).toList();

    setState(() => _recentLocations = decoded);
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

  void _showPermissionDialog(
    BuildContext context, {
    bool openSettings = false,
  }) {
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

  // -------------------- AUTH / INIT --------------------

  Future<void> loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    customerId = prefs.getString('customer_Id') ?? '';
    if (customerId.isEmpty) {
      AppLogger.log.w('⚠️ No customer ID found in shared preferences.');
    } else {
      AppLogger.log.i('✅ Loaded customerId = $customerId');
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketAndData();
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

    // 2) Driver updates (car/bike + animation + timestamp ordering)
    socketService.on('nearby-driver-update', (data) {
      if (!mounted) return;

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

      // Timestamp ordering
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

      // Optional server heading/bearing
      final dynamic hRaw = data['bearing'] ?? data['heading'];
      final double? serverHeading = (hRaw is num) ? hRaw.toDouble() : null;

      _driverTypes[driverId] = rideType;

      _animateDriverTo(
        driverId: driverId,
        to: LatLng(lat, lng),
        serviceType: rideType, // "Bike" / "Car"
        serverHeading: serverHeading,
      );
    });

    // 3) Remove driver (also clear timers/state)
    socketService.on('remove-nearby-driver', (data) {
      AppLogger.log.i("📍 remove-nearby-driver: $data");
      final String driverId = data['driverId'].toString();
      if (!mounted) return;

      _moveTimers.remove(driverId)?.cancel();
      setState(() {
        _driverMarkers.remove(driverId);
      });
      _lastPos.remove(driverId);
      _driverTypes.remove(driverId);
      _lastEventAt.remove(driverId);
    });

    // 4) Load icons (crisp), location, recents
    await _loadDriverIcons();
    await _initLocation(context);
    await _loadRecentLocations();
  }

  // -------------------- ICONS --------------------
  Future<BitmapDescriptor> _bitmapFromAssetSized(
    String assetPath, {
    required double widthDp,
  }) async {
    // Convert logical dp to physical px so icons look consistent across devices
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
    // Sizes tuned to feel like Uber/Ola; tweak 1–2dp if you want smaller/larger.
    _carIcon = await _bitmapFromAssetSized(AppImages.movingCar, widthDp: 28);
    _bikeIcon = await _bitmapFromAssetSized(AppImages.packageBike, widthDp: 24);

    if (!mounted) return;

    // Refresh existing markers to use the new, sized icons
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

  // -------------------- ANIMATION --------------------

  void _animateDriverTo({
    required String driverId,
    required LatLng to,
    required String serviceType,
    double? serverHeading,
  }) {
    // First time → place directly
    if (!_driverMarkers.containsKey(driverId)) {
      _driverMarkers[driverId] = Marker(
        markerId: MarkerId(driverId),
        position: to,
        icon: _iconForRideType(serviceType),
        anchor: const Offset(0.5, 0.5),
        flat: true,
        rotation: serverHeading ?? 0,
      );
      _lastPos[driverId] = to;
      setState(() {});
      return;
    }

    // Cancel any ongoing animation for this driver
    _moveTimers.remove(driverId)?.cancel();

    final from = _lastPos[driverId] ?? _driverMarkers[driverId]!.position;

    if (_almostSame(from, to)) {
      // no move; just update rotation/icon if needed
      final newHeading =
          serverHeading ??
          _bearingBetween(from, to) ??
          _driverMarkers[driverId]!.rotation;

      _driverMarkers[driverId] = _driverMarkers[driverId]!.copyWith(
        positionParam: to,
        rotationParam: newHeading,
        iconParam: _iconForRideType(serviceType),
      );
      _lastPos[driverId] = to;
      setState(() {});
      return;
    }

    final meters = _haversineMeters(from, to);
    final durationMs = meters.clamp(80, 1500).toInt(); // 0.08s..1.5s
    const stepMs = 33; // ~30fps
    final steps = (durationMs / stepMs).clamp(1, 120).round();
    int i = 0;

    final startHeading = _driverMarkers[driverId]!.rotation;
    final endHeading =
        serverHeading ?? (_bearingBetween(from, to) ?? startHeading);

    _moveTimers[driverId] = Timer.periodic(
      const Duration(milliseconds: stepMs),
      (t) {
        i++;
        double tt = (i / steps).clamp(0.0, 1.0);
        tt = _easeOutCubic(tt);

        final pos = _lerpLatLng(from, to, tt);
        final rot = _lerpAngleDeg(startHeading, endHeading, tt);

        _driverMarkers[driverId] = Marker(
          markerId: MarkerId(driverId),
          position: pos,
          icon: _iconForRideType(serviceType),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: rot,
        );
        _lastPos[driverId] = pos;

        if (tt >= 1.0) {
          t.cancel();
          _moveTimers.remove(driverId);
          _driverMarkers[driverId] = Marker(
            markerId: MarkerId(driverId),
            position: to,
            icon: _iconForRideType(serviceType),
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: endHeading,
          );
        }
        if (mounted) setState(() {});
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // important for keepAlive
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
                        markers: {
                          ..._driverMarkers.values.toSet(),
                          // add current marker if you want
                        },
                        onMapCreated: (controller) async {
                          _mapController = controller;
                          _initLocation(context);
                          final style = await DefaultAssetBundle.of(
                            context,
                          ).loadString('assets/map_style/map_style1.json');
                          _mapController?.setMapStyle(style);
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
                            setState(() {});
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

                      // Center pin image overlay (static)
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

                      // "My location" FAB
                      const Positioned(
                        top: 290,
                        right: 10,
                        child: _MyLocationFab(),
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
                                  Get.to(DrawerScreen());
                                },
                                child: Icon(Icons.menu, size: 20),
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
                              const Icon(Icons.favorite_border, size: 20),
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
                            child: PackageContainer.customRideContainer(
                              onTap: () => Get.to(BookRideSearchScreen()),
                              tittle: 'Book Ride',
                              subTitle: 'Best Drivers',
                              img: AppImages.carImage,
                              imgHeight: 25,
                              imgWeight: 45,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: PackageContainer.customRideContainer(
                              onTap: () {
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

  // -------------------- CLEANUP --------------------

  // -------------------- MATH / UTILS --------------------

  bool _almostSame(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 1e-6 &&
      (a.longitude - b.longitude).abs() < 1e-6;

  LatLng _lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );

  double? _bearingBetween(LatLng a, LatLng b) {
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    if (x == 0 && y == 0) return null;
    final brng = math.atan2(y, x);
    return (_radToDeg(brng) + 360) % 360;
  }

  double _haversineMeters(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final la1 = _degToRad(a.latitude);
    final la2 = _degToRad(b.latitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * R * math.asin(math.min(1, math.sqrt(h)));
  }

  double _degToRad(double d) => d * math.pi / 180.0;
  double _radToDeg(double r) => r * 180.0 / math.pi;

  double _lerpAngleDeg(double a, double b, double t) {
    double delta = ((b - a + 540) % 360) - 180;
    return (a + delta * t) % 360;
  }

  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
}

// Small FAB extracted for readability
class _MyLocationFab extends StatelessWidget {
  const _MyLocationFab();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeScreensState>();
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.white,
      onPressed: state?._goToCurrentLocation,
      child: const Icon(Icons.my_location, color: Colors.black),
    );
  }
}
