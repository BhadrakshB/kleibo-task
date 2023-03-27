// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

@HiveType(typeId: 0)
class Movie extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String directorName;
  @HiveField(2)
  Uint8List posterImage;

  @override
  bool operator ==(covariant Movie other) {
    return name == other.name && directorName == other.directorName;
  }

  @override
  String toString() =>
      "name: $name\ndirectorName: $directorName\nposterImage: ${posterImage.hashCode}";

  Movie(
      {required this.name,
      required this.directorName,
      required this.posterImage});
}

class MovieAdapter extends TypeAdapter<Movie> {
  @override
  final int typeId = 0;

  @override
  Movie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Movie(
      name: fields[0] as String,
      directorName: fields[1] as String,
      posterImage: fields[2] as Uint8List,
    );
  }

  @override
  void write(BinaryWriter writer, Movie obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.directorName)
      ..writeByte(2)
      ..write(obj.posterImage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalDB extends ChangeNotifier {
  Box<Movie> box;
  List<Movie> movies = [];
  XFile? imageDetails;
  LocalDB({
    required this.box,
  });

  Future<Box<Movie>> loadData() async {
    log("LOADING DATA");
    Box<Movie> box = await Hive.openBox('userMovies');

    movies = box.toMap().values.toList();
    log(movies.toString());
    notifyListeners();
    return box;
  }

  void addMovie(Movie movie, Function onSuccess) async {
    box.add(movie);
    movies = box.toMap().values.toList();
    onSuccess();
    notifyListeners();
  }

  void deleteMovie(Movie movie) async {
    for (var element in movies) {
      if (element == movie) {
        box.deleteAt(movies.indexOf(element));
        break;
      } else {}
    }
    movies = box.toMap().values.toList();
    notifyListeners();
  }

  void setMovie(
      {required Movie movie,
      required Function onSuccess,
      required Function onFail}) async {
    bool duplicateExists = false;
    log("RECEVIED MOVIE CLASS: ${movie.name}");

    for (var element in movies) {
      if (element == movie) {
        duplicateExists = true;
        onFail();
      } else {}
    }
    log("DUPLICATE EXISTS $duplicateExists");
    !duplicateExists ? addMovie(movie, onSuccess) : {};
    log("$movies");
  }

  void receiveImage() async {
    final ImagePicker _picker = ImagePicker();
    log("STARTED IMAGE PICKING");
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    log("RECEIVED IMAGE: ${image?.name ?? "NO IMAGE"}");
    Uint8List? fileAsBytes = await image?.readAsBytes();
    imageDetails = image;
    notifyListeners();
  }
}
