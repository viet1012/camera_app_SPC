import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AutoCameraUploadScreen extends StatefulWidget {
  const AutoCameraUploadScreen({super.key});

  @override
  State<AutoCameraUploadScreen> createState() => _AutoCameraUploadScreenState();
}

class _AutoCameraUploadScreenState extends State<AutoCameraUploadScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  String? _aufnr;
  String _result = "";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras!.first, ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _takePictureAndUpload() async {
    if (!_isCameraInitialized || _aufnr == null) return;

    setState(() {
      _loading = true;
      _result = "📸 Đang chụp và upload ảnh...";
    });

    try {

      await _cameraController!.takePicture().then((file) async {
        final imageFile = File(file.path);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.122.15:1012/api/upload'),
        );
        request.fields['aufnr'] = _aufnr!;
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

        var response = await request.send();
        if (response.statusCode == 200) {
          setState(() {
            _result = "✅ Upload thành công!";
          });
        } else {
          setState(() {
            _result = "❌ Upload thất bại: ${response.statusCode}";
          });
        }
      });
    } catch (e) {
      setState(() {
        _result = "⚠️ Lỗi: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _resetForNext();
    }
  }

  void _resetForNext() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _controller.clear();
        _aufnr = null;
        _result += "\n--- Sẵn sàng nhập mã tiếp theo ---";
      });
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tự động chụp và upload ảnh"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => SystemNavigator.pop(),
            tooltip: "Thoát ứng dụng",
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isCameraInitialized && _cameraController != null)
              SizedBox(
                height: 500,
                child: CameraPreview(_cameraController!),
              )
            else
              const SizedBox(
                height: 500,
                child: Center(child: Text("Đang khởi động camera...")),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        labelText: "Nhập mã AUFNR (12 ký tự)",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) async {
                        final trimmed = value.trim();
                        if (trimmed.length == 12) {
                          setState(() {
                            _aufnr = trimmed;
                          });
                          await _takePictureAndUpload();
                        } else {
                          setState(() {
                            _result = "❗ Mã AUFNR phải đúng 12 ký tự.";
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    if (_loading) const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(
                      _result,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }



}
