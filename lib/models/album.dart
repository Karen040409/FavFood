class Album {
  final int userId;
  final int id;
  final String title;

  const Album({required this.userId, required this.id, required this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'userId': int userId, 'id': int id, 'title': String title} => Album(
          userId: userId,
          id: id,
          title: title,
        ),
      {'id': int id, 'title': String title} => Album(
          userId: 1,
          id: id,
          title: title,
        ),
      _ => throw FormatException('Failed to load album: $json'),
    };
  }

  Map<String, dynamic> toJson() => {'userId': userId, 'id': id, 'title': title};
}
