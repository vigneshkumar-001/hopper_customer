
import 'package:get/get.dart';
import 'package:hopper/Presentation/Authentication/controller/network_handling_controller.dart';
import 'package:hopper/Presentation/BookRide/Controllers/driver_search_controller.dart';
import 'package:hopper/driver_detail_controller.dart';


Future<void> initController() async {
  // Get.lazyPut(() => AuthController());
  Get.lazyPut(() => DriverController());
  Get.put(NetworkController()); // ✅ Immediately registers it

  Get.lazyPut(() => DriverSearchController());

}
