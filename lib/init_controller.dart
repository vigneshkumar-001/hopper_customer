import 'package:hopper/Presentation/Authentication/controller/authcontroller.dart';
import 'package:get/get.dart';

Future<void> initController() async {
  Get.lazyPut(() => AuthController());
}
