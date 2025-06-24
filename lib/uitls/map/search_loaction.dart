import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Consents/app_texts.dart';
import 'package:hopper/Core/Utility/app_buttons.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/Authentication/widgets/textfields.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hopper/uitls/map/google_map.dart'; // Make sure this MapScreen accepts LatLng too

class CommonLocationSearch extends StatefulWidget {
  final String? type;
  const CommonLocationSearch({super.key, this.type});

  @override
  State<CommonLocationSearch> createState() => _CommonLocationSearchState();
}

class _CommonLocationSearchState extends State<CommonLocationSearch> {
  final TextEditingController _searchController = TextEditingController();
  final String _apiKey = 'AIzaSyDgGqDOMvgHFLSF8okQYOEiWSe7RIgbEic';
  bool _showInfoMessage = false;

  List<dynamic> _searchResults = [];

  // void _searchPlaces(String query) async {
  //   final url =
  //       'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey&components=country:in';
  //   final response = await http.get(Uri.parse(url));
  //   final data = json.decode(response.body);
  //
  //   if (response.statusCode == 200 && data['status'] == 'OK') {
  //     setState(() {
  //       _searchResults = data['predictions'];
  //     });
  //   }
  // }
  void _searchPlaces(String query) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query'
        '&location=${position.latitude},${position.longitude}'
        '&radius=50000' // 50km
        '&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == 'OK') {
      List<dynamic> predictions = data['predictions'];

      // Run all detail fetches in parallel
      final futures = predictions.map((prediction) async {
        final placeId = prediction['place_id'];
        final detailUrl =
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

        final detailRes = await http.get(Uri.parse(detailUrl));
        final detailData = json.decode(detailRes.body);

        if (detailRes.statusCode == 200 && detailData['status'] == 'OK') {
          final location = detailData['result']['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];

          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            lat,
            lng,
          );

          prediction['distance'] = '${(distance / 1000).toStringAsFixed(1)} km';
          prediction['lat'] = lat;
          prediction['lng'] = lng;

          return prediction;
        }
        return null;
      });

      final detailedResults = await Future.wait(futures);
      final filteredResults = detailedResults.whereType<Map>().toList();

      setState(() {
        _searchResults = filteredResults;
      });
    }
  }


  void _getPlaceDetailsAndNavigate(
    String placeId,
    String placeName,
    String distance,
  ) async {
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
      MaterialPageRoute(
        builder: (_) => MapScreen(searchQuery: '', type: widget.type ?? ''),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        widget.type == 'receiver' ? 'Send to' : 'Collect from',
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
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
                      imgHeight: 18,

                      containerColor: AppColors.commonWhite,

                      onChanged: (value) {
                        setState(() {
                          _showInfoMessage = value.isNotEmpty;
                        });

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
                  SizedBox(height: 20),
                  if (!_showInfoMessage)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Update your location on the Hoppr homepage to select address from a different city',
                            style: TextStyle(
                              color: AppColors.searchDownTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      place['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(place['distance'] ?? ''),
                    onTap: () {
                      _getPlaceDetailsAndNavigate(
                        place['place_id'],
                        place['description'],
                        place['distance'] ?? '',
                      );
                      setState(() {
                        _searchResults.clear();
                        _searchController.text = '';
                        _showInfoMessage = false;
                      });
                    },
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
