import 'dart:typed_data';

class Person {
  final String identifier;
  final String name;
  final Uint8List faceJpg;
  final Uint8List templates;

  const Person({
    this.identifier = '',
    required this.name,
    required this.faceJpg,
    required this.templates,
  });

  factory Person.fromMap(Map<String, dynamic> data) {
    return Person(
      identifier: data['identifier'],
      name: data['name'],
      faceJpg: data['faceJpg'],
      templates: data['templates'],
    );
  }

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      'identifier': identifier,
      'name': name,
      'faceJpg': faceJpg,
      'templates': templates,
    };
    return map;
  }
}
