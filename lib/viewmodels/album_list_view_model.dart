import 'package:flutter/foundation.dart';

import '../models/album.dart';
import '../services/album_api_service.dart';

class AlbumListViewModel extends ChangeNotifier {
  AlbumListViewModel({AlbumApiService? api}) : _api = api ?? AlbumApiService() {
    loadAlbums();
  }

  final AlbumApiService _api;
  final List<Album> _albums = [];

  bool isLoading = false;
  String? errorMessage;

  List<Album> get albums => List.unmodifiable(_albums);

  Future<void> loadAlbums() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _api.fetchAlbums();
      _albums
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      errorMessage = '$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Album> createAlbum(String title) async {
    final album = await _api.createAlbum(title);
    _albums.insert(0, album);
    notifyListeners();
    return album;
  }

  Future<void> updateAlbum(int id, String title) async {
    final updated = await _api.updateAlbum(id, title);
    final index = _albums.indexWhere((a) => a.id == id);
    if (index != -1) {
      _albums[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteAlbum(int id) async {
    await _api.deleteAlbum(id);
    _albums.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
