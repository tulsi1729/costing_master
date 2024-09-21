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
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

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

  _showPicker() async {
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

  Future<void> _saveToGallery() async {
    if (_image != null) {
      // Save the image
      await GallerySaver.saveImage(_image!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Save image to gallery"),
      ),
      body: Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                _showPicker();
              },
              child: RepaintBoundary(
                key: _globalKey,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: const Column(
                    children: [
                      Text(
                        "Hello flutter ",
                        style: TextStyle(fontSize: 23),
                      ),
                      // _image != null
                      //     ? Column(
                      //         children: [
                      //           Image.file(_image!, height: 200),
                      //         ],
                      //       )
                      //     : const Text("No Image Found"),
                      Icon(Icons.abc),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 15),
              child: ElevatedButton(
                onPressed: () {
                  _saveToGallery();
                },
                child: const Text("Save"),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: imageFromGallery,
                  child: const Text('Pick Image'),
                ),
                ElevatedButton(
                  onPressed: imageFromCamera,
                  child: const Text('Capture Image'),
                ),
              ],
            ),
            Container(
              child: Column(
                children: <Widget>[
                  _image != null
                      ? Image.file(_image!, height: 300.0, width: 300.0)
                      : const Text("No Image Selected"),
                  TextButton(
                    child: const Text('Upload'),
                    onPressed: () async {
                      uploadFile();
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
