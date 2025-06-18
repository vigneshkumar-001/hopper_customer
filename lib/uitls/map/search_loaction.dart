import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hopper/uitls/map/google_map.dart'; // Make sure this MapScreen accepts LatLng too

class CommonLocationSearch extends StatefulWidget {
  const CommonLocationSearch({super.key});

  @override
  State<CommonLocationSearch> createState() => _CommonLocationSearchState();
}

class _CommonLocationSearchState extends State<CommonLocationSearch> {
  final TextEditingController _searchController = TextEditingController();
  final String _apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';

  List<dynamic> _searchResults = [];

  void _searchPlaces(String query) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey&components=country:in';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == 'OK') {
      setState(() {
        _searchResults = data['predictions'];
      });
    }
  }

  void _getPlaceDetailsAndNavigate(String placeId, String placeName) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  MapScreen(searchQuery: placeName, location: LatLng(lat, lng)),
        ),
      );
    }
  }

  void _locateOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapScreen(searchQuery: '')),
    );
    // final searchText = _searchController.text.trim();
    // if (searchText.isNotEmpty) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (_) => MapScreen(searchQuery: searchText)),
    //   );
    // } else {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text("Please enter an address.")));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppColors.containerColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: CustomTextFields.plainTextField(
                  hintStyle: TextStyle(fontSize: 12),
                  imgHeight: 18,

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
            ),

            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(place['description']),
                    onTap:
                        () => _getPlaceDetailsAndNavigate(
                          place['place_id'],
                          place['description'],
                        ),
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
                _locateOnMap();
              },

              text: AppTexts.locateOnMap,
            ),
          ],
        ),
      ),
    );
  }
}
