import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/order_confirm_screen.dart';


class ConfirmBooking extends StatefulWidget {
  final String? selectedCarType;
  const ConfirmBooking({super.key, this.selectedCarType});

  @override
  State<ConfirmBooking> createState() => _ConfirmBookingState();
}

class _ConfirmBookingState extends State<ConfirmBooking> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      Style: TextStyle(
                        fontSize: 12,
                        color: AppColors.commonBlack.withOpacity(0.6),
                        overflow: TextOverflow.ellipsis,
                      ),
                      readOnly: true,

                      hintStyle: TextStyle(fontSize: 11),
                      imgHeight: 20,
                      controller: _startController,

                      containerColor: AppColors.commonWhite,
                      leadingImage: AppImages.dart,
                      title: 'Search for an address or landmark',
                    ),
                    const Divider(height: 0, color: AppColors.containerColor),
                    CustomTextFields.plainTextField(
                      Style: TextStyle(
                        fontSize: 12,
                        color: AppColors.commonBlack.withOpacity(0.6),
                        overflow: TextOverflow.ellipsis,
                      ),

                      controller: _destController,

                      hintStyle: TextStyle(fontSize: 11),
                      imgHeight: 20,
                      containerColor: AppColors.commonWhite,
                      leadingImage: AppImages.dart,
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
              CustomTextFields.textWithStyles700('Price Details', fontSize: 20),
              SizedBox(height: 15),
              Container(
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
                              text: '125',
                              imagePath: AppImages.nCurrency,
                              fontWeight: FontWeight.w900,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text(AppTexts.serviceFare)),
                            CustomTextFields.textWithImage(
                              text: '125',
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
                            Expanded(
                              child: CustomTextFields.textWithStyles600(
                                AppTexts.total,
                                fontSize: 14,
                              ),
                            ),

                            CustomTextFields.textWithImage(
                              text: '125',
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
              ),
              SizedBox(height: 10),
              CustomTextFields.textWithStylesSmall(
                'By confirming, you agree to our Terms of Service and Cancellation Policy',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: AppButtons.button(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderConfirmScreen()));
            },
            text: 'Confrim',
            rightImagePath: AppImages.nBlackCurrency,
            rightImagePathText: ' 73',
          ),
        ),
      ),
    );
  }
}
