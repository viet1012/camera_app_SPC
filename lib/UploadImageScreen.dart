import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Sau khi build xong thì focus vào TextField
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

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
      imageQuality: 100,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Sau khi chụp xong thì tự upload luôn
      await _uploadFile();
    }
  }



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
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: "Nhập mã AUFNR",
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                      _aufnr = null;
                      _imageFile = null;
                      _result = "";
                    });
                    FocusScope.of(context).requestFocus(_focusNode); // tự focus lại
                  },
                )
                    : null,
              ),
              onChanged: (_) {
                setState(() {}); // để cập nhật trạng thái nút clear
              },
              onSubmitted: (value) async {
                setState(() {
                  _aufnr = value.trim();
                  _result = "";
                  _imageFile = null;
                });

                if (_aufnr != null && _aufnr!.isNotEmpty) {
                  await _pickImage();
                }
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

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: (_imageFile == null || _aufnr == null) ? null : _uploadFile,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Upload ảnh"),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                SystemNavigator.pop(); // hoặc exit(0);
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text("Thoát ứng dụng"),
            ),

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
