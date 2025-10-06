import 'package:get/get.dart';
import 'package:hopper/Presentation/Authentication/controller/network_handling_controller.dart';
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/Presentation/Drawer/controller/profle_cotroller.dart';
import 'package:hopper/Presentation/Drawer/controller/ride_history_controller.dart';
import 'package:hopper/driver_detail_controller.dart';

import 'Presentation/OnBoarding/Controller/package_controller.dart';

Future<void> initController() async {
  // Get.lazyPut(() => AuthController());
  Get.lazyPut(() => DriverController());
  Get.put(NetworkController());
  Get.put(PackageController());
  Get.put(ProfleCotroller());

  Get.lazyPut(() => DriverSearchController());
  Get.lazyPut(() => RideHistoryController());
}
