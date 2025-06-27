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
import 'package:hopper/uber_screen.dart';
import 'package:hopper/uitls/websocket/socket_io_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:geocoding/geocoding.dart';

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
  bool _isCameraMoving = false;
  String _address = 'Search...';
  BitmapDescriptor? _customIcon;
  LatLng? _pickedPosition;
  double? _lastZoom;
  bool _isZooming = false;
  late BitmapDescriptor _carIcon;
  final Map<String, Marker> _driverMarkers = {};

  final double _zoomThreshold = 0.01;
  final double _moveThreshold = 0.00005;

  Future<void> _loadCustomMarker() async {
    _carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      AppImages.movingCar,
      height: 50,
      width: 40,
    );
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
      setState(() {});
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

  Future<void> _initLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    AppLogger.log.i(_currentPosition);
  }

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();

    final userId = "68593b9efda38c44796aca61";

    socketService.initSocket(
      'https://hoppr-face-two-dbe557472d7f.herokuapp.com/',
    );

    socketService.onConnect(() {
      socketService.registerUser(userId);
    });
    socketService.off(
      'nearby-driver-update',
    ); // 👈 Important to remove existing listener
    socketService.on('registered', (data) {
      AppLogger.log.i("✅ Registered → $data");
    });

    socketService.on('nearby-driver-update', (data) {
      if (!mounted) return;

      final String driverId = data['driverId'];
      final double lat = data['latitude'];
      final double lng = data['longitude'];

      final Marker marker = Marker(
        markerId: MarkerId(driverId),
        position: LatLng(lat, lng),
        icon: _carIcon,
        anchor: const Offset(0.5, 0.5),
      );

      setState(() {
        _driverMarkers[driverId] = marker;
      });
    });

    _loadCustomMarker();
    _initLocation();
  }

  @override
  /*  void initState() {
    super.initState();
    // socketService.initSocket(
    //   'https://hoppr-face-two-dbe557472d7f.herokuapp.com/',
    // );
    // socketService.emit('register', {
    //   'userId': "68593b9efda38c44796aca61",
    //   'type': 'customer',
    // });
    // socketService.on('registered', (data) {
    //   AppLogger.log.i("📩 Received: $data");
    // });

    socketService.initSocket(
      'https://hoppr-face-two-dbe557472d7f.herokuapp.com/',
    );

    // 2. On connect, register user
    socketService.onConnect(() {
      socketService.emit('register', {
        'userId': "68593b9efda38c44796aca61",
        'type': 'customer',
      });
    });

    // 3. On registration confirmation
    socketService.on('registered', (data) {
      AppLogger.log.i("✅ Registered → $data");
    });

    // 4. Listen to driver location updates
    socketService.on('nearby-driver-update', (data) {
      final String driverId = data['driverId'];
      final double lat = data['latitude'];
      final double lng = data['longitude'];

      AppLogger.log.i("📍 Nearby driver update: $data");
      final Marker marker = Marker(
        markerId: MarkerId(driverId),
        position: LatLng(lat, lng),
        icon: _carIcon,
        anchor: const Offset(0.5, 0.5),
      );

      setState(() {
        _driverMarkers[driverId] = marker;
      });
    });
    _loadCarIcon();
    _initLocation();
    _loadCustomMarker();
    _getCurrentLocation();
  }*/
  // @override
  // void dispose() {
  //   socketService.dispose();
  //   super.dispose();
  // }
  Widget build(BuildContext context) {
    super.build(context);
    Set<Marker> _markers = {};
    if (_currentPosition != null && _customIcon != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: _customIcon!,
        ),
      );
    }
    return Scaffold(
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
                background:
                    _currentPosition == null
                        ? Center(child: AppLoader.appLoader())
                        : Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentPosition!,
                                zoom: 16,
                              ),
                              markers: {
                                ..._driverMarkers.values.toSet(),
                                // Optional: add current location marker
                              },
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
                                ).loadString(
                                  'assets/map_style/map_style1.json',
                                );
                                _mapController!.setMapStyle(style);
                              },
                              onCameraMove: (CameraPosition position) {
                                // Save camera target every frame
                                _pickedPosition = position.target;

                                // Check if this is a zoom action
                                if (_lastZoom != null &&
                                    (position.zoom - _lastZoom!).abs() >
                                        _zoomThreshold) {
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

                                  _currentPosition = LatLng(
                                    centerLat,
                                    centerLng,
                                  );
                                  await _getAddressFromLatLng(
                                    _currentPosition!,
                                  );
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
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Image.asset(
                                  AppImages.pinLocation,
                                  height: 40,
                                  width: 25,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 50,
                              left: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CommonBottomNavigation(
                                            initialIndex: 3,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.menu, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _address,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.favorite_border, size: 20),
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
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PackageContainer.customRideContainer(
                            onTap: () {
                              Get.to(BookRideSearchScreen());
                            },
                            tittle: 'Book Ride',
                            subTitle: 'Best Drivers',
                            img: AppImages.carImage,
                            imgHeight: 25,
                            imgWeight: 45,
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: PackageContainer.customRideContainer(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const CommonBottomNavigation(
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
                    SizedBox(height: 20),
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
                                onTap: () {
                                  print('Iam tapped');
                                  Get.to(BookRideSearchScreen());
                                },
                                title: 'Search Destination',
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      AppImages.recentHistory,
                                      height: 20,
                                      width: 20,
                                    ),
                                    SizedBox(width: 10),
                                    CustomTextFields.textWithStylesSmall(
                                      textAlign: TextAlign.center,

                                      colors: AppColors.commonBlack,

                                      fontWeight: FontWeight.w500,

                                      'Castleton Ave, Staten Island',
                                    ),

                                    Spacer(),
                                    Icon(Icons.keyboard_arrow_right),
                                  ],
                                ),
                              ),
                              Divider(indent: 10, endIndent: 15),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      AppImages.recentHistory,
                                      height: 20,
                                      width: 20,
                                    ),
                                    SizedBox(width: 10),
                                    CustomTextFields.textWithStylesSmall(
                                      textAlign: TextAlign.center,
                                      colors: AppColors.commonBlack,

                                      fontWeight: FontWeight.w500,

                                      'Castleton Ave, Staten Island',
                                    ),

                                    Spacer(),
                                    Icon(Icons.keyboard_arrow_right),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              CustomTextFields.textWithStylesSmall(
                                textAlign: TextAlign.center,
                                AppTexts.tellUsYourDestination,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
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
                              TextSpan(
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
    );
  }
}
