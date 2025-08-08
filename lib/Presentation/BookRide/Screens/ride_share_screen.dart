import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/Screens/confirm_booking.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';

class RideShareScreen extends StatefulWidget {
  final String? selectedCarType;
  final Map<String, dynamic> pickupData;
  final Map<String, dynamic> destinationData;
  final String pickupAddress;
  final String destinationAddress;
  const RideShareScreen({
    super.key,
    this.selectedCarType,
    required this.pickupData,
    required this.destinationData,
    required this.pickupAddress,
    required this.destinationAddress,
  });

  @override
  State<RideShareScreen> createState() => _RideShareScreenState();
}

class _RideShareScreenState extends State<RideShareScreen> {
  int selectedIndex = -1;
  Set<int> selectedSeats = {};
  int seatCount = 1;
  final int maxSeatCount = 2;
  final int minSeatCount = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
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
                            'Seat Selection',
                            fontSize: 20,
                          ),
                          Spacer(),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.containerColor,
                      ),
                      child: ListTile(
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Ride'),
                            Row(
                              children: [
                                CustomTextFields.textWithStyles600(
                                  '${widget.selectedCarType} Share  ',
                                  fontSize: 16,
                                ),
                                Icon(Icons.circle, size: 7),
                                CustomTextFields.textWithStyles600(
                                  '  4 seats',
                                  fontSize: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColors.commonWhite,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomTextFields.textWithStylesSmall(
                                  'Total Fare',
                                ),
                                SizedBox(height: 5),
                                CustomTextFields.textWithImage(
                                  sizedBox: 1,
                                  text: '63',
                                  colors: AppColors.commonBlack,
                                  fontWeight: FontWeight.w600,
                                  rightTextFontSize: 13,
                                  imagePath: AppImages.nBlackCurrency,
                                  rightImagePath: AppImages.nBlackCurrency,
                                  rightImagePathText: ' 85',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CustomTextFields.textWithStyles600(
                    //   'Number of Passengers',
                    //   fontSize: 18,
                    // ),
                    // const SizedBox(height: 20),
                    // Row(
                    //   children: [
                    //     Container(
                    //       height: 40,
                    //       width: 40,
                    //       decoration: BoxDecoration(
                    //         border: Border.all(
                    //           color: Colors.black.withOpacity(0.2),
                    //         ),
                    //         borderRadius: BorderRadius.circular(50),
                    //       ),
                    //       child: IconButton(
                    //         icon: Icon(Icons.remove, size: 23),
                    //         onPressed:
                    //             seatCount > minSeatCount
                    //                 ? () {
                    //                   setState(() {
                    //                     seatCount--;
                    //                   });
                    //                 }
                    //                 : null, // disable if already at minimum
                    //       ),
                    //     ),
                    //
                    //     const SizedBox(width: 16),
                    //
                    //     Text(
                    //       '$seatCount',
                    //       style: TextStyle(
                    //         fontSize: 18,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //
                    //     const SizedBox(width: 16),
                    //
                    //     Container(
                    //       height: 40,
                    //       width: 40,
                    //       decoration: BoxDecoration(
                    //         border: Border.all(
                    //           color: Colors.black.withOpacity(0.2),
                    //         ),
                    //         borderRadius: BorderRadius.circular(50),
                    //       ),
                    //       child: IconButton(
                    //         icon: Icon(Icons.add, size: 22),
                    //         onPressed:
                    //             seatCount < maxSeatCount
                    //                 ? () {
                    //                   setState(() {
                    //                     seatCount++;
                    //                   });
                    //                 }
                    //                 : null, // disable if already at max
                    //       ),
                    //     ),
                    //
                    //     const SizedBox(width: 20),
                    //
                    //   ],
                    // ),
                    const SizedBox(height: 10),
                    CustomTextFields.textWithStylesSmall(
                      'Max 2 per booking',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 20),
                    CustomTextFields.textWithStyles600(
                      'Select your preferred seat',
                      fontSize: 18,
                    ),
                    const SizedBox(height: 5),
                    CustomTextFields.textWithStylesSmall(
                      'Selecting specific seat helps us optimize your ride - sharing experience',
                    ),
                    const SizedBox(height: 35),

                    /*      Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 55),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.commonBlack.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(height: 5),
                                Container(
                                  width: 95,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.rideShareContainerColor2,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(60),
                                      topRight: Radius.circular(60),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {},
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.stearing,
                                              rightImage: AppImages.alone,
                                              isSelected: false,
                                              isDisabled: true,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedSeats.contains(1)) {
                                              selectedSeats.remove(1);
                                            } else {
                                              selectedSeats.add(1);
                                            }
                                          });
                                        },
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.alone,
                                              rightImage: AppImages.alone,
                                              isSelected: selectedSeats
                                                  .contains(1),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedSeats.contains(2)) {
                                              selectedSeats.remove(2);
                                            } else {
                                              selectedSeats.add(2);
                                            }
                                          });
                                        },
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.alone,
                                              rightImage: AppImages.alone,
                                              isSelected: selectedSeats
                                                  .contains(2),
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedIndex == 3) {
                                              selectedIndex = -1;
                                            } else {
                                              selectedIndex = 3;
                                            }
                                          });
                                        },
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.alone,
                                              rightImage: AppImages.alone,
                                              isSelected: selectedIndex == 3,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),*/
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 55),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.commonBlack.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(height: 5),
                                Container(
                                  width: 95,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.rideShareContainerColor2,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(60),
                                      topRight: Radius.circular(60),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {},
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.stearing,
                                              rightImage: AppImages.alone,
                                              isSelected: false,
                                              isDisabled: true,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedSeats.contains(1)) {
                                              selectedSeats.remove(1);
                                            } else {
                                              if (selectedSeats.length <
                                                  maxSeatCount) {
                                                selectedSeats.add(1);
                                              } else {
                                                Get.closeAllSnackbars();
                                                Get.snackbar(
                                                  'Limit Reached',
                                                  'Maximum $maxSeatCount seats can be selected',
                                                  snackPosition:
                                                      SnackPosition.TOP,
                                                  backgroundColor:
                                                      AppColors.commonBlack,
                                                  colorText:
                                                      AppColors.commonWhite,
                                                );
                                              }
                                            }
                                          });
                                        },
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.alone,
                                              rightImage: AppImages.alone,
                                              isSelected: selectedSeats
                                                  .contains(1),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedSeats.contains(2)) {
                                              selectedSeats.remove(2);
                                            } else {
                                              if (selectedSeats.length <
                                                  maxSeatCount) {
                                                selectedSeats.add(2);
                                              } else {
                                                Get.closeAllSnackbars();
                                                Get.snackbar(
                                                  'Limit Reached',
                                                  'Maximum $maxSeatCount seats can be selected',
                                                  snackPosition:
                                                      SnackPosition.TOP,
                                                  backgroundColor:
                                                      AppColors.commonBlack,
                                                  colorText:
                                                      AppColors.commonWhite,
                                                );
                                              }
                                            }
                                          });
                                        },
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.alone,
                                              rightImage: AppImages.alone,
                                              isSelected: selectedSeats
                                                  .contains(2),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedSeats.contains(3)) {
                                              selectedSeats.remove(3);
                                            } else {
                                              if (selectedSeats.length <
                                                  maxSeatCount) {
                                                selectedSeats.add(3);
                                              } else {
                                                Get.closeAllSnackbars();
                                                Get.snackbar(
                                                  'Limit Reached',
                                                  'Maximum $maxSeatCount seats can be selected',
                                                  snackPosition:
                                                      SnackPosition.TOP,
                                                  backgroundColor:
                                                      AppColors.commonBlack,
                                                  colorText:
                                                      AppColors.commonWhite,
                                                );
                                              }
                                            }
                                          });
                                        },
                                        child:
                                            PackageContainer.rideShareContainer(
                                              leftImage: AppImages.alone,
                                              rightImage: AppImages.alone,
                                              isSelected: selectedSeats
                                                  .contains(3),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(
                            size: 15,
                            Icons.circle,
                            color: AppColors.rideShareContainerColor3,
                          ),
                          SizedBox(width: 2),

                          Text('Available'),
                          SizedBox(width: 10),
                          Icon(
                            Icons.circle,
                            color: AppColors.changeButtonColor,
                            size: 15,
                          ),
                          SizedBox(width: 2),

                          Text('Selected'),
                          SizedBox(width: 10),
                          Icon(
                            size: 15,
                            Icons.circle,
                            color: AppColors.rideShareContainerColor,
                          ),
                          SizedBox(width: 2),
                          Text('Taken'),
                          SizedBox(width: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xffF6F7FF),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              SizedBox(height: 4),
              AppButtons.button(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ConfirmBooking(
                            selectedCarType: widget.selectedCarType!,
                            pickupData: widget.pickupData,
                            destinationData: widget.destinationData,
                            pickupAddress: widget.pickupAddress,
                            destinationAddress: widget.destinationAddress,
                          ),
                    ),
                  );
                },
                text: 'Confirm',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
