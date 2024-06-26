import 'dart:convert';

import 'package:pronto/home/models/prediction_auto_complete.dart';

class PlaceAutoCompleteResponse {
  final String? status;
  final List<PredictionAutoComplete>? predictions;
  //final Logger _logger = Logger();

  PlaceAutoCompleteResponse({this.status, this.predictions});

  factory PlaceAutoCompleteResponse.fromJson(Map<String, dynamic> json) {
    return PlaceAutoCompleteResponse(
      status: json['status'] as String?,
      predictions: json['predictions'] != null
          ? (json['predictions'] as List)
              .map<PredictionAutoComplete>((item) =>
                  PredictionAutoComplete.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  static PlaceAutoCompleteResponse parseAutocompleteResult(
      String responseBody) {
    // print("(PlaceAutoCompleteResponse) Response Body: $responseBody");
    final parsed = json.decode(responseBody).cast<String, dynamic>();

    //print("Parsed: $parsed");

    return PlaceAutoCompleteResponse.fromJson(parsed);
  }
}
