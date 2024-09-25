import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

class PickImage extends ConsumerStatefulWidget {
  const PickImage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PickImageState();
}

class _PickImageState extends ConsumerState<PickImage> {
  // firebase_storage.FirebaseStorage storage =
  //     firebase_storage.FirebaseStorage.instance;

  final GlobalKey _globalKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  UploadTask? uploadTask;

  // Function to pick an image
  Future<void> imageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        uploadFile();
      } else {
        log('No image selected.');
      }
    });
  }

  Future imageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        uploadFile();
      } else {
        log('No image selected.');
      }
    });
  }

  Future uploadFile() async {
    final path = "files/$_image";
    final file = File(_image!.path);

    final ref = FirebaseStorage.instance.ref().child(path);
    ref.putFile(file);

    uploadTask = ref.putFile(file);
    final snapshot = await uploadTask!.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();
    log("url is -- $urlDownload");
  }

  Future showPicker() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData =
        await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      final result = await ImageGallerySaver.saveImage(
          quality: 100, byteData.buffer.asUint8List());
      log(result);
    }
  }

  Future<void> saveToGallery() async {
    if (_image != null) {
      // Save the image
      await GallerySaver.saveImage(_image!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Image"),
      ),
      body: const Center(),
    );
  }
}
