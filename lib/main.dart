import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Presentation/Authentication/screens/splash_screens.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:hopper/init_controller.dart';
import 'package:flutter/services.dart';

import 'package:hopper/uber_screen.dart';

Future<void> main() async {
  await initController;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        home: SplashScreens(),
      ),
    );
  }
}
