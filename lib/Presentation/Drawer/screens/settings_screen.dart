import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/customBottemSheet.dart';


import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:get/get.dart';
import 'package:hopper/Presentation/Drawer/controller/profle_cotroller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController dobController = TextEditingController();

  final ProfileController controller = Get.put(ProfileController());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
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
                    const Spacer(),
                    CustomTextFields.textWithStyles700(
                      'Settings',
                      fontSize: 20,
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.containerColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: CustomTextFields.textWithStyles600('Edit'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            AppImages.dummy,
                            height: 85,
                            width: 85,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Positioned(
                          top: 25,
                          left: 25,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.commonWhite,

                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(AppImages.camera, height: 23),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Name & ID
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Michael Francis",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "User ID - HDY7484NGU",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 25,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFields.textWithStyles700(
                        'Basic Info',
                        fontSize: 20,
                      ),
                      SizedBox(height: 20),
                      CustomTextFields.textField(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z]'),
                          ),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your  Name';
                          } /*else if (value.length != 11) {
                            return 'Must be exactly 11 digits';
                          }*/
                          return null;
                        },
                        controller: controller.name,
                        tittle: 'Your Name',
                        hintText: 'Enter Your Name',
                      ),

                      SizedBox(height: 24),
                      CustomTextFields.datePickerField(
                        formKey: _formKey1,
                        onChanged: (value) {
                          _formKey1.currentState?.validate();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your DOB';
                          }
                          return null;
                        },
                        context: context,
                        title: 'Date of Birth',
                        hintText: 'Select your DOB',
                        controller: controller.dobController,
                      ),

                      SizedBox(height: 24),
                      CustomTextFields.dropDown(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select gender';
                          }
                          return null;
                        },
                        controller: controller.genderController,
                        title: 'Gender',
                        hintText: 'Select gender',
                        onTap: () {
                          CustomBottomSheet.showOptionsBottomSheet(
                            title: 'Select Gender',
                            options: ['Male', 'Female', 'Other'],
                            context: context,
                            controller: controller.genderController,
                          );
                        },
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      SizedBox(height: 24),

                      CustomTextFields.textField(
                        controller: controller.emailController,
                        tittle: 'Your email',
                        hintText: 'Enter your Email',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),

                      CustomTextFields.mobileNumber(
                        readOnly: true,
                        title: 'Mobile Number',
                        initialValue: '9',
                        onTap: () {},
                        prefixIcon: Container(
                          alignment: Alignment.center,
                          child: Text('', style: const TextStyle(fontSize: 16)),
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
}
