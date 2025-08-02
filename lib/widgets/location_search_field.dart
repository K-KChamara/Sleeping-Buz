import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

const kGoogleApiKey = "AIzaSyCGxGNbT5Xq3LL9ewON-YQQx3BeinXhoDY"; // Replace with your API key

class LocationSearchField extends StatelessWidget {
  final Function(String) onPlaceSelected;

  const LocationSearchField({super.key, required this.onPlaceSelected});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        Prediction? prediction = await PlacesAutocomplete.show(
          context: context,
          apiKey: kGoogleApiKey,
          mode: Mode.overlay,
          language: "en",
          components: [Component(Component.country, "lk")], // For Sri Lanka
        );

        if (prediction != null) {
          onPlaceSelected(prediction.description!);
        }
      },
      child: const Text("Search for Location"),
    );
  }
}
