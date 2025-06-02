import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _takePictureAndUploadTwice() async {
    if (!_isCameraInitialized || _aufnr == null) return;

    setState(() {
      _loading = true;
      _result = "📸 Đang chụp và upload ảnh 1/2...";
    });

    try {
      for (int i = 1; i <= 2; i++) {
        final file = await _cameraController!.takePicture();
        final imageFile = File(file.path);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.122.15:1012/api/upload'),
        );
        request.fields['aufnr'] = _aufnr!;
        request.fields['index'] = "$i"; // gửi kèm số thứ tự ảnh (nếu cần)
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

        final response = await request.send();
        if (response.statusCode != 200) {
          setState(() {
            _result = "❌ Upload ảnh $i thất bại: ${response.statusCode}";
          });
          return;
        }

        setState(() {
          _result = "✅ Upload ảnh $i thành công!";
        });

        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // đợi nhẹ trước khi chụp tiếp
      }
    } catch (e) {
      setState(() {
        _result = "⚠️ Lỗi khi chụp hoặc upload: $e";
      });
    } finally {
      setState(() {
        _loading = false;
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
      final file = await _cameraController!.takePicture();
      final imageFile = File(file.path);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.122.15:1012/api/upload'),
      );
      request.fields['aufnr'] = _aufnr!;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

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
    } catch (e) {
      setState(() {
        _result = "⚠️ Lỗi: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });

      // ⏳ Chờ 1 giây rồi reset
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _controller.clear();
          _aufnr = null;
          _result += "\n--- Sẵn sàng nhập mã tiếp theo ---";
        });
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
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
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Center(
                            child: SizedBox(
                              width: 300,
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                decoration: const InputDecoration(
                                  labelText: "Nhập mã AUFNR (12 ký tự)",
                                  border: OutlineInputBorder(),
                                ),
                                maxLength: 12,
                                keyboardType: TextInputType.none ,
                                onSubmitted: (value) async {
                                  final trimmed = value.trim();

                                  // 🧠 Tách chuỗi nếu có định dạng CSV sau khi quét QR
                                  final parts = trimmed.split(',');
                                  String? extracted;

                                  // Lấy phần tử đầu tiên có đúng 12 chữ số
                                  for (final part in parts) {
                                    final candidate = part.trim();
                                    if (RegExp(r'^\d{12}$').hasMatch(candidate)) {
                                      extracted = candidate;
                                      break;
                                    }
                                  }

                                  if (extracted != null) {
                                    setState(() {
                                      _aufnr = extracted!;
                                      _controller.text = extracted; // hiện lại lên ô nhập
                                    });
                                    await _takePictureAndUpload();
                                  } else {
                                    setState(() {
                                      _result = "❗ Không tìm thấy mã AUFNR hợp lệ trong mã quét.";
                                      _controller.clear();
                                      _aufnr = null;
                                    });
                                    FocusScope.of(context).requestFocus(_focusNode);
                                  }
                                },

                                // onSubmitted: (value) async {
                                //   final trimmed = value.trim();
                                //   if (trimmed.length == 12) {
                                //     setState(() {
                                //       _aufnr = trimmed;
                                //     });
                                //     await _takePictureAndUpload();
                                //   } else {
                                //     setState(() {
                                //       _result = "❗ Mã AUFNR phải đúng 12 ký tự.";
                                //       _controller.clear();
                                //       _aufnr = null;
                                //     });
                                //     FocusScope.of(context).requestFocus(_focusNode);
                                //   }
                                // },
                              ),
                            ),
                          ),
                          SizedBox(width: 20,),
                          if (_isCameraInitialized && _cameraController != null)
                            Expanded(
                              child: SizedBox(
                                width: 600,
                                child: AspectRatio(
                                  aspectRatio: _cameraController!.value.aspectRatio,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            )
                          else
                            const SizedBox(
                              height: 400,
                              child: Center(
                                child: Text("Đang khởi động camera..."),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      if (_loading)
                        const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 10),
                      Text(
                        _result,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
