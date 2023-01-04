import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:google_ml_kit/google_ml_kit.dart';

import '../../vision_detector_views/painters/face_detector_painter.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  bool cameraAccess = false;
  String? error;
  List<CameraDescription>? cameras;
  CameraController? controller;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  @override
  void initState() {
    getCameraPerm();

    super.initState();
  }

  Future<void> getCameraPerm() async {
    try {
      final perm =
          await html.window.navigator.permissions!.query({"name": "camera"});
      if (perm.state == "denied") {
        return;
      }

      // await html.window.navigator.mediaDevices!.getUserMedia({'video': true});
      setState(() {
        cameraAccess = true;
      });

      final cameras = await availableCameras();
      setState(() {
        this.cameras = cameras;
      });

      initCam();
    } on html.DomException catch (e) {
      setState(() {
        error = '${e.name}: ${e.message}';
      });
    }
  }

  Future<void> initCam() async {
    setState(() {
      controller = CameraController(cameras![0], ResolutionPreset.max,
          enableAudio: false);
    });

    try {
      await controller!.initialize().then((_) async {
        print('camera initialized');
        //! START STREAM
        await controller!.startImageStream((CameraImage? image) {
          print('OK');
        });
        print('not ok');
      });
      setState(() {});
    } catch (e) {
      print("initCam ==> ${e.toString()}");
    }
  }

  Future _processCameraImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      final camera = cameras![0];
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      if (imageRotation == null) return;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) return;

      final planeData = image.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      final inputImage =
          InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

      // widget.onImage(inputImage);
      processImage(inputImage);
    } catch (e) {
      print("_processCameraImage ==> ${e.toString()}");
    }
  }

  Future<void> processImage(InputImage inputImage) async {
    // if (!_canProcess) return;
    // if (_isBusy) return;
    // _isBusy = true;
    // setState(() {
    //   _text = '';
    // });

    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [],
          ),
        ),
      ),
    );
  }
}

//! OLD DATA
// bool cameraAccess = false;
// String? error;
// List<CameraDescription>? cameras;
// CameraController? controller;

// final FaceDetector _faceDetector = FaceDetector(
//   options: FaceDetectorOptions(
//     enableContours: true,
//     enableClassification: true,
//   ),
// );
// bool _canProcess = true;
// bool _isBusy = false;
// CustomPaint? _customPaint;
// String? _text;

// @override
// void initState() {
//   getCameraPerm();

//   super.initState();
// }

// Future<void> getCameraPerm() async {
//   try {
//     final perm =
//         await html.window.navigator.permissions!.query({"name": "camera"});
//     if (perm.state == "denied") {
//       return;
//     }

//     // await html.window.navigator.mediaDevices!.getUserMedia({'video': true});
//     setState(() {
//       cameraAccess = true;
//     });

//     final cameras = await availableCameras();
//     setState(() {
//       this.cameras = cameras;
//     });

//     initCam();
//   } on html.DomException catch (e) {
//     setState(() {
//       error = '${e.name}: ${e.message}';
//     });
//   }
// }

// Future<void> initCam() async {
//   setState(() {
//     controller = CameraController(cameras![0], ResolutionPreset.max,
//         enableAudio: false);
//   });

//   try {
//     await controller!.initialize().then((_) async{
//       print('camera initialized');
//       //! START STREAM
//       await controller!.startImageStream((CameraImage? image) {
//         print('OK');
//       });
//       print('not ok');

//     });
//     setState(() {});
//   } catch (e) {
//     print("initCam ==> ${e.toString()}");
//   }
// }

// Future _processCameraImage(CameraImage image) async {
//   try {
//     final WriteBuffer allBytes = WriteBuffer();
//     for (final Plane plane in image.planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     final bytes = allBytes.done().buffer.asUint8List();

//     final Size imageSize =
//         Size(image.width.toDouble(), image.height.toDouble());

//     final camera = cameras![0];
//     final imageRotation =
//         InputImageRotationValue.fromRawValue(camera.sensorOrientation);
//     if (imageRotation == null) return;

//     final inputImageFormat =
//         InputImageFormatValue.fromRawValue(image.format.raw);
//     if (inputImageFormat == null) return;

//     final planeData = image.planes.map(
//       (Plane plane) {
//         return InputImagePlaneMetadata(
//           bytesPerRow: plane.bytesPerRow,
//           height: plane.height,
//           width: plane.width,
//         );
//       },
//     ).toList();

//     final inputImageData = InputImageData(
//       size: imageSize,
//       imageRotation: imageRotation,
//       inputImageFormat: inputImageFormat,
//       planeData: planeData,
//     );

//     final inputImage =
//         InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

//     // widget.onImage(inputImage);
//     processImage(inputImage);
//   } catch (e) {
//     print("_processCameraImage ==> ${e.toString()}");
//   }
// }

// Future<void> processImage(InputImage inputImage) async {
//   // if (!_canProcess) return;
//   // if (_isBusy) return;
//   // _isBusy = true;
//   // setState(() {
//   //   _text = '';
//   // });

//   final faces = await _faceDetector.processImage(inputImage);
//   if (inputImage.inputImageData?.size != null &&
//       inputImage.inputImageData?.imageRotation != null) {
//     final painter = FaceDetectorPainter(
//         faces,
//         inputImage.inputImageData!.size,
//         inputImage.inputImageData!.imageRotation);
//     _customPaint = CustomPaint(painter: painter);
//   } else {
//     String text = 'Faces found: ${faces.length}\n\n';
//     for (final face in faces) {
//       text += 'face: ${face.boundingBox}\n\n';
//     }
//     _text = text;
//     _customPaint = null;
//   }
//   _isBusy = false;
//   if (mounted) {
//     setState(() {});
//   }
// }

// @override
// void dispose() {
//   // controller?.dispose();
//   super.dispose();
// }





// Widget? _webcamWidget;
//   VideoElement _webcamVideoElement = VideoElement();

//   @override
//   void initState() {
//     super.initState();

//     // Create an video element which will be provided with stream source
//     // _webcamVideoElement = VideoElement();

//     // Register an webcam
//     ui.platformViewRegistry.registerViewFactory(
//         'webcamVideoElement', (int viewId) => _webcamVideoElement);

//     // Create video widget
//     _webcamWidget =
//         HtmlElementView(key: UniqueKey(), viewType: 'webcamVideoElement');

//     // Access the webcam stream
//     window.navigator.getUserMedia(video: true).then((MediaStream stream) {
//       _webcamVideoElement.srcObject = stream;
//     });

//     initIt();
//   }

//   void initIt() async {
//     await Future.delayed(const Duration(seconds: 1));
//     if (_webcamVideoElement.srcObject!.active!) {
//       _webcamVideoElement.play();
//     } else {
//       _webcamVideoElement.pause();
//     }
//   }