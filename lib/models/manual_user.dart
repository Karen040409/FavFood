/// Manual JSON serialization using dart:convert (Flutter docs).
class ManualUser {
  const ManualUser({required this.name, required this.email});

  final String name;
  final String email;

  ManualUser.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        email = json['email'] as String;

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
}

const String sampleUserJson = '''
{
  "name": "John Smith",
  "email": "john@example.com"
}
''';
