import 'package:camera/camera.dart';
import 'package:camera_project/controller/scan_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraView extends StatelessWidget {
  const CameraView({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return controller.isCameraInitialized()
              ? Column(
                  children: [
                    CameraPreview(controller.cameraController),
                    ElevatedButton(
                      onPressed: () {
                        controller.zoomOut(controller.cameraController);
                      },
                      child: const Text(
                        'Zoom Out',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text("Loading preview"),
                );
        },
      ),
    );
  }
}
