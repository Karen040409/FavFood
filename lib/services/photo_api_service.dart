import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/photo.dart';

List<Photo> parsePhotos(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List<Object?>)
      .cast<Map<String, Object?>>();

  return parsed
      .map((json) => Photo.fromJson(Map<String, dynamic>.from(json)))
      .toList();
}

Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await client.get(
    Uri.parse('https://jsonplaceholder.typicode.com/photos?_limit=100'),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load photos (${response.statusCode})');
  }

  return compute(parsePhotos, response.body);
}
