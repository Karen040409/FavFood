/// Manual model for JSON Placeholder photos (parsed in a background isolate).
class Photo {
  const Photo({
    required this.albumId,
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  final int albumId;
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      albumId: json['albumId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }

  /// JSONPlaceholder links point at via.placeholder.com (often down). Use Picsum for display.
  String get displayThumbnailUrl => 'https://picsum.photos/seed/$id/200/200';
}
