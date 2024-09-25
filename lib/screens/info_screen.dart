import 'package:costing_master/model/info_model.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

class InfoScreen extends ConsumerStatefulWidget {
  final String clientName;

  final void Function(InfoModel) infoUpdate;
  final void Function(bool) setIsNavigationDisabled;

  const InfoScreen({
    super.key,
    required this.clientName,
    required this.infoUpdate,
    required this.setIsNavigationDisabled,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => InfoState();
}

class InfoState extends ConsumerState<InfoScreen> {
  final sariNameController = TextEditingController();
  final designNoController = TextEditingController();
  String sariName = '';
  int designNo = 0;
  final ImagePicker _picker = ImagePicker();
  String? url;
  UploadTask? uploadTask;
  bool isImageUploading = false;

  File? _image;

  Future<String> uploadFile(File? image) async {
    const path = "costings/abc.png";
    final file = File(image!.path);

    final ref = FirebaseStorage.instance.ref().child(path);
    ref.putFile(file);

    uploadTask = ref.putFile(file);
    final snapshot = await uploadTask!.whenComplete(() {});
    url = await snapshot.ref.getDownloadURL();

    return url!;
  }

  Future<void> saveToGallery() async {
    if (_image != null) {
      // Save the image
      await GallerySaver.saveImage(_image!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Text(
                    widget.clientName,
                    style: const TextStyle(fontSize: 32),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: TextField(
                              controller: sariNameController,
                              onChanged: (sariName) {
                                sariNameController.text = sariName;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Sari Name',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Flexible(
                            flex: 1,
                            child: TextField(
                              controller: designNoController,
                              onChanged: (designNo) {
                                designNoController.text = designNo;
                              },
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Design Number',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isImageUploading)
              const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (url != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                      ),
                    ),
                    child: Image.network(
                      url!,
                      height: 200,

                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      // loadingBuilder: (
                      //   _,
                      //   __,
                      //   ___,
                      // ) =>
                      //     const CircularProgressIndicator(), //todo
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: -24,
                    right: -24,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          url = null;
                        });
                      },
                      icon: const Icon(
                        Icons.cancel,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    url != null
                        ? Column(
                            children: [
                              Image.network(
                                url!,
                              ),
                            ],
                          )
                        : const Text("Upload Image"),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await pickAndUploadImage(false);
                          },
                          child: const Text('Pick Image'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await pickAndUploadImage(true);
                          },
                          child: const Text('Capture Image'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future saveInfoModelToParent() async {
    widget.infoUpdate(
      InfoModel(
        clientName: widget.clientName,
        sariName: sariNameController.text,
        designNo: int.parse(designNoController.text),
        imageUrl: url.toString(),
      ),
    );
  }

  Future<void> pickAndUploadImage(bool isFromCamera) async {
    setState(() {
      isImageUploading = true;
    });
    widget.setIsNavigationDisabled(true);

    XFile? pickedFile;

    if (isFromCamera) {
      pickedFile = await _picker.pickImage(source: ImageSource.camera);
    } else {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    }
    if (pickedFile != null) {
      _image = File(pickedFile.path);

      final url1 = await uploadFile(_image);
      setState(() {
        url = url1;
      });
      log(url ?? "url is null");
    } else {
      log('No image selected.');
    }
    setState(() {
      isImageUploading = false;
    });
    widget.setIsNavigationDisabled(false);
  }
}