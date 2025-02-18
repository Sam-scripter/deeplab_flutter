import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wardrobe App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BodyMeasurementApp(),
    );
  }
}

class BodyMeasurementApp extends StatefulWidget {
  @override
  _BodyMeasurementAppState createState() => _BodyMeasurementAppState();
}

class _BodyMeasurementAppState extends State<BodyMeasurementApp> {
  File? _image;
  String? _height;
  String? _shoulderWidth;
  String? _waistWidth;
  String? _legLength;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });
      _sendImageToAPI(_image!);
    }
  }

  Future<void> _sendImageToAPI(File image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.145:8000/api/segment/'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var measurements = jsonDecode(responseData);
      setState(() {
        _height = measurements['height'].toString();
        _shoulderWidth = measurements['shoulder_width'].toString();
        _waistWidth = measurements['waist_width'].toString();
        _legLength = measurements['leg_length'].toString();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Measurement')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Show loading indicator
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : const Text('No image selected.'),
            const SizedBox(height: 20),
            _height != null ? Text('Height: $_height cm') : Container(),
            _shoulderWidth != null ? Text('Shoulder Width: $_shoulderWidth cm') : Container(),
            _waistWidth != null ? Text('Waist Width: $_waistWidth cm') : Container(),
            _legLength != null ? Text('Leg Length: $_legLength cm') : Container(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text('Take Photo'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('Pick from Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
