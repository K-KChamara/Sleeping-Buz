import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

const kGoogleApiKey = "AIzaSyCGxGNbT5Xq3LL9ewON-YQQx3BeinXhoDY";

class LocationSearchField extends StatelessWidget {
  final Function(String) onPlaceSelected;

  const LocationSearchField({super.key, required this.onPlaceSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Prediction? prediction = await PlacesAutocomplete.show(
          context: context,
          apiKey: kGoogleApiKey,
          mode: Mode.overlay,
          language: "en",
          components: [Component(Component.country, "lk")],
        );

        if (prediction != null) {
          onPlaceSelected(prediction.description!);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              "Search for location...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
