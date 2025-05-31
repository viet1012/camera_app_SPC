import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _aufnr;
  File? _imageFile;
  bool _loading = false;
  String _result = "";

  final ImagePicker _picker = ImagePicker();

  // Gọi api upload file
  Future<void> _uploadFile() async {
    if (_aufnr == null || _aufnr!.isEmpty) {
      setState(() {
        _result = "Vui lòng nhập mã AUFNR trước khi chụp ảnh.";
      });
      return;
    }
    if (_imageFile == null) {
      setState(() {
        _result = "Bạn chưa chụp ảnh.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _result = "";
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.122.15:1012/api/upload'),
      );
      request.fields['aufnr'] = _aufnr!;
      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          _result = "Upload thành công!";
        });
      } else {
        setState(() {
          _result = "Upload thất bại với mã lỗi: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Lỗi upload: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 100, // chất lượng cao nhất
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Future<void> _editImage(File file) async {
  //   final croppedFile = await ImageCropper().cropImage(
  //     sourcePath: file.path,
  //     aspectRatioPresets: [
  //       CropAspectRatioPreset.original,
  //       CropAspectRatioPreset.ratio4x3,
  //       CropAspectRatioPreset.ratio16x9,
  //     ],
  //     uiSettings: [
  //       AndroidUiSettings(
  //         toolbarTitle: 'Chỉnh sửa ảnh',
  //         toolbarColor: Colors.deepOrange,
  //         toolbarWidgetColor: Colors.white,
  //         initAspectRatio: CropAspectRatioPreset.original,
  //         lockAspectRatio: false,
  //       ),
  //       IOSUiSettings(
  //         title: 'Chỉnh sửa ảnh',
  //       ),
  //     ],
  //   );
  //
  //   if (croppedFile != null) {
  //     setState(() {
  //       _imageFile = File(croppedFile.path);
  //     });
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload ảnh theo AUFNR")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Nhập mã AUFNR",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _aufnr = value.trim();
                  _result = "";
                  _imageFile = null; // reset ảnh mỗi lần nhập mã mới
                });
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: (_aufnr == null || _aufnr!.isEmpty) ? null : _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Chụp ảnh"),
            ),

            const SizedBox(height: 10),

            if (_imageFile != null)
              Image.file(_imageFile!, height: 200),
            // if (_imageFile != null)
            //   GestureDetector(
            //     onTap: () => _editImage(_imageFile!),
            //     child: Image.file(_imageFile!, height: 200),
            //   ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: (_imageFile == null || _aufnr == null) ? null : _uploadFile,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Upload ảnh"),
            ),

            const SizedBox(height: 20),

            Text(
              _result,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            )
          ],
        ),
      ),
    );
  }
}
