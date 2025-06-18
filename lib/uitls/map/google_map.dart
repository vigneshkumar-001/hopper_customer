import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final String searchQuery;
  final LatLng? location;

  const MapScreen({super.key, required this.searchQuery, this.location});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _targetLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _focusNode = FocusNode();
  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String _selectedAddress = "Fetching address...";
  List<dynamic> _searchResults = [];
  LatLng? _currentPosition;
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
      _getAddressFromLatLng(latLng); // 👈 This will update map + marker
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
    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final formattedAddress = data['results'][0]['formatted_address'];
      _updateLocation(latLng, formattedAddress);
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    const apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      final location = data['result']['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);
      final address = data['result']['formatted_address'];

      _updateLocation(latLng, address);
      _focusNode.unfocus();
      _searchResults.clear();
      _searchController.text = address;
    }
  }

  void _updateLocation(LatLng latLng, String address) {
    final markerId = const MarkerId("selected");

    setState(() {
      _targetLocation = latLng;
      _selectedAddress = address;
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

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));

    // Show info window after a small delay (map must finish updating)
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.showMarkerInfoWindow(markerId);
    });
  }

  void _onConfirmLocation() {}

  void _onConfirmLocastion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter Address Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),
                  CustomTextFields.textAndField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Your Address';
                      } /*else if (value.length != 11) {
                            return 'Must be exactly 11 digits';
                          }*/
                      return null;
                    },
                    controller: addressController,
                    tittle: 'Enter Address',
                    hintText: 'Enter Your Address',
                  ),
                  const SizedBox(height: 16),

                  CustomTextFields.textAndField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Enter landmark';
                      return null;
                    },

                    controller: landmarkController,
                    tittle: 'Land Mark',
                    hintText: 'Enter a Land Mark',
                  ),
                  const SizedBox(height: 12),
                  CustomTextFields.textAndField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Enter name';
                      return null;
                    },

                    controller: nameController,
                    tittle: 'Sender Name',
                    hintText: 'Enter Sender Name',
                  ),
                  const SizedBox(height: 12),
                  CustomTextFields.textAndField(
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Enter phone number';
                      if (value.length != 10) return 'Must be 10 digits';
                      return null;
                    },

                    inputFormatters: [LengthLimitingTextInputFormatter(20)],

                    type: TextInputType.number,
                    controller: phoneController,
                    tittle: 'Mobile Number',
                    hintText: 'Senders\'s Mobile Number',
                  ),
                  const SizedBox(height: 20),
                  AppButtons.button(
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        if (_targetLocation != null &&
                            _selectedAddress.isNotEmpty) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.pop(context, {
                            'location': _targetLocation,
                            'mapAddress': _selectedAddress,
                            'address': addressController.text.trim(),
                            'landmark': landmarkController.text.trim(),
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                          });
                        }
                      }
                    },

                    text: 'Proceed',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _targetLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _targetLocation!,
                      zoom: 17,
                    ),
                    markers: _markers,
                    onTap: (latLng) => _getAddressFromLatLng(latLng),
                  ),

                  // Search bar
                  Positioned(
                    top: 40,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
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
                            suffixIcon: IconButton(
                              onPressed: () {
                                _searchResults.clear();
                                _searchController.text = '';
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
                            readOnly: false,
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
                            children: const [
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedAddress,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16, // Increased font size
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButtons.button(
                            onTap: _onConfirmLocastion,
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
}
