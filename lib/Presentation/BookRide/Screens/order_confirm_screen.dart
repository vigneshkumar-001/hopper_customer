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
  bool isDriverConfirmed = false;
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
                                'KJA978AZ',
                                colors: AppColors.commonBlack,
                                fontWeight: FontWeight.w500,
                              ),
                              CustomTextFields.textWithStylesSmall(
                                'Oluwaseun Michael ⭐ 4.5',
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
