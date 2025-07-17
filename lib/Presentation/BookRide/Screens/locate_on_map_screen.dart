import 'dart:convert';
import 'package:get/get.dart';
import 'package:hopper/Core/Consents/app_logger.dart';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Core/Utility/app_loader.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:hopper/uitls/map/search_loaction.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocateOnMapScreen extends StatefulWidget {
  final String searchQuery;
  final LatLng? location;
  final String? type;
  final String? initialAddress;
  final String? initialLandmark;
  final String? initialName;
  final String? initialPhone;
  final bool cameFromPackage;

  const LocateOnMapScreen({
    super.key,
    required this.searchQuery,
    this.location,
    this.type,
    this.initialAddress,
    this.initialLandmark,
    this.initialName,
    this.cameFromPackage = false, // default: false
    this.initialPhone,
  });

  @override
  State<LocateOnMapScreen> createState() => _LocateOnMapScreenState();
}

class _LocateOnMapScreenState extends State<LocateOnMapScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  GoogleMapController? _mapController;
  LatLng? _targetLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isDragging = false;
  bool _bottomSheetShown = false;

  final FocusNode _focusNode = FocusNode();
  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? selectedParcel;
  String _selectedAddress = "Fetching address...";
  List<dynamic> _searchResults = [];
  LatLng? _cameraPosition;
  bool _isFetchingAddress = false;

  bool _isCameraMoving = false;

  bool receiveWithOtp = true;
  List<String> parcelTypes = ['Home', 'Work', 'Other'];
  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;

    if (widget.location != null) {
      _updateLocation(
        widget.location!,
        widget.searchQuery.isNotEmpty
            ? widget.searchQuery
            : "Selected Location",
      );
    } else if (widget.searchQuery.isNotEmpty) {
      _getLocationFromQuery(widget.searchQuery);
    } else {
      _initLocation();
    }
  }

  Future<void> _getLocationFromQuery(String query) async {
    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final loc = data['results'][0]['geometry']['location'];
      final formattedAddress = data['results'][0]['formatted_address'];
      final latLng = LatLng(loc['lat'], loc['lng']);

      _updateLocation(latLng, formattedAddress);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Location not found")));
    }
  }

  Future<void> _initLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      _getAddressFromLatLng(latLng);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to get location: $e")));
    }
  }

  Future<void> _searchPlaces(String query) async {
    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey&components=country:in';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        _searchResults = data['predictions'];
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    setState(() {
      _isFetchingAddress = true;
    });
    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);
    if (!mounted) return;
    if (data['status'] == 'OK') {
      final formattedAddress = data['results'][0]['formatted_address'];
      _updateLocation(latLng, formattedAddress);
    }
    setState(() {
      _isFetchingAddress = false;
    });
  }

  Future<void> _getPlaceDetails(String placeId) async {
    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (!mounted) return;
    if (response.statusCode == 200) {
      final location = data['result']['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);
      final address = data['result']['formatted_address'];

      _updateLocation(latLng, address, shouldMoveCamera: true); // Move camera
      _focusNode.unfocus();
      _searchResults.clear();
      _searchController.text = address;
    }
  }

  void _updateLocation(
    LatLng latLng,
    String address, {
    bool shouldMoveCamera = false,
  }) {
    if (!mounted) return;
    final markerId = const MarkerId("selected");

    setState(() {
      _targetLocation = latLng;
      _selectedAddress = address;
      _searchController.text = _selectedAddress; // ✅ ADD THIS LINE
      _markers = {
        Marker(
          markerId: markerId,
          position: latLng,
          infoWindow: const InfoWindow(
            title: "Delivery Point",
            snippet: "Your delivery partner will come to this point",
          ),
        ),
      };
    });

    if (shouldMoveCamera) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    }

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(milliseconds: 500), () {
    //     _mapController?.showMarkerInfoWindow(markerId);
    //   });
    // });
  }

  void _goToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(position.latitude, position.longitude);

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body:
          _targetLocation == null
              ? Center(child: AppLoader.appLoader())
              : Stack(
                children: [
                  GoogleMap(
                    myLocationEnabled: true,

                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _targetLocation!,
                      zoom: 17,
                    ),
                    onCameraMove: (CameraPosition position) {
                      _isCameraMoving = true;
                      _isDragging = true; // hide the bubble
                      _cameraPosition = position.target;
                      setState(() {}); // update UI immediately
                    },

                    onCameraIdle: () {
                      if (_isCameraMoving && _cameraPosition != null) {
                        _isCameraMoving = false;
                        _getAddressFromLatLng(_cameraPosition!);
                        _isDragging = false; // show the bubble again
                        setState(() {});
                      }
                    },
                  ),
                  Positioned(
                    bottom: 280,
                    right: 15,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _goToCurrentLocation,
                      child: Icon(Icons.my_location, color: Colors.black),
                    ),
                  ),

                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Image.asset(
                        AppImages.pinLocation,
                        height: 40,
                        width: 25,
                      ),
                    ),
                  ),
                  if (!_isDragging)
                    Positioned(
                      top: MediaQuery.of(context).size.height / 3 + 25,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {},
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bubble
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Delivery partner will come\nto this location",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // Triangle
                              ClipPath(
                                clipper: TriangleClipper(),
                                child: Container(
                                  width: 20,
                                  height: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,

                    child: Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white70,
                            Colors.white38,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 42,
                    left: 16,
                    right: 16,
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
                              widget.type == 'receiver'
                                  ? 'Send to'
                                  : 'Collect from',
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: AppColors.containerColor.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: CustomTextFields.plainTextField(
                            onTap: () async {
                              if (widget.cameFromPackage) {
                                final result = await Get.to(
                                  () => CommonLocationSearch(
                                    Loaction: _selectedAddress,
                                    initialAddress: addressController.text,
                                    initialLandmark: landmarkController.text,
                                    initialName: nameController.text,
                                    initialPhone: phoneController.text,
                                    type: widget.type,
                                  ),
                                );

                                if (result != null &&
                                    result['mapAddress'] != null) {
                                  final locationResult = {
                                    'location': result['location'],
                                    'mapAddress': result['mapAddress'],
                                    'address': result['address'] ?? '',
                                    'landmark': result['landmark'] ?? '',
                                    'name': result['name'] ?? '',
                                    'phone': result['phone'] ?? '',
                                  };

                                  Navigator.pop(context, locationResult);
                                }
                              } else {
                                Navigator.pop(context, {
                                  'mapAddress': _selectedAddress,
                                  'location': _targetLocation,
                                });
                              }
                            },

                            autofocus: false,
                            suffixIcon: IconButton(
                              onPressed: () async {
                                if (widget.cameFromPackage) {
                                  final result = await Get.to(
                                    () => CommonLocationSearch(
                                      Loaction: _selectedAddress,
                                      initialAddress: addressController.text,
                                      initialLandmark: landmarkController.text,
                                      initialName: nameController.text,
                                      initialPhone: phoneController.text,
                                      type: widget.type,
                                    ),
                                  );

                                  if (result != null &&
                                      result['mapAddress'] != null) {
                                    final locationResult = {
                                      'location': result['location'],
                                      'mapAddress': result['mapAddress'],
                                      'address': result['address'] ?? '',
                                      'landmark': result['landmark'] ?? '',
                                      'name': result['name'] ?? '',
                                      'phone': result['phone'] ?? '',
                                    };

                                    Navigator.pop(context, locationResult);
                                  }
                                } else {
                                  Navigator.pop(context, {
                                    'mapAddress': _selectedAddress,
                                    'location': _targetLocation,
                                  });
                                }
                                // _searchResults.clear();
                                // _searchController.text = '';
                              },
                              icon: Icon(Icons.clear, size: 19),
                            ),
                            hintStyle: TextStyle(fontSize: 12),
                            imgHeight: 17,

                            containerColor: AppColors.commonWhite,

                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _searchPlaces(value);
                              } else {
                                setState(() => _searchResults.clear());
                              }
                            },
                            controller: _searchController,
                            leadingImage: AppImages.dart,
                            title: 'Search for an address or landmark',
                            readOnly: true,
                          ),
                        ),

                        if (_searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final place = _searchResults[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on),
                                  title: Text(place['description']),
                                  onTap: () {
                                    _getPlaceDetails(place['place_id']);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ), // Increased padding
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: 24,
                              ), // Slightly bigger
                              SizedBox(width: 10),
                              Text(
                                "Location",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18, // Increased size
                                ),
                              ),
                              Spacer(),
                              TextButton(
                                onPressed: () async {
                                  if (widget.cameFromPackage) {
                                    final result = await Get.to(
                                      () => CommonLocationSearch(
                                        Loaction: _selectedAddress,
                                        initialAddress: addressController.text,
                                        initialLandmark:
                                            landmarkController.text,
                                        initialName: nameController.text,
                                        initialPhone: phoneController.text,
                                        type: widget.type,
                                      ),
                                    );

                                    if (result != null &&
                                        result['mapAddress'] != null) {
                                      final locationResult = {
                                        'location': result['location'],
                                        'mapAddress': result['mapAddress'],
                                        'address': result['address'] ?? '',
                                        'landmark': result['landmark'] ?? '',
                                        'name': result['name'] ?? '',
                                        'phone': result['phone'] ?? '',
                                      };

                                      Navigator.pop(context, locationResult);
                                    }
                                  } else {
                                    Navigator.pop(context, {
                                      'mapAddress': _selectedAddress,
                                      'location': _targetLocation,
                                    });
                                  }
                                },
                                child: CustomTextFields.textWithStyles700(
                                  'Edit',
                                  fontSize: 12,
                                  color: AppColors.resendBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedAddress,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButtons.button(
                            buttonColor:
                                _isFetchingAddress
                                    ? Colors.grey
                                    : AppColors.commonBlack,
                            onTap:
                                _isFetchingAddress ? null : _onConfirmLocation,
                            text: 'Confirm Location',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  void _onConfirmLocation() {
    if (_targetLocation != null && _selectedAddress.isNotEmpty) {
      Navigator.pop(context, {
        'mapAddress': _selectedAddress,
        'location': _targetLocation,
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a location")));
    }
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
