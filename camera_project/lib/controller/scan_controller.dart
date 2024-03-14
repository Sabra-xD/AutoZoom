// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTfLite();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  late CameraController cameraController;
  //Lists Cameras on the device
  late List<CameraDescription> cameras;
  late CameraImage cameraImage;
  late double currentZoomLevel = 1;
  var cameraCount = 0;
  var x, y, w, h = 0.0;
  var label = "";
  var isCameraInitialized = false.obs;

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.max);

      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;

            objectDetector(image, cameraController);
          }
          update();
        });
      });

      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

  initTfLite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage img, CameraController _cameraController) async {
    var detector = await Tflite.detectObjectOnFrame(
        bytesList: img.planes.map((e) {
          return e.bytes;
        }).toList(),
        model: "SSDMobileNet",
        asynch: true,
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numBoxesPerBlock: 1,
        numResultsPerClass: 1,
        // numResults: 1,
        rotation: 90,
        threshold: 0.4);

    if (detector != null) {
      //What does first do? As in, first element that matches?
      var ourDetectorObject = detector.first;

      // print("Result is $detector");
      if (ourDetectorObject['confidenceInClass'] != null &&
          ourDetectorObject['confidenceInClass'] * 100 > 45) {
        label = ourDetectorObject['detectedClass'].toString();
        h = ourDetectorObject['rect']['h'];
        w = ourDetectorObject['rect']['w'];
        x = ourDetectorObject['rect']['x'];
        y = ourDetectorObject['rect']['y'];
        // print("The coordinates of the thing is : h:$h w:$w x:$x y:$y");
        zoomIn(_cameraController, w, h);
      }
      update();
    }
  }

  zoomIn(CameraController _cameraController, w, h) async {
    double max = await _cameraController.getMaxZoomLevel();
    if (w < 0.5 && h < 0.5) {
      if (currentZoomLevel < max) {
        //double in the zoom.
        if (currentZoomLevel * 2 < max) {
          _cameraController.setZoomLevel(currentZoomLevel * 2);
          currentZoomLevel = currentZoomLevel * 2;
        } else {
          _cameraController.setZoomLevel(max);
          currentZoomLevel = max;
        }
      }
    }
  }

  zoomOut(CameraController _cameraControol) async {
    currentZoomLevel = 1;
    _cameraControol.setZoomLevel(1);
  }
}
