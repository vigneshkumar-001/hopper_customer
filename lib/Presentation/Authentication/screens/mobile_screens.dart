import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/controller/authcontroller.dart';
import 'package:hopper/Presentation/Authentication/screens/otp_screens.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:country_picker/country_picker.dart';
import 'package:get/get.dart';

class MobileScreens extends StatefulWidget {
  const MobileScreens({super.key});

  @override
  State<MobileScreens> createState() => _MobileScreensState();
}

class _MobileScreensState extends State<MobileScreens> {
  final AuthController controller = Get.put(AuthController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  void showCountrySelector(BuildContext) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      searchAutofocus: true,
      onSelect: (Country country) {
        controller.setSelectedCountry(country);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    controller.selectedCountryCode.value = '+234';
    controller.countryCodeController.text = '+234';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppButtons.backButton(context: context),
                        const SizedBox(height: 25),
                        CustomTextFields.textWithStyles700(
                          AppTexts.enterMobileNumberForVerification,
                        ),
                        const SizedBox(height: 15),
                        CustomTextFields.textWithStylesSmall(
                          AppTexts.enterMobileNumberContent,
                        ),
                        const SizedBox(height: 20),

                        // Country Code & Mobile Number Input Row
                        Row(
                          children: [
                            // Country Selector
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () => showCountrySelector(context),
                                child: Obx(
                                  () => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.containerColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          selectedCountryFlag.isEmpty
                                              ? '🇳🇬'
                                              : selectedCountryFlag,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          controller
                                                  .selectedCountryCode
                                                  .value
                                                  .isEmpty
                                              ? '+--'
                                              : controller
                                                  .selectedCountryCode
                                                  .value,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),

                            // Mobile Number Field with Validation
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                onChanged: (value) {
                                  // Trigger revalidation on each change
                                  _formKey.currentState?.validate();
                                },
                                controller: controller.mobileNumber,
                                keyboardType: TextInputType.phone,
                                autofocus: true,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  final code =
                                      controller.selectedCountryCode.value;
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your Mobile Number';
                                  } else if (code == '+91' &&
                                      value.length != 10) {
                                    return 'Indian numbers must be exactly 10 digits';
                                  } else if (code == '+234' &&
                                      value.length != 10) {
                                    return 'Nigerian numbers must be exactly 10 digits';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter mobile number',
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 1,
                                    horizontal: 10,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.containerColor,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Submit Button
                AppButtons.button(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OtpScreens(
                                countyCode:
                                    controller.selectedCountryCode.value,
                                mobileNumber: controller.mobileNumber.text,
                              ),
                        ),
                      );
                    }
                  },
                  text: AppTexts.continueWithPhoneNumber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
