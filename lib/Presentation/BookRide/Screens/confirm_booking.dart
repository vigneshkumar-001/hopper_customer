import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_logger.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/Presentation/BookRide/Screens/order_confirm_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';

class ConfirmBooking extends StatefulWidget {
  final String? selectedCarType;
  final Map<String, dynamic> pickupData;
  final Map<String, dynamic> destinationData;
  final String pickupAddress;
  final String destinationAddress;
  final String? carType;
  const ConfirmBooking({
    super.key,
    this.selectedCarType,
    required this.pickupData,
    this.carType,
    required this.destinationData,
    required this.pickupAddress,
    required this.destinationAddress,
  });

  @override
  State<ConfirmBooking> createState() => _ConfirmBookingState();
}

class _ConfirmBookingState extends State<ConfirmBooking> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  DriverSearchController driverController = Get.put(DriverSearchController());

  LatLng? _pickupPosition;
  LatLng? _destinationPosition;
  @override
  @override
  void initState() {
    super.initState();

    _pickupPosition = LatLng(
      widget.pickupData['lat'],
      widget.pickupData['lng'],
    );

    _destinationPosition = LatLng(
      widget.destinationData['lat'],
      widget.destinationData['lng'],
    );
  }
  String formatDistance(double meters) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} Km';
  }

  String formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return hours > 0
        ? '$hours hr $remainingMinutes min'
        : '$remainingMinutes min';
  }
  @override
  Widget build(BuildContext context) {
    _startController.text = widget.pickupAddress;
    _destController.text = widget.destinationAddress;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (driverController.isLoading.value) {
            return Center(child: AppLoader.appLoader());
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          AppImages.backImage,
                          height: 19,
                          width: 19,
                        ),
                      ),
                      Spacer(),

                      CustomTextFields.textWithStyles700(
                        'Confirm Booking',
                        fontSize: 20,
                      ),
                      Spacer(),
                    ],
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
                          autofocus: false,
                          Style: TextStyle(
                            fontSize: 12,
                            color: AppColors.commonBlack.withOpacity(0.6),
                            overflow: TextOverflow.ellipsis,
                          ),
                          readOnly: true,

                          hintStyle: TextStyle(fontSize: 11),
                          imgHeight: 17,
                          controller: _startController,

                          containerColor: AppColors.commonWhite,
                          leadingImage: AppImages.circleStart,
                          title: 'Search for an address or landmark',
                        ),
                        const Divider(
                          height: 0,
                          color: AppColors.containerColor,
                        ),
                        CustomTextFields.plainTextField(
                          autofocus: false,
                          Style: TextStyle(
                            fontSize: 12,
                            color: AppColors.commonBlack.withOpacity(0.6),
                            overflow: TextOverflow.ellipsis,
                          ),

                          controller: _destController,

                          hintStyle: TextStyle(fontSize: 11),
                          imgHeight: 17,
                          containerColor: AppColors.commonWhite,
                          leadingImage: AppImages.rectangleDest,
                          title: 'Enter destination',
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(color: AppColors.containerColor),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        spacing: 7,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomTextFields.textWithStylesSmall('Your Ride'),
                            ],
                          ),

                          Row(
                            children: [
                              CustomTextFields.textWithStyles600(
                                '${widget.selectedCarType ?? ''}  ',
                                fontSize: 18,
                              ),
                              Icon(Icons.circle, size: 7),
                              CustomTextFields.textWithStyles600(
                                '  Ride Alone',
                                fontSize: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  CustomTextFields.textWithStyles700(
                    'Price Details',
                    fontSize: 20,
                  ),
                  SizedBox(height: 15),
                  Obx(() {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.commonBlack.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Column(
                            spacing: 5,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(AppTexts.baseFare)),
                                  CustomTextFields.textWithImage(
                                    text:
                                        driverController
                                            .carBooking
                                            .value
                                            ?.baseFare
                                            .toString() ??
                                        '',
                                    imagePath: AppImages.nCurrency,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: Text(AppTexts.serviceFare)),
                                    CustomTextFields.textWithImage(
                                      text:   driverController
                                          .carBooking
                                          .value
                                          ?.serviceFare
                                          .toString() ??
                                          "",


                                      imagePath: AppImages.nCurrency,
                                      fontWeight: FontWeight.w900,
                                 ),
                                ],
                              ),
                              SizedBox(height: 3),
                              SizedBox(
                                height: 2,
                                child: DottedLine(
                                  direction: Axis.horizontal,
                                  lineLength: double.infinity,
                                  lineThickness: 1.4,
                                  dashLength: 4.0,
                                  dashColor: Colors.grey.shade400,
                                ),
                              ),
                              SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(child: Text(AppTexts.estTime)),
                                  CustomTextFields.textWithImage(
                                    text:formatDuration(  driverController
                                        .carBooking
                                        .value
                                        ?. duration ??0),


                                    fontWeight: FontWeight.w900,
                                  ),
                                ],
                              ),

                              Row(
                                children: [
                                  Expanded(child: Text(AppTexts.totalKm)),
                                  CustomTextFields.textWithImage(

                                  text: formatDistance((driverController.carBooking.value?.distance ?? 0).toDouble()),

                                    fontWeight: FontWeight.w900,
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),
                              SizedBox(
                                height: 2,
                                child: DottedLine(
                                  direction: Axis.horizontal,
                                  lineLength: double.infinity,
                                  lineThickness: 1.4,
                                  dashLength: 4.0,
                                  dashColor: Colors.grey.shade400,
                                ),
                              ),
                              SizedBox(height: 3),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextFields.textWithStyles600(
                                      AppTexts.total,
                                      fontSize: 14,
                                    ),
                                  ),

                                  CustomTextFields.textWithImage(
                                    text:
                                        ((driverController
                                                        .carBooking
                                                        .value
                                                        ?.baseFare ??
                                                    0) +
                                                (driverController
                                                        .carBooking
                                                        .value
                                                        ?.serviceFare ??
                                                    0))
                                            .toString(),

                                    imagePath: AppImages.nBlackCurrency,
                                    fontWeight: FontWeight.w900,
                                    colors: AppColors.commonBlack,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: 10),
                  CustomTextFields.textWithStylesSmall(
                    'By confirming, you agree to our Terms of Service and Cancellation Policy',
                  ),
                ],
              ),
            ),
          );
        }),
      ),

      bottomNavigationBar: Obx(() {
        return driverController.isLoading.value
            ? const SizedBox.shrink()
            : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: AppButtons.button(
                  onTap: () async {
                    final allData = driverController.carBooking.value;
                    String? result = await driverController.sendDriverRequest(
                      carType: widget.carType ?? '',
                      pickupLatitude: allData?.fromLatitude ?? 0.0,
                      pickupLongitude: allData?.fromLongitude ?? 0.0,
                      dropLatitude: allData?.toLatitude ?? 0.0,
                      dropLongitude: allData?.toLongitude ?? 0.0,
                      bookingId: allData?.bookingId.toString() ?? '',
                      context: context,
                    );
                    AppLogger.log.i(result);
                    if (result != null) {
                      driverController.selectedCarType.value = '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OrderConfirmScreen(
                                pickupData: {
                                  'description': widget.pickupAddress,
                                  'lat': _pickupPosition?.latitude ?? 0.0,
                                  'lng': _pickupPosition?.longitude ?? 0.0,
                                },
                                destinationData: {
                                  'description': widget.destinationAddress,
                                  'lat': _destinationPosition?.latitude ?? 0.0,
                                  'lng': _destinationPosition?.longitude ?? 0.0,
                                },
                                pickupAddress: widget.pickupAddress,
                                destinationAddress: widget.destinationAddress,
                              ),
                        ),
                      );
                    }
                  },
                  text: 'Confirm',
                  rightImagePath: AppImages.nBlackCurrency,
                  rightImagePathText: driverController.carBooking.value?.amount ?? 0,
                ),
              ),
            );
      }),
      /* bottomNavigationBar: Obx(() {
        return driverController.isLoading.value
            ? const SizedBox.shrink()
            : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: AppButtons.button(
                  onTap: () async {
                    final allData = driverController.carBooking.value;
                    AppLogger.log.i(allData?.bookingId.toString() ?? '');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PaymentScreen(
                              amount: 0,
                              bookingId: allData?.bookingId.toString() ?? '',
                            ),
                      ),
                    );
                  },
                  text: 'Confirm',
                  rightImagePath: AppImages.nBlackCurrency,
                  rightImagePathText:
                      ((driverController.carBooking.value?.baseFare ?? 0) +
                              (driverController.carBooking.value?.serviceFare ??
                                  0))
                          .toString(),
                ),
              ),
            );
      }),*/
    );
  }
}
