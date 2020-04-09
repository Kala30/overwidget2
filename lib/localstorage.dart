import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class LocalStorage {

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/player_list.json');
  }

  Future writeFile(String json) async {
    final file = await _localFile;
    //print(json);
    // Write the file
    return file.writeAsString(json);
  }

  Future clearFile() async {
    final file = await _localFile;

    // Write the file
    file.writeAsString('');
    //print(file.readAsString());
  }

  Future readFile() async {
    try {
      final file = await _localFile;

      // Read the file
      String contents = await file.readAsString();
      //print(contents);
      return contents;
    } catch (e) {
      return null;
    }
  }
}