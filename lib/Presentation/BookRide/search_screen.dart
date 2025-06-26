import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/book_map_screen.dart';
import 'package:hopper/uitls/map/search.dart';

class BookRideSearchScreen extends StatefulWidget {
  final bool? isPickup;
  final Map<String, dynamic>? pickupData;
  final Map<String, dynamic>? destinationData;
  const BookRideSearchScreen({
    super.key,
    this.isPickup,
    this.pickupData,
    this.destinationData,
  });

  @override
  State<BookRideSearchScreen> createState() => _BookRideSearchScreenState();
}

class _BookRideSearchScreenState extends State<BookRideSearchScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  Map<String, dynamic>? _pickup;
  Map<String, dynamic>? _destination;

  List<Map<String, dynamic>> _startSearchResults = [];
  List<Map<String, dynamic>> _destSearchResults = [];

  bool _isStartFieldFocused = true;

  void _searchLocation(String value) async {
    if (value.length < 3) return;

    final results = await LocationHelper.searchPlaces(value);
    setState(() {
      if (_isStartFieldFocused) {
        _startSearchResults = results;
      } else {
        _destSearchResults = results;
      }
    });
  }

  void _handleSelection(Map<String, dynamic> item) {
    setState(() {
      if (_isStartFieldFocused) {
        _startController.text = item['description'];
        _pickup = item;
        // _startSearchResults.clear();
      } else {
        _destController.text = item['description'];
        _destination = item;
        // _destSearchResults.clear();
      }
    });

    // If both pickup and destination are selected, navigate to map screen
    if (_pickup != null && _destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => BookMapScreen(
                pickupData: _pickup!,
                destinationData: _destination!,
                pickupAddress: _pickup!['description'],
                destinationAddress: _destination!['description'],
              ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _isStartFieldFocused = widget.isPickup ?? true;

    if (widget.pickupData != null) {
      _startController.text = widget.pickupData!['description'] ?? '';
      _pickup = widget.pickupData;
    }
    if (widget.destinationData != null) {
      _destController.text = widget.destinationData!['description'] ?? '';
      _destination = widget.destinationData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsToShow =
        _isStartFieldFocused ? _startSearchResults : _destSearchResults;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          AppImages.backImage,
                          height: 19,
                          width: 19,
                        ),
                      ),
                      SizedBox(width: 12),
                      CustomTextFields.textWithStyles600(
                        'Set pick up location',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            CustomTextFields.plainTextField(
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
                              controller: _startController,
                              onChanged: _searchLocation,
                              onTap: () {
                                setState(() => _isStartFieldFocused = true);
                              },
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.dart,
                              title: 'Search for an address or landmark',
                              readOnly: false,
                            ),
                            const Divider(
                              height: 10,
                              color: AppColors.containerColor,
                            ),
                            CustomTextFields.plainTextField(
                              controller: _destController,
                              onChanged: _searchLocation,
                              onTap: () {
                                setState(() => _isStartFieldFocused = false);
                              },
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.dart,
                              title: 'Enter destination',
                              readOnly: false,
                            ),
                          ],
                        ),
                        Positioned(
                          left: 23,
                          top: 30,
                          bottom: 30,
                          child: Container(width: 1.3, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),

            // 👇 Scrollable results
            Expanded(
              child:
                  resultsToShow.isNotEmpty
                      ? ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        itemCount: resultsToShow.length,
                        itemBuilder: (context, index) {
                          final item = resultsToShow[index];
                          return ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 19),
                                SizedBox(height: 4),
                                if (item['distance'] != null)
                                  Text(
                                    item['distance'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              item['description'].split(',')[0],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item['description'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff828284),
                              ),
                            ),
                            onTap: () => _handleSelection(item),
                          );
                        },
                      )
                      : SizedBox.shrink(),
            ),

            AppButtons.button(
              hasBorder: true,
              fontSize: 14,
              borderColor: AppColors.containerColor,
              buttonColor: AppColors.commonWhite,
              textColor: AppColors.commonBlack,
              imagePath: AppImages.mapLocation,
              onTap: () {
                // _locateOnMap();
              },
              text: AppTexts.locateOnMap,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          AppImages.backImage,
                          height: 19,
                          width: 19,
                        ),
                      ),
                      SizedBox(width: 12),
                      CustomTextFields.textWithStyles600(
                        'Set pick up location',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            CustomTextFields.plainTextField(
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
                              controller: _startController,
                              onChanged: _searchLocation,

                              onTap: () {
                                setState(() => _isStartFieldFocused = true);
                              },
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.dart,
                              title: 'Search for an address or landmark',
                              readOnly: false,
                            ),
                            const Divider(
                              height: 10,
                              color: AppColors.containerColor,
                            ),
                            CustomTextFields.plainTextField(
                              controller: _destController,
                              onChanged: _searchLocation,
                              onTap: () {
                                setState(() => _isStartFieldFocused = false);
                              },
                              hintStyle: TextStyle(fontSize: 11),
                              imgHeight: 20,
                              containerColor: AppColors.commonWhite,
                              leadingImage: AppImages.dart,
                              title: 'Enter destination',
                              readOnly: false,
                            ),
                          ],
                        ),

                        Positioned(
                          left: 23,
                          top: 30,
                          bottom: 30,
                          child: Container(width: 1.3, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            if (resultsToShow.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: resultsToShow.length,
                  itemBuilder: (context, index) {
                    final item = resultsToShow[index];
                    return ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 19),
                          SizedBox(height: 4),
                          if (item['distance'] != null)
                            Text(
                              item['distance'],
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        item['description'].split(',')[0],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item['description'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff828284),
                        ),
                      ),
                      onTap: () => _handleSelection(item),
                    );
                  },
                ),
              ),

            AppButtons.button(
              hasBorder: true,
              fontSize: 14,
              borderColor: AppColors.containerColor,
              buttonColor: AppColors.commonWhite,
              textColor: AppColors.commonBlack,
              imagePath: AppImages.mapLocation,
              onTap: () {
                // _locateOnMap();
              },

              text: AppTexts.locateOnMap,
            ),
          ],
        ),
      ),
    );
  }
}
