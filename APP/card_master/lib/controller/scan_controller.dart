import 'dart:math';

import 'package:camera/camera.dart';
import 'package:get/get.dart';

class ScanController extends GetxController {

  late CameraController cameraController;
  late List<CameraDescription> cameras;


  var isCameraInitialized = false.obs;

  initCamera() async {
    if await Permitission.camera.request().isGranted; {
      
    }else{
      print("Camera permission is denied");
    }
  }

}
