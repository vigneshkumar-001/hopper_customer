import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/Presentation/BookRide/Screens/book_map_screen.dart';
import 'package:hopper/Presentation/BookRide/Screens/locate_on_map_screen.dart';
import 'package:hopper/uitls/map/search.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// class _BookRideSearchScreenState extends State<BookRideSearchScreen> {
//   final TextEditingController _startController = TextEditingController();
//   final TextEditingController _destController = TextEditingController();
//   Map<String, dynamic>? _pickup;
//   Map<String, dynamic>? _destination;
//
//   List<Map<String, dynamic>> _startSearchResults = [];
//   List<Map<String, dynamic>> _destSearchResults = [];
//
//   bool _isStartFieldFocused = true;
//
//   void _searchLocation(String value) async {
//     if (value.length < 3) return;
//
//     final results = await LocationHelper.searchPlaces(value);
//     setState(() {
//       if (_isStartFieldFocused) {
//         _startSearchResults = results;
//       } else {
//         _destSearchResults = results;
//       }
//     });
//   }
//
//   // void _handleSelection(Map<String, dynamic> item) {
//   //   setState(() {
//   //     if (_isStartFieldFocused) {
//   //       _startController.text = item['description'];
//   //       _pickup = item;
//   //       // _startSearchResults.clear();
//   //     } else {
//   //       _destController.text = item['description'];
//   //       _destination = item;
//   //       // _destSearchResults.clear();
//   //     }
//   //   });
//   //
//   //   // If both pickup and destination are selected, navigate to map screen
//   //   if (_pickup != null && _destination != null) {
//   //     Navigator.push(
//   //       context,
//   //       MaterialPageRoute(
//   //         builder:
//   //             (_) => BookMapScreen(
//   //               pickupData: _pickup!,
//   //               destinationData: _destination!,
//   //               pickupAddress: _pickup!['description'],
//   //               destinationAddress: _destination!['description'],
//   //             ),
//   //       ),
//   //     );
//   //   }
//   // }
//   void _handleSelection(Map<String, dynamic> item) {
//     final selectedMapData = {
//       'description': item['description'],
//       'location': LatLng(item['lat'], item['lng']),
//     };
//
//     setState(() {
//       if (_isStartFieldFocused) {
//         _startController.text = item['description'];
//         _pickup = selectedMapData;
//       } else {
//         _destController.text = item['description'];
//         _destination = selectedMapData;
//       }
//     });
//
//     if (_pickup != null && _destination != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder:
//               (_) => BookMapScreen(
//                 pickupData: _pickup!,
//                 destinationData: _destination!,
//                 pickupAddress: _pickup!['description'],
//                 destinationAddress: _destination!['description'],
//               ),
//         ),
//       );
//     }
//   }
//
//   Future<void> _locateOnMap() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => LocateOnMapScreen(
//               searchQuery: '',
//               type: _isStartFieldFocused ? 'pickup' : 'destination',
//               cameFromPackage: false,
//             ),
//       ),
//     );
//
//     if (result != null && result['mapAddress'] != null) {
//       final selectedMapData = {
//         'description': result['mapAddress'],
//         'location': result['location'], // already LatLng
//       };
//
//       setState(() {
//         if (_isStartFieldFocused) {
//           _startController.text = result['mapAddress'];
//           _pickup = selectedMapData;
//         } else {
//           _destController.text = result['mapAddress'];
//           _destination = selectedMapData;
//         }
//       });
//
//       // ✅ If both are selected, navigate to BookMapScreen
//       if (_pickup != null && _destination != null) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (_) => BookMapScreen(
//                   pickupData: _pickup!,
//                   destinationData: _destination!,
//                   pickupAddress: _pickup!['description'],
//                   destinationAddress: _destination!['description'],
//                 ),
//           ),
//         );
//       }
//     }
//   }
//
//   /*  Future<void> _locateOnMap() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => LocateOnMapScreen(
//               searchQuery: '',
//               type: 'map',
//               cameFromPackage: false,
//             ),
//       ),
//     );
//
//     if (result != null && result['mapAddress'] != null) {
//       final selectedMapData = {
//         'description': result['mapAddress'],
//         'location': result['location'],
//       };
//
//       setState(() {
//         if (_pickup != null && _destination == null) {
//           // ✅ Pickup already filled, fill destination
//           _destController.text = result['mapAddress'];
//           _destination = selectedMapData;
//           _isStartFieldFocused = false;
//         } else {
//           // ✅ Default behavior: set pickup if destination already exists or both empty
//           _startController.text = result['mapAddress'];
//           _pickup = selectedMapData;
//           _isStartFieldFocused = true;
//         }
//       });
//
//       // If both are selected, go to BookMapScreen
//       if (_pickup != null && _destination != null) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder:
//                 (_) => BookMapScreen(
//               pickupData: _pickup!,
//               destinationData: _destination!,
//               pickupAddress: _pickup!['description'],
//               destinationAddress: _destination!['description'],
//             ),
//           ),
//         );
//
//       }
//     }
//   }*/
//
//   @override
//   void initState() {
//     super.initState();
//
//     _isStartFieldFocused = widget.isPickup ?? true;
//
//     if (widget.pickupData != null) {
//       _startController.text = widget.pickupData!['description'] ?? '';
//       _pickup = widget.pickupData;
//     }
//     if (widget.destinationData != null) {
//       _destController.text = widget.destinationData!['description'] ?? '';
//       _destination = widget.destinationData;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final resultsToShow =
//         _isStartFieldFocused ? _startSearchResults : _destSearchResults;
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Image.asset(
//                           AppImages.backImage,
//                           height: 19,
//                           width: 19,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       CustomTextFields.textWithStyles600(
//                         'Set pick up location',
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 8,
//                           offset: Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Stack(
//                       children: [
//                         Column(
//                           children: [
//                             CustomTextFields.plainTextField(
//                               hintStyle: TextStyle(fontSize: 11),
//                               imgHeight: 20,
//                               controller: _startController,
//                               onChanged: _searchLocation,
//                               onTap: () {
//                                 setState(() => _isStartFieldFocused = true);
//                               },
//                               containerColor: AppColors.commonWhite,
//                               leadingImage: AppImages.dart,
//                               title: 'Search for an address or landmark',
//                               readOnly: false,
//                             ),
//                             const Divider(
//                               height: 10,
//                               color: AppColors.containerColor,
//                             ),
//                             CustomTextFields.plainTextField(
//                               controller: _destController,
//                               onChanged: _searchLocation,
//                               onTap: () {
//                                 setState(() => _isStartFieldFocused = false);
//                               },
//                               hintStyle: TextStyle(fontSize: 11),
//                               imgHeight: 20,
//                               containerColor: AppColors.commonWhite,
//                               leadingImage: AppImages.dart,
//                               title: 'Enter destination',
//                               readOnly: false,
//                             ),
//                           ],
//                         ),
//                         Positioned(
//                           left: 23,
//                           top: 30,
//                           bottom: 30,
//                           child: Container(width: 1.3, color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                 ],
//               ),
//             ),
//
//             Expanded(
//               child:
//                   resultsToShow.isNotEmpty
//                       ? ListView.builder(
//                         padding: EdgeInsets.symmetric(horizontal: 15),
//                         itemCount: resultsToShow.length,
//                         itemBuilder: (context, index) {
//                           final item = resultsToShow[index];
//                           return ListTile(
//                             leading: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 Icon(Icons.location_on_outlined, size: 19),
//                                 SizedBox(height: 4),
//                                 if (item['distance'] != null)
//                                   Text(
//                                     item['distance'],
//                                     style: TextStyle(
//                                       fontSize: 9,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                               ],
//                             ),
//                             title: Text(
//                               item['description'].split(',')[0],
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             subtitle: Text(
//                               item['description'],
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Color(0xff828284),
//                               ),
//                             ),
//                             onTap: () => _handleSelection(item),
//                           );
//                         },
//                       )
//                       : SizedBox.shrink(),
//             ),
//
//             AppButtons.button(
//               hasBorder: true,
//               fontSize: 14,
//               borderColor: AppColors.containerColor,
//               buttonColor: AppColors.commonWhite,
//               textColor: AppColors.commonBlack,
//               imagePath: AppImages.mapLocation,
//               onTap: () {
//                 _locateOnMap();
//               },
//               text: AppTexts.locateOnMap,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
class _BookRideSearchScreenState extends State<BookRideSearchScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  List<Map<String, dynamic>> _startSearchResults = [];
  List<Map<String, dynamic>> _destSearchResults = [];
  List<String> _recentLocations = [];

  bool _isStartFieldFocused = true;

  Map<String, dynamic>? _pickup;
  Map<String, dynamic>? _destination;

  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _isStartFieldFocused = widget.isPickup ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isStartFieldFocused) {
        _pickupFocus.requestFocus();
      } else {
        _destinationFocus.requestFocus();
      }
    });

    if (widget.pickupData != null) {
      _startController.text = widget.pickupData!['description'] ?? '';
      _pickup = widget.pickupData;
    }
    if (widget.destinationData != null) {
      _destController.text = widget.destinationData!['description'] ?? '';
      _destination = widget.destinationData;
    }

    _loadRecentLocations();
  }

  Future<void> _searchLocation(String value) async {
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

  // void _goToMapScreen() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (_) => BookMapScreen(
  //             pickupData: _pickup!,
  //             destinationData: _destination!,
  //             pickupAddress: _pickup!['description'],
  //             destinationAddress: _destination!['description'],
  //           ),
  //     ),
  //   );
  // }
  void _goToMapScreen() {
    final isFromMap = ModalRoute.of(context)?.settings.arguments == 'fromMap';

    if (isFromMap) {
      Navigator.pop(context, {
        'pickup': {
          'description': _pickup!['description'],
          'lat': _pickup!['lat'],
          'lng': _pickup!['lng'],
        },
        'destination': {
          'description': _destination!['description'],
          'lat': _destination!['lat'],
          'lng': _destination!['lng'],
        },
      });
    } else {
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

  /*  void _handleSelection(Map<String, dynamic> item) {
    late final Map<String, dynamic> selectedMapData;

    if (item['location'] is LatLng) {
      selectedMapData = {
        'description': item['description'],
        'location': item['location'],
      };
    } else if (item['lat'] != null && item['lng'] != null) {
      selectedMapData = {
        'description': item['description'],
        'location': LatLng(item['lat'], item['lng']),
      };
    } else {
      // Skip handling if there's no location (can't navigate to map)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Selected location is invalid.')));
      return;
    }

    setState(() {
      if (_isStartFieldFocused) {
        _startController.text = selectedMapData['description'];
        _pickup = selectedMapData;
        _startSearchResults.clear();
      } else {
        _destController.text = selectedMapData['description'];
        _destination = selectedMapData;
        _destSearchResults.clear();
      }
    });

    // Save only if location is present
    if (selectedMapData['location'] != null) {
      _saveRecentLocation(
        selectedMapData['description'],
        selectedMapData['location'],
      );
    }

    if (_pickup != null && _destination != null) {
      _goToMapScreen();
    }
  }*/

  void _handleSelection(Map<String, dynamic> item) {
    late final Map<String, dynamic> selectedMapData;

    if (item['location'] is LatLng) {
      selectedMapData = {
        'description': item['description'],
        'location': item['location'],
      };
    } else if (item['lat'] != null && item['lng'] != null) {
      selectedMapData = {
        'description': item['description'],
        'location': LatLng(item['lat'], item['lng']),
      };
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Selected location is invalid.')));
      return;
    }

    final LatLng newLoc = selectedMapData['location'];

    if (_isStartFieldFocused &&
        _destination != null &&
        _destination!['location'] != null) {
      final LatLng destLoc = _destination!['location'];
      final distance = Geolocator.distanceBetween(
        newLoc.latitude,
        newLoc.longitude,
        destLoc.latitude,
        destLoc.longitude,
      );

      if (distance <= 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pickup and drop cannot be the same or within 1 km."),
          ),
        );
        _startController.clear();
        _pickup = null;
        return;
      }
    }

    if (!_isStartFieldFocused &&
        _pickup != null &&
        _pickup!['location'] != null) {
      final LatLng pickupLoc = _pickup!['location'];
      final distance = Geolocator.distanceBetween(
        pickupLoc.latitude,
        pickupLoc.longitude,
        newLoc.latitude,
        newLoc.longitude,
      );

      if (distance <= 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pickup and drop cannot be the same or within 1 km."),
          ),
        );
        _destController.clear();
        _destination = null;
        return;
      }
    }

    setState(() {
      if (_isStartFieldFocused) {
        _startController.text = selectedMapData['description'];
        _pickup = selectedMapData;
        _startSearchResults.clear();
      } else {
        _destController.text = selectedMapData['description'];
        _destination = selectedMapData;
        _destSearchResults.clear();
      }
    });

    _saveRecentLocation(selectedMapData['description'], newLoc);

    if (_pickup != null && _destination != null) {
      _goToMapScreen();
    }
  }

  Future<void> _locateOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocateOnMapScreen(
              searchQuery: '',
              type: _isStartFieldFocused ? 'pickup' : 'destination',
              cameFromPackage: false,
            ),
      ),
    );

    if (result != null &&
        result['mapAddress'] != null &&
        result['location'] != null &&
        result['location'] is LatLng) {
      final LatLng latLng = result['location'];

      if (_isStartFieldFocused &&
          _destination != null &&
          _destination!['location'] != null) {
        final LatLng dest = _destination!['location'];
        final distance = Geolocator.distanceBetween(
          latLng.latitude,
          latLng.longitude,
          dest.latitude,
          dest.longitude,
        );
        if (distance <= 1000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Pickup and drop cannot be the same or within 1 km.",
              ),
            ),
          );
          _startController.clear();
          _pickup = null;
          return;
        }
      }

      if (!_isStartFieldFocused &&
          _pickup != null &&
          _pickup!['location'] != null) {
        final LatLng pickup = _pickup!['location'];
        final distance = Geolocator.distanceBetween(
          pickup.latitude,
          pickup.longitude,
          latLng.latitude,
          latLng.longitude,
        );
        if (distance <= 1000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Pickup and drop cannot be the same or within 1 km.",
              ),
            ),
          );
          _destController.clear();
          _destination = null;
          return;
        }
      }

      final selectedMapData = {
        'description': result['mapAddress'],
        'location': latLng,
      };

      setState(() {
        if (_isStartFieldFocused) {
          _startController.text = result['mapAddress'];
          _pickup = selectedMapData;
          _startSearchResults.clear();
        } else {
          _destController.text = result['mapAddress'];
          _destination = selectedMapData;
          _destSearchResults.clear();
        }
      });

      _saveRecentLocation(result['mapAddress'], latLng);

      if (_pickup != null && _destination != null) {
        _goToMapScreen();
      }
    }
  }

  /*  Future<void> _locateOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocateOnMapScreen(
              searchQuery: '',
              type: _isStartFieldFocused ? 'pickup' : 'destination',
              cameFromPackage: false,
            ),
      ),
    );

    if (result != null &&
        result['mapAddress'] != null &&
        result['location'] != null &&
        result['location'] is LatLng) {
      final LatLng? latLng = result['location'] as LatLng?;
      if (latLng == null) return;

      final selectedMapData = {
        'description': result['mapAddress'],
        'location': latLng,
      };

      setState(() {
        if (_isStartFieldFocused) {
          _startController.text = result['mapAddress'];
          _pickup = selectedMapData;
          _startSearchResults.clear();
        } else {
          _destController.text = result['mapAddress'];
          _destination = selectedMapData;
          _destSearchResults.clear();
        }
      });

      _saveRecentLocation(result['mapAddress'], result['location']);

      if (_pickup != null && _destination != null) {
        _goToMapScreen();
      }
    }
  }*/

  Future<void> _saveRecentLocation(String description, LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList('recent_locations') ?? [];

    final newItem = {
      'description': description,
      'lat': location.latitude,
      'lng': location.longitude,
    };

    recent.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded['description'] == description;
      } catch (_) {
        return item == description;
      }
    });

    recent.insert(0, jsonEncode(newItem));

    if (recent.length > 5) recent = recent.sublist(0, 5);

    await prefs.setStringList('recent_locations', recent);
  }

  Future<void> _loadRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentStrings = prefs.getStringList('recent_locations') ?? [];

    setState(() {
      _recentLocations = recentStrings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsToShow =
        _isStartFieldFocused ? _startSearchResults : _destSearchResults;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
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
                                  suffixIcon:
                                      _isStartFieldFocused &&
                                              _startController.text.isNotEmpty
                                          ? IconButton(
                                            icon: Icon(Icons.close, size: 18),
                                            onPressed: () {
                                              _startController.clear();
                                              setState(() {});
                                            },
                                          )
                                          : null,
                                  hintStyle: TextStyle(fontSize: 11),
                                  imgHeight: 15,
                                  focusNode: _pickupFocus,
                                  controller: _startController,
                                  onChanged: _searchLocation,
                                  onTap:
                                      () => setState(
                                        () => _isStartFieldFocused = true,
                                      ),
                                  containerColor: AppColors.commonWhite,
                                  leadingImage: AppImages.circleStart,
                                  title: 'Search for an address or landmark',
                                  readOnly: false,
                                ),
                                const Divider(
                                  height: 10,
                                  color: AppColors.containerColor,
                                ),
                                CustomTextFields.plainTextField(
                                  focusNode: _destinationFocus,
                                  controller: _destController,
                                  onChanged: _searchLocation,
                                  onTap:
                                      () => setState(
                                        () => _isStartFieldFocused = false,
                                      ),
                                  hintStyle: TextStyle(fontSize: 11),
                                  imgHeight: 16,
                                  containerColor: AppColors.commonWhite,
                                  leadingImage: AppImages.rectangleDest,
                                  title: 'Enter destination',
                                  readOnly: false,
                                  suffixIcon:
                                      !_isStartFieldFocused &&
                                              _destController.text.isNotEmpty
                                          ? IconButton(
                                            icon: Icon(Icons.close, size: 18),
                                            onPressed: () {
                                              _destController.clear();
                                              setState(() {});
                                            },
                                          )
                                          : null,
                                ),
                              ],
                            ),
                            Positioned(
                              left: 23,
                              top: 33,
                              bottom: 33,
                              child: Container(
                                width: 1.3,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Expanded(
                child:
                    resultsToShow.isEmpty && _recentLocations.isNotEmpty
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent locations',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                ..._recentLocations.map((locString) {
                                  try {
                                    final locMap = jsonDecode(locString);
                                    return ListTile(
                                      leading: Icon(
                                        Icons.history,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      title: Text(
                                        locMap['description'],
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        final selectedMapData = {
                                          'description': locMap['description'],
                                          'location': LatLng(
                                            locMap['lat'],
                                            locMap['lng'],
                                          ),
                                        };
                                        _handleSelection(selectedMapData);
                                      },
                                    );
                                  } catch (e) {
                                    return ListTile(
                                      leading: Icon(
                                        Icons.history,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      title: Text(
                                        locString,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        final selectedMapData = {
                                          'description': locString,
                                          'location': null,
                                        };
                                        _handleSelection(selectedMapData);
                                      },
                                    );
                                  }
                                }),
                              ],
                            ),
                          ),
                        )
                        : resultsToShow.isNotEmpty
                        ? ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
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
                                  fontWeight: FontWeight.w600,
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
                onTap: _locateOnMap,
                text: AppTexts.locateOnMap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
