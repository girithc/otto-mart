import 'dart:convert';

import 'package:pronto/home/models/prediction_auto_complete.dart';

class PlaceAutoCompleteResponse {
  final String? status;
  final List<PredictionAutoComplete>? predictions;

  PlaceAutoCompleteResponse({this.status, this.predictions});

  factory PlaceAutoCompleteResponse.fromJson(Map<String, dynamic> json) {
    return PlaceAutoCompleteResponse(
      status: json['status'] as String?,
      predictions: json['predictions'] != null
          ? json['predictions']
              .map<PredictionAutoComplete>(
                  (json) => PredictionAutoComplete.fromJson(json))
              .toList()
          : null,
    );
  }

  static PlaceAutoCompleteResponse parseAutocompleteResult(
      String responseBody) {
    print("(PlaceAutoCompleteResponse) Response Body: $responseBody");
    final parsed = json.decode(responseBody).cast<String, dynamic>();

    return PlaceAutoCompleteResponse.fromJson(parsed);
  }
}
