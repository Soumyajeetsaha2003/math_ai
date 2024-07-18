import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Math AI",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orangeAccent,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? _image;
  String _solution = "";

  Future<void> _getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      ImageCropper cropper = ImageCropper();
      final croppedImage = await cropper.cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio16x9,
          CropAspectRatioPreset.ratio3x2,
        ],
      );

      setState(() {
        _image = croppedImage != null ? XFile(croppedImage.path) : null;
      });

      if (_image != null) {
        _solveMathProblem(_image!);
      }
    }
  }

  Future<void> _solveMathProblem(XFile image) async {
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyAzFRJO_z0sNMIm4r6WcRGcuEZYaojcRqA");
    final headers = {
      'Content-Type': 'application/json',
    };

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
      'prompt': {
        'text': 'Solve the math problem in this image: $base64Image',
      },
      'parameters': {
        'maxOutputTokens': 1024,
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _solution = data['content']; // API response structure
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
        setState(() {
          _solution = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        _solution = "Error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Math AI"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image == null
                ? Text("No Image Selected")
                : Image.file(File(_image!.path)),
            SizedBox(height: 20),
            _solution.isEmpty
                ? Text("Solution will be displayed here.")
                : Text("Solution:\n$_solution"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImageFromCamera,
        tooltip: "Pick image",
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
