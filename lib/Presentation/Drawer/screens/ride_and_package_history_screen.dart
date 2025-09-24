import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/Drawer/controller/ride_history_controller.dart';
import 'package:hopper/Presentation/OnBoarding/Widgets/package_contoiner.dart';
import 'package:get/get.dart';

/*class RideAndPackageHistoryScreen extends StatefulWidget {
  const RideAndPackageHistoryScreen({super.key});

  @override
  State<RideAndPackageHistoryScreen> createState() =>
      _RideAndPackageHistoryScreenState();
}

class _RideAndPackageHistoryScreenState
    extends State<RideAndPackageHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final RideHistoryController controller = Get.put(RideHistoryController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
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
                  CustomTextFields.textWithStyles700('History', fontSize: 20),
                  const Spacer(),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.adminChatContainerColor,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [Tab(text: 'Rides'), Tab(text: 'Package')],
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black,

                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: Colors.black, width: 3),
                        insets: EdgeInsets.symmetric(horizontal: 0),
                      ),
                      labelStyle: TextStyle(
                        color: AppColors.drawerT,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: TextStyle(
                        color: AppColors.drawerT,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.transparent,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(' '),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Obx(() {
              final data = controller.rideHistoryList;
              return Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        return await controller.getRideHistory();
                      },
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          Expanded(
                            child:
                                controller.isLoading.value
                                    ? Center(child: AppLoader.circularLoader())
                                    : data.isEmpty
                                    ? const Center(
                                      child: Text("No rides found"),
                                    )
                                    : ListView.builder(
                                      itemCount: data.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 8,
                                          ),
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color:
                                                  AppColors
                                                      .rideShareContainerColor,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CustomTextFields.textWithStyles700(
                                                    'Prime - sedan',
                                                    fontSize: 14,
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      "Completed",
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Icon(
                                                    Icons.more_vert,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),

                                              Row(
                                                children: [
                                                  Text(
                                                    "1:45 PM ",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppColors
                                                              .carTypeColor,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_right_alt_sharp,
                                                    size: 15,
                                                    color:
                                                        AppColors.carTypeColor,
                                                  ),
                                                  Text(
                                                    " 2:30 PM",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppColors
                                                              .carTypeColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          40,
                                                        ),

                                                    child: Image.network(
                                                      data[index]
                                                              .driverId
                                                              ?.profilePic
                                                              .toString() ??
                                                          '',
                                                      height: 35,
                                                      width: 35,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      CustomTextFields.textWithStyles600(
                                                        fontSize: 14,
                                                        data[index]
                                                                .driverId
                                                                ?.firstName
                                                                .toString() ??
                                                            '',
                                                      ),
                                                      CustomTextFields.textWithStylesSmall(
                                                        'KA 01 AB 1234',
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              Stack(
                                                children: [
                                                  Column(
                                                    children: [
                                                      // Pickup Address
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 2,
                                                                ),
                                                            child: Icon(
                                                              Icons.circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 12,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Pickup Address',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  data[index]
                                                                          .pickupAddress
                                                                          .toString() ??
                                                                      '',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .black54,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 5,
                                                                ),
                                                            child: Icon(
                                                              Icons.circle,
                                                              color:
                                                                  Colors.orange,
                                                              size: 12,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Delivery Address',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  data[index]
                                                                          .dropAddress
                                                                          .toString() ??
                                                                      '',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .black54,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 2,
                                                                ),
                                                                Text(
                                                                  '"Handle with care - fragile electronics"',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                    fontSize:
                                                                        12,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),

                                                  Positioned(
                                                    top: 15,
                                                    left: 5,
                                                    child: DottedLine(
                                                      direction: Axis.vertical,
                                                      lineLength: 35,
                                                      dashLength: 3,
                                                      dashColor:
                                                          AppColors
                                                              .dotLineColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),

                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.orange,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    data[index]
                                                            .driverRating
                                                            ?.rating
                                                            .toString() ??
                                                        '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      CustomTextFields.textWithImage(
                                                        text: '17.50',
                                                        fontSize: 16,
                                                        imageColors:
                                                            AppColors
                                                                .changeButtonColor,
                                                        colors:
                                                            AppColors
                                                                .changeButtonColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        imageSize: 20,
                                                        imagePath:
                                                            AppImages
                                                                .nBlackCurrency,
                                                      ),
                                                      SizedBox(height: 2),
                                                      CustomTextFields.textWithImage(
                                                        text: '280',
                                                        rightImagePath:
                                                            AppImages
                                                                .nBlackCurrency,
                                                        rightImagePathText:
                                                            ' 5.00 tip',
                                                        rightTextFontSize: 12,
                                                        fontSize: 12,
                                                        imageColors:
                                                            AppColors
                                                                .commonBlack,
                                                        colors:
                                                            AppColors
                                                                .commonBlack,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        imageSize: 15,
                                                        imagePath:
                                                            AppImages
                                                                .nBlackCurrency,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.rideShareContainerColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Electronics",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Completed",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.more_vert, size: 20),
                                ],
                              ),

                              Row(
                                children: [
                                  Text(
                                    "1:45 PM ",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.carTypeColor,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_right_alt_sharp,
                                    size: 15,
                                    color: AppColors.carTypeColor,
                                  ),
                                  Text(
                                    " 2:30 PM",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.carTypeColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  CustomTextFields.textWithStyles600(
                                    'TechStore Ltd ',
                                    fontSize: 12,
                                  ),

                                  Icon(
                                    Icons.arrow_right_alt_sharp,
                                    size: 15,
                                    color: AppColors.commonBlack,
                                  ),
                                  CustomTextFields.textWithStyles600(
                                    ' John Smith   #ORD-2024-001',
                                    fontSize: 12,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Stack(
                                children: [
                                  Column(
                                    children: [
                                      // Pickup Address
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Icon(
                                              Icons.circle,
                                              color: Colors.green,
                                              size: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pickup Address',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '123 Main Street, TechStore',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            child: Icon(
                                              Icons.circle,
                                              color: Colors.orange,
                                              size: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Delivery Address',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '456 Oak Avenue, Apt 3B',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  '"Handle with care - fragile electronics"',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  Positioned(
                                    top: 15,
                                    left: 5,
                                    child: DottedLine(
                                      direction: Axis.vertical,
                                      lineLength: 35,
                                      dashLength: 3,
                                      dashColor: AppColors.dotLineColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "4.5",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      CustomTextFields.textWithImage(
                                        text: '280',
                                        fontSize: 16,
                                        imageColors:
                                            AppColors.changeButtonColor,
                                        colors: AppColors.changeButtonColor,
                                        fontWeight: FontWeight.w600,
                                        imageSize: 20,
                                        imagePath: AppImages.nBlackCurrency,
                                      ),
                                      SizedBox(height: 2),
                                      CustomTextFields.textWithImage(
                                        text: '280',
                                        rightImagePath:
                                            AppImages.nBlackCurrency,
                                        rightImagePathText: ' 5.00 tip',
                                        rightTextFontSize: 12,
                                        fontSize: 12,
                                        imageColors: AppColors.commonBlack,
                                        colors: AppColors.commonBlack,
                                        fontWeight: FontWeight.w600,
                                        imageSize: 15,
                                        imagePath: AppImages.nBlackCurrency,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}*/

class RideAndPackageHistoryScreen extends StatefulWidget {
  const RideAndPackageHistoryScreen({Key? key}) : super(key: key);

  @override
  State<RideAndPackageHistoryScreen> createState() =>
      _RideAndPackageHistoryScreenState();
}

class _RideAndPackageHistoryScreenState
    extends State<RideAndPackageHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RideHistoryController controller = Get.put(RideHistoryController());

  @override
  void initState() {
    super.initState();
    controller.getRideHistory();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildRideList() {
    return Obx(() {
      final data = controller.rideHistoryList;
      if (controller.isLoading.value) {
        return Center(child: AppLoader.circularLoader());
      } else if (data.isEmpty) {
        return const Center(child: Text("No rides found"));
      } else {
        return RefreshIndicator(
          onRefresh: () => controller.getRideHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final ride = data[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.rideShareContainerColor),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ride type & status
                    Row(
                      children: [
                        CustomTextFields.textWithStyles700(
                          'Prime -  Sedan',
                          fontSize: 14,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ride.status == 'SUCCESS'
                                ? "Completed"
                                : ride.status.toString(),
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.more_vert, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Time
                    Row(
                      children: [
                        Text(
                          ride.rideDurationFormatted.toString() ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.carTypeColor,
                          ),
                        ),
                        // const Icon(
                        //   Icons.arrow_right_alt_sharp,
                        //   size: 15,
                        //   color: Colors.grey,
                        // ),
                        // Text(
                        //   "",
                        //   style: TextStyle(
                        //     fontSize: 13,
                        //     color: AppColors.carTypeColor,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(
                            ride.driver?.profilePic ?? '',
                            height: 35,
                            width: 35,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 35),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextFields.textWithStyles600(
                              ride.driver?.firstName ?? "",
                              fontSize: 14,
                            ),
                            CustomTextFields.textWithStylesSmall(
                              ride.driver?.carPlateNumber ?? "",
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Pickup & Drop Address
                    Stack(
                      children: [
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pickup Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ride.pickupAddress ?? "",
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Icon(
                                    Icons.circle,
                                    color: Colors.orange,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Delivery Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ride.dropAddress ?? "",
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 16,
                          left: 5,
                          child: DottedLine(
                            direction: Axis.vertical,
                            lineLength: 55,
                            dashLength: 3,
                            dashColor: AppColors.dotLineColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Rating & Price
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          ride.driverRating?.rating?.toString() ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        CustomTextFields.textWithImage(
                          text: ride.amount.toString() ?? "",
                          fontSize: 16,
                          imageColors: AppColors.changeButtonColor,
                          colors: AppColors.changeButtonColor,
                          fontWeight: FontWeight.w600,
                          imageSize: 20,
                          imagePath: AppImages.nBlackCurrency,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    });
  }

  Widget _buildParcelList() {
    return Obx(() {
      final parcels = controller.parcelHistoryList;
      if (controller.isLoading.value) {
        return Center(child: AppLoader.circularLoader());
      } else if (parcels.isEmpty) {
        return const Center(child: Text("No parcels found"));
      } else {
        return RefreshIndicator(
          onRefresh: () => controller.getRideHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: parcels.length,
            itemBuilder: (context, index) {
              final parcel = parcels[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.rideShareContainerColor),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          parcel.parcelType ?? "Parcel",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            parcel.status == 'SUCCESS'
                                ? "Completed"
                                : parcel.status.toString() ?? '',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.more_vert, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Pickup & Drop

                    // Time
                    Row(
                      children: [
                        Text(
                          parcel.rideDurationFormatted.toString() ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.carTypeColor,
                          ),
                        ),
                        // const Icon(
                        //   Icons.arrow_right_alt_sharp,
                        //   size: 15,
                        //   color: Colors.grey,
                        // ),
                        // Text(
                        //   "",
                        //   style: TextStyle(
                        //     fontSize: 13,
                        //     color: AppColors.carTypeColor,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CustomTextFields.textWithStyles600(
                          parcel.fromContactName.toString().toUpperCase() ?? '',
                          fontSize: 12,
                        ),

                        Icon(
                          Icons.arrow_right_alt_sharp,
                          size: 15,
                          color: AppColors.commonBlack,
                        ),
                        CustomTextFields.textWithStyles600(
                          ' ${parcel.toContactName.toString().toUpperCase() ?? ''}   #ORD-2024-001',
                          fontSize: 12,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pickup Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        parcel.pickupAddress ?? "",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 5),
                                  child: Icon(
                                    Icons.circle,
                                    color: Colors.orange,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delivery Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        parcel.dropAddress ?? "",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Positioned(
                          top: 16,
                          left: 5,
                          child: DottedLine(
                            direction: Axis.vertical,
                            lineLength: 55,
                            dashLength: 3,
                            dashColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          parcel.driverRating?.rating?.toString() ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '₹${parcel.total ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back & Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
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
                  CustomTextFields.textWithStyles700('History', fontSize: 20),
                  const Spacer(),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.adminChatContainerColor,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [Tab(text: 'Rides'), Tab(text: 'Package')],
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black,

                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: Colors.black, width: 3),
                        insets: EdgeInsets.symmetric(horizontal: 0),
                      ),
                      labelStyle: TextStyle(
                        color: AppColors.drawerT,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: TextStyle(
                        color: AppColors.drawerT,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.transparent,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(' '),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRideList(), _buildParcelList()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
