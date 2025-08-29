import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
import 'package:dotted_line/dotted_line.dart';
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

class PackageMapConfirmScreen extends StatefulWidget {
  const PackageMapConfirmScreen({super.key});

  @override
  State<PackageMapConfirmScreen> createState() =>
      _PackageMapConfirmScreenState();
}

class _PackageMapConfirmScreenState extends State<PackageMapConfirmScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _carIcon;
  Set<Marker> _markers = {};
  bool _isDriverConfirmed = false;
  Future<void> _loadCustomMarker() async {
    _carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      AppImages.movingCar,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateLineHeight());
  }

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
            top: 300,
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
                                  // driverSearchController.cancelRide(
                                  //   bookingId:
                                  //   driverSearchController
                                  //       .carBooking
                                  //       .value!
                                  //       .bookingId,
                                  //   selectedReason: selectedReason,
                                  //   context: context,
                                  // );
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
                                        'PKG - 2025-7481',
                                        colors: AppColors.commonBlack,
                                        fontWeight: FontWeight.w500,
                                      ),

                                      Row(
                                        children: [
                                          ClipOval(
                                            child: Image.asset(
                                              AppImages.dummy,
                                              height: 26,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          CustomTextFields.textWithStylesSmall(
                                            fontSize: 15,
                                            'Oluwaseun Michael ',
                                            colors: AppColors.commonBlack,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          SizedBox(width: 5),
                                          Image.asset(
                                            AppImages.star,
                                            width: 13,
                                            height: 13,
                                          ),
                                          SizedBox(width: 5),
                                          CustomTextFields.textWithStyles600(
                                            '4.5',
                                          ),
                                        ],
                                      ),
                                      CustomTextFields.textWithStylesSmall(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        'Vehicle: Bike (TN 01 AB 1234)',
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
                              SizedBox(height: 20),

                              GestureDetector(
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
                              ),
                              SizedBox(height: 25),
                              if (_isDriverConfirmed) ...[
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
                              ] else ...[
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
                              ],

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
                                    'PKG-2025-7481',
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
                                    '2.5 kg',
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
                                                  children: const [
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
                                                      '123 Main Street, Apt 4B\nMadurai, Tamil Nadu 625001',
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
                                                  children: const [
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
                                                      '56 Oak Avenue, Floor 2\nChennai, Tamil Nadu 600001',
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
                                                  AppButtons.showPackageCancelBottomSheet(
                                                    context,
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
                                                    'PKG - 2025-7481',
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
