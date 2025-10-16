// import 'package:flutter/material.dart';
// import 'package:hopper/Core/Consents/app_colors.dart';
// import 'package:hopper/Presentation/Authentication/screens/splash_screens.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
// import 'package:hopper/Presentation/OnBoarding/Screens/payment_screen.dart';
//
// import 'package:hopper/init_controller.dart';
// import 'package:flutter/services.dart';
//
// import 'package:hopper/uber_screen.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   Stripe.publishableKey =
//       "pk_test_51RTgU2Qhzmr6TYhsKMWtfICaQ72crva7xVWCA0hPeV1qdH9CInnl9WwJLNcxIIUWKDhCeipRLztD82DTnBXKx05700iEGBQWjw";
//   await Stripe.instance.applySettings();
//   await initController();
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.white,
//       statusBarIconBrightness: Brightness.dark,
//       statusBarBrightness: Brightness.dark,
//       systemNavigationBarColor: Colors.black,
//       systemNavigationBarIconBrightness: Brightness.dark,
//     ),
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ScreenUtilInit(
//       designSize: const Size(360, 690),
//       child: GetMaterialApp(
//         theme: ThemeData(
//           scaffoldBackgroundColor: AppColors.commonWhite,
//           textSelectionTheme: TextSelectionThemeData(
//             selectionHandleColor: Colors.black,
//           ),
//         ),
//         debugShowCheckedModeBanner: false,
//         home: SplashScreens(),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hopper/Presentation/Authentication/controller/authController.dart';
import 'package:hopper/Presentation/Drawer/controller/profle_cotroller.dart';
import 'package:hopper/Presentation/Drawer/controller/ride_history_controller.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/custom_bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/init_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:hopper/Presentation/Authentication/screens/mobile_screens.dart';
import 'package:hopper/uber_screen.dart';

import 'package:hopper/Presentation/Authentication/screens/splash_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey =
      "pk_test_51RTgU2Qhzmr6TYhsKMWtfICaQ72crva7xVWCA0hPeV1qdH9CInnl9WwJLNcxIIUWKDhCeipRLztD82DTnBXKx05700iEGBQWjw";
  await Stripe.instance.applySettings();

  await initController();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  Widget startWidget = const SplashScreens(); // Default

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  if (token != null && token.isNotEmpty) {
    // If token exists → fetch data
    final rideHistoryController = Get.find<RideHistoryController>();
    final authController = Get.find<AuthController>();
    final profileController = Get.find<ProfleCotroller>();

    await authController. getAppSettings();
    await rideHistoryController.getRideHistory();
    await profileController.getProfileData();


    startWidget = CommonBottomNavigation(initialIndex: 0); // Go to Home
  } else {
    startWidget = const MobileScreens();
  }

  runApp(MyApp(startWidget: startWidget));
}

class MyApp extends StatelessWidget {
  final Widget startWidget;
  const MyApp({super.key, required this.startWidget});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      child: GetMaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.commonWhite,
          textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: Colors.black,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: startWidget,
      ),
    );
  }
}
