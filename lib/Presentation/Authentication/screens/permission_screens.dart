import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';

class PermissionScreens extends StatefulWidget {
  const PermissionScreens({super.key});

  @override
  State<PermissionScreens> createState() => _PermissionScreensState();
}

class _PermissionScreensState extends State<PermissionScreens> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppButtons.backButton(context: context),

                      Image.asset(AppImages.location),
                      CustomTextFields.textWithStyles700(
                        AppTexts.locationPermission,
                      ),
                      SizedBox(height: 20),
                      CustomTextFields.textWithStylesSmall(
                        AppTexts.locationPermissionContent,
                      ),
                    ],
                  ),
                ),
              ),
              AppButtons.button(onTap: () {}, text: AppTexts.continues),
            ],
          ),
        ),
      ),
    );
  }
}
