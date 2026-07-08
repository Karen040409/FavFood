import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/album.dart';

const _baseUrl = 'https://jsonplaceholder.typicode.com/albums';

class AlbumApiService {
  AlbumApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token != null) {
      return {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        'Accept': 'application/json',
      };
    }
    return {
      HttpHeaders.authorizationHeader: 'Basic your_api_token_here',
      'Accept': 'application/json',
    };
  }

  Future<List<Album>> fetchAlbums() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl?_limit=20'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => Album.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load albums');
  }

  Future<Album> fetchAlbum(int id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load album');
  }

  Future<Album> createAlbum(String title) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...await _authHeaders(),
      },
      body: jsonEncode(<String, dynamic>{'title': title, 'userId': 1}),
    );

    if (response.statusCode == 201) {
      return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create album (${response.statusCode}).');
  }

  Future<Album> updateAlbum(int id, String title) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...await _authHeaders(),
      },
      body: jsonEncode(<String, dynamic>{'title': title, 'userId': 1}),
    );

    if (response.statusCode == 200) {
      return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update album (${response.statusCode}).');
  }

  Future<void> deleteAlbum(int id) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...await _authHeaders(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete album.');
    }
  }
}
