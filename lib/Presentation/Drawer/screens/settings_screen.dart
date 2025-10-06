import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/customBottemSheet.dart';

import 'package:image_picker/image_picker.dart';

import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:get/get.dart';
import 'package:hopper/Presentation/Drawer/controller/profle_cotroller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfleCotroller controller = Get.put(ProfleCotroller());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      controller.setProfileImage(pickedFile.path);
    }
  }

  @override
  void initState() {
    super.initState();
    controller.getProfileData();
  }

  String formatDob(String dob) {
    try {
      final parsedDate = DateTime.parse(dob);
      return DateFormat("d MMMM yyyy").format(parsedDate);
    } catch (e) {
      return dob;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildMainContent(),
          Obx(() {
            return controller.isLoading.value
                ? Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(child: AppLoader.circularLoader()),
                )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget buildMainContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFD), Color(0xFFF6F7FF)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: buildSettingsContent(),
        ),
      ),
    );
  }

  Widget buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeader(),
        const SizedBox(height: 20),
        buildProfileSection(),
        buildBasicInfoForm(),
      ],
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(AppImages.backImage, height: 19, width: 19),
          ),
          const Spacer(),
          CustomTextFields.textWithStyles700('Settings', fontSize: 20),
          const Spacer(),
          Obx(
            () => GestureDetector(
              onTap: () {
                if (controller.isEditing.value) {
                  controller.saveData(_formKey);
                } else {
                  controller.toggleEdit();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.containerColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: CustomTextFields.textWithStyles600(
                  controller.isEditing.value ? "Save" : "Edit",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              Obx(() {
                final path = controller.profileImagePath.value;
                return ClipOval(
                  child:
                      path.isEmpty
                          ? Container(
                            height: 85,
                            width: 85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          )
                          : path.startsWith('http')
                          ? CachedNetworkImage(
                            imageUrl: path,
                            height: 85,
                            width: 85,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => SizedBox(
                                  height: 85,
                                  width: 85,
                                  child: const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 85,
                                  width: 85,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                          )
                          : Image.file(
                            File(path),
                            height: 85,
                            width: 85,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  height: 85,
                                  width: 85,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                );
              }),
              Obx(
                () =>
                    controller.isEditing.value
                        ? Positioned(
                          top: 25,
                          left: 30,
                          child: InkWell(
                            onTap: () {
                              pickImage();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                AppImages.camera,
                                height: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  controller.userName.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  "User ID - ${controller.userId.value}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBasicInfoForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFields.textWithStyles700('Basic Info', fontSize: 20),
            const SizedBox(height: 20),
            Obx(
              () => CustomTextFields.textField(
                filled: true,
                filledColor: AppColors.commonWhite,
                controller: controller.nameController,
                tittle: 'Your Name',
                hintText: 'Enter Your Name',
                readOnly: !controller.isEditing.value,
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => CustomTextFields.datePickerField(
                filled: true,
                filledColor: AppColors.commonWhite,
                formKey: _formKey1,
                context: context,
                title: 'Date of Birth',
                hintText: 'Select your DOB',
                controller: controller.dobController,
                readOnly: !controller.isEditing.value,
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => CustomTextFields.dropDown(
                filled: true,
                filledColor: AppColors.commonWhite,
                controller: controller.genderController,
                title: 'Gender',
                hintText: 'Select gender',
                readOnly: !controller.isEditing.value,
                onTap: () {
                  if (controller.isEditing.value) {
                    CustomBottomSheet.showOptionsBottomSheet(
                      title: 'Select Gender',
                      options: ['Male', 'Female', 'Other'],
                      context: context,
                      controller: controller.genderController,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => CustomTextFields.textField(
                filled: true,
                filledColor: AppColors.commonWhite,
                controller: controller.emailController,
                tittle: 'Your Email',
                hintText: 'Enter your Email',
                readOnly: !controller.isEditing.value,
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => CustomTextFields.mobileNumber(
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  child: Text(
                    controller.code.value.isNotEmpty
                        ? controller.code.value
                        : "+91",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                readOnly: true,
                title: 'Mobile Number',
                initialValue: controller.mobileNumber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _SettingsScreenState extends State<SettingsScreen> {
//   final ProfleCotroller controller = Get.put(ProfleCotroller());
//
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();
//
//   @override
//   void initState() {
//     super.initState();
//     controller.getProfileData();
//   }
//
//   String formatDob(String dob) {
//     try {
//       final parsedDate = DateTime.parse(dob); // parse ISO string
//       return DateFormat("d MMMM yyyy").format(parsedDate);
//       // Example: 5 March 2000
//     } catch (e) {
//       return dob;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFFFFFD), // #FFFFFD
//               Color(0xFFF6F7FF), // #F6F7FF
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             physics: BouncingScrollPhysics(),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 15,
//                     vertical: 20,
//                   ),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Image.asset(
//                           AppImages.backImage,
//                           height: 19,
//                           width: 19,
//                         ),
//                       ),
//                       const Spacer(),
//                       CustomTextFields.textWithStyles700(
//                         'Settings',
//                         fontSize: 20,
//                       ),
//                       const Spacer(),
//                       Obx(
//                         () => GestureDetector(
//                           onTap: () {
//                             if (controller.isEditing.value) {
//                               controller.saveData(_formKey);
//                             } else {
//                               controller.toggleEdit();
//                             }
//                           },
//                           child: Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 11,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: AppColors.containerColor,
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                             child: CustomTextFields.textWithStyles600(
//                               controller.isEditing.value ? "Save" : "Edit",
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 SizedBox(height: 20),
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Stack(
//                         children: [
//                           Obx(() {
//                             final path = controller.profileImagePath.value;
//
//                             return ClipOval(
//                               child:
//                                   path.isEmpty
//                                       ? Container(
//                                         height: 85,
//                                         width: 85,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.grey[300],
//                                         ),
//                                         child: const Icon(
//                                           Icons.person,
//                                           size: 40,
//                                           color: Colors.white,
//                                         ),
//                                       )
//                                       : path.startsWith('http')
//                                       ? CachedNetworkImage(
//                                         imageUrl: path,
//                                         height: 85,
//                                         width: 85,
//                                         fit: BoxFit.cover,
//                                         placeholder:
//                                             (context, url) => SizedBox(
//                                               height: 85,
//                                               width: 85,
//                                               child: const Center(
//                                                 child: SizedBox(
//                                                   height: 20,
//                                                   width: 20,
//                                                   child:
//                                                       CircularProgressIndicator(
//                                                         strokeWidth: 2,
//                                                       ),
//                                                 ),
//                                               ),
//                                             ),
//                                         errorWidget:
//                                             (context, url, error) => Container(
//                                               height: 85,
//                                               width: 85,
//                                               decoration: BoxDecoration(
//                                                 shape: BoxShape.circle,
//                                                 color: Colors.grey[300],
//                                               ),
//                                               child: const Icon(
//                                                 Icons.person,
//                                                 size: 40,
//                                                 color: Colors.white,
//                                               ),
//                                             ),
//                                       )
//                                       : Image.file(
//                                         File(path),
//                                         height: 85,
//                                         width: 85,
//                                         fit: BoxFit.cover,
//                                         errorBuilder:
//                                             (context, error, stackTrace) =>
//                                                 Container(
//                                                   height: 85,
//                                                   width: 85,
//                                                   decoration: BoxDecoration(
//                                                     shape: BoxShape.circle,
//                                                     color: Colors.grey[300],
//                                                   ),
//                                                   child: const Icon(
//                                                     Icons.person,
//                                                     size: 40,
//                                                     color: Colors.white,
//                                                   ),
//                                                 ),
//                                       ),
//                             );
//                           }),
//
//                           Obx(
//                             () =>
//                                 controller.isEditing.value
//                                     ? Positioned(
//                                       top: 25,
//                                       left: 30,
//                                       child: InkWell(
//                                         onTap: () {
//                                           pickImage();
//                                         },
//                                         child: Container(
//                                           padding: EdgeInsets.all(5),
//                                           decoration: BoxDecoration(
//                                             color: AppColors.commonWhite,
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: Image.asset(
//                                             AppImages.camera,
//                                             height: 20,
//                                             color: AppColors.commonBlack,
//                                           ),
//                                         ),
//                                       ),
//                                     )
//                                     : SizedBox.shrink(),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(width: 16),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Obx(
//                             () => Text(
//                               controller.userName.value,
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(height: 4),
//                           Obx(
//                             () => Text(
//                               "User ID - ${controller.userId.value}",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 25,
//                   ),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         CustomTextFields.textWithStyles700(
//                           'Basic Info',
//                           fontSize: 20,
//                         ),
//                         SizedBox(height: 20),
//                         Obx(
//                           () => CustomTextFields.textField(
//                             filled: true,
//                             filledColor: AppColors.commonWhite,
//                             controller: controller.nameController,
//                             tittle: 'Your Name',
//                             hintText: 'Enter Your Name',
//                             readOnly: !controller.isEditing.value,
//                           ),
//                         ),
//                         SizedBox(height: 24),
//                         Obx(
//                           () => CustomTextFields.datePickerField(
//                             filled: true,
//                             filledColor: AppColors.commonWhite,
//                             formKey: _formKey1,
//                             context: context,
//                             title: 'Date of Birth',
//                             hintText: 'Select your DOB',
//                             controller: controller.dobController,
//                             readOnly: !controller.isEditing.value,
//                           ),
//                         ),
//
//                         SizedBox(height: 24),
//                         Obx(
//                           () => CustomTextFields.dropDown(
//                             filled: true,
//                             filledColor: AppColors.commonWhite,
//                             controller: controller.genderController,
//                             title: 'Gender',
//                             hintText: 'Select gender',
//                             readOnly: !controller.isEditing.value,
//                             onTap: () {
//                               if (controller.isEditing.value) {
//                                 CustomBottomSheet.showOptionsBottomSheet(
//                                   title: 'Select Gender',
//                                   options: ['Male', 'Female', 'Other'],
//                                   context: context,
//                                   controller: controller.genderController,
//                                 );
//                               }
//                             },
//                           ),
//                         ),
//                         SizedBox(height: 24),
//                         Obx(
//                           () => CustomTextFields.textField(
//                             filled: true,
//                             filledColor: AppColors.commonWhite,
//                             controller: controller.emailController,
//                             tittle: 'Your Email',
//                             hintText: 'Enter your Email',
//                             readOnly: !controller.isEditing.value,
//                           ),
//                         ),
//
//                         SizedBox(height: 24),
//
//                         Obx(
//                           () => CustomTextFields.mobileNumber(
//                             prefixIcon: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                               ),
//                               alignment: Alignment.center,
//                               child: Text(
//                                 controller.code.value.isNotEmpty
//                                     ? controller.code.value
//                                     : "+91", // reactive value
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                             readOnly: true,
//                             title: 'Mobile Number',
//                             initialValue: controller.mobileNumber,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       controller.setProfileImage(pickedFile.path);
//     }
//   }
// }
