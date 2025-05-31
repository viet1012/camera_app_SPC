import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'UploadImageScreen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); // Lấy danh sách camera trên thiết bị
  runApp(CameraApp());
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      home: UploadImageScreen(),
    );
  }
}