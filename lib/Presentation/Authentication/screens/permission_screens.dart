import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/package_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

class PermissionScreens extends StatefulWidget {
  const PermissionScreens({super.key});

  @override
  State<PermissionScreens> createState() => _PermissionScreensState();
}

class _PermissionScreensState extends State<PermissionScreens> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  LatLng? _currentPosition;
  bool isLoading = false;

  Future<void> _initLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // ✅ 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "Location Disabled",
        "Please enable location services to use the app.",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // ✅ 2. Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDialog(context);
        return;
      }
    }

    // ✅ 3. Handle permanently denied
    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog(context, openSettings: true);
      return;
    }

    try {
      // ✅ 4. Optional: show loading if you're staying on this screen
      setState(() => isLoading = true);

      // ✅ 5. Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CommonBottomNavigation()),
      );

      setState(() {
        _currentPosition = userLatLng;
        // isLoading = false;
      });

      print("📍 Driver Location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Error", "Unable to fetch location: $e");
    }
  }

  void _showPermissionDialog(
    BuildContext context, {
    bool openSettings = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.commonWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
            title: Row(
              children: const [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  "Permission Required",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              openSettings
                  ? "Location permission is permanently denied. Please enable it in your device settings to continue."
                  : "We need your location to continue. Please grant permission.",
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (openSettings) {
                    Geolocator.openAppSettings();
                  } else {
                    Geolocator.requestPermission();
                  }
                },
                child: Text(
                  "Allow",
                  style: TextStyle(color: AppColors.commonWhite),
                ),
              ),
            ],
          ),
    );
  }

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

              isLoading
                  ? AppLoader.appLoader()
                  : AppButtons.button(
                    onTap: () async {
                      await _initLocation(context);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => CommonBottomNavigation(),
                      //   ),
                      // );
                    },
                    text: AppTexts.continues,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
