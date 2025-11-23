import 'package:costing_master/model/info_model.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

class InfoScreen extends ConsumerStatefulWidget {
  final String clientName;
  final InfoModel? info;

  final void Function(InfoModel) infoUpdate;
  final void Function(bool) setIsNavigationDisabled;
  final void Function(bool)? setIsFormValid;

  const InfoScreen({
    super.key,
    required this.clientName,
    required this.infoUpdate,
    required this.setIsNavigationDisabled,
    required this.info,
    this.setIsFormValid,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => InfoState();
}

class InfoState extends ConsumerState<InfoScreen> {
  late final TextEditingController sariNameController;
  late final TextEditingController designNoController;

  String sariName = '';
  String designNo = '';
  final ImagePicker _picker = ImagePicker();
  String? url;
  UploadTask? uploadTask;
  bool isImageUploading = false;

  File? _image;
  String? sariNameError;
  String? imageError;
  bool hasValidated = false;

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
      // Save the image TODO: fix following line
      // await GallerySaver.saveImage(_image!.path);
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   sariNameController = TextEditingController(text: widget.info?.sariName);
  //   designNoController =
  //       TextEditingController(text: widget.info?.designNo.toString() ?? '0');
  //   url = widget.info?.imageUrl;
  //   // Update form validity after init
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _updateFormValidity();
  //   });
  // }
  @override
  void initState() {
    super.initState();
    sariNameController =
        TextEditingController(text: widget.info?.sariName ?? '');
    designNoController =
        TextEditingController(text: widget.info?.designNo?.toString() ?? '');

    // Set initial URL if editing
    if (widget.info != null &&
        widget.info!.imageUrl.isNotEmpty &&
        widget.info!.imageUrl != 'null') {
      url = widget.info!.imageUrl;
    }

    // Update form validity after init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFormValidity();
    });
  }

  bool _isFormValid() {
    final sariNameValid = sariNameController.text.trim().isNotEmpty;
    final imageValid = url != null && url!.isNotEmpty && url != 'null';
    return sariNameValid && imageValid;
  }

  void _updateFormValidity() {
    if (widget.setIsFormValid != null) {
      widget.setIsFormValid!(_isFormValid());
    }
  }

  bool _validate() {
    setState(() {
      hasValidated = true;
      sariNameError = null;
      imageError = null;

      if (sariNameController.text.trim().isEmpty) {
        sariNameError = 'Sari Name is required';
      }

      if (url == null || url!.isEmpty || url == 'null') {
        imageError = 'Image is required';
      }
    });

    _updateFormValidity();
    return sariNameError == null && imageError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Name - Simple text, no card
            Text(
              widget.clientName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 20),
            // Sari Name and Design Number in one row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Sari Name *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      TextField(
                        controller: sariNameController,
                        onChanged: (sariName) {
                          if (hasValidated) {
                            setState(() {
                              sariNameError = sariName.trim().isEmpty
                                  ? 'Sari Name is required'
                                  : null;
                            });
                          }
                          _updateFormValidity();
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter sari name',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: hasValidated && sariNameError != null
                                  ? Colors.red.shade400
                                  : Colors.grey.shade300,
                              width: hasValidated && sariNameError != null
                                  ? 2
                                  : 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: hasValidated && sariNameError != null
                                  ? Colors.red.shade400
                                  : Colors.deepPurple.shade400,
                              width: 2,
                            ),
                          ),
                          errorText: null, // We'll show error below field
                          errorMaxLines: 1,

                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Design Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      TextField(
                        controller: designNoController,
                        onChanged: (designNo) {
                          designNoController.text = designNo;
                          _updateFormValidity();
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter number',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade400,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Show error below field only when validated and error exists
            if (hasValidated && sariNameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        sariNameError!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Image Section - No card, just content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Upload Image *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                if (isImageUploading)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Uploading image...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (url != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url!,
                            height: 200,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  url = null;
                                  if (hasValidated) {
                                    imageError = 'Image is required';
                                  }
                                });
                                _updateFormValidity();
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.red,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasValidated && imageError != null
                            ? Colors.red.shade400
                            : Colors.grey.shade300,
                        width: hasValidated && imageError != null ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasValidated && imageError != null
                                ? Colors.red.shade50
                                : Colors.deepPurple.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: hasValidated && imageError != null
                                ? Colors.red.shade400
                                : Colors.deepPurple.shade400,
                          ),
                        ),
                        if (hasValidated && imageError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  imageError!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 400) {
                              // Wide layout: buttons side by side
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await pickAndUploadImage(false);
                                      },
                                      icon: const Icon(Icons.photo_library,
                                          size: 18),
                                      label: const Text(
                                        'Gallery',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        backgroundColor:
                                            Colors.deepPurple.shade400,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await pickAndUploadImage(true);
                                      },
                                      icon: const Icon(Icons.camera_alt,
                                          size: 18),
                                      label: const Text(
                                        'Camera',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        backgroundColor:
                                            Colors.deepPurple.shade600,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Narrow layout: buttons stacked vertically
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await pickAndUploadImage(false);
                                      },
                                      icon: const Icon(Icons.photo_library,
                                          size: 20),
                                      label: const Text(
                                        'Pick from Gallery',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        backgroundColor:
                                            Colors.deepPurple.shade400,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await pickAndUploadImage(true);
                                      },
                                      icon: const Icon(Icons.camera_alt,
                                          size: 20),
                                      label: const Text(
                                        'Capture Image',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        backgroundColor:
                                            Colors.deepPurple.shade600,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // bool validateAndSave() {
  //   if (!_validate()) {
  //     return false;
  //   }

  //   widget.infoUpdate(
  //     InfoModel(
  //       clientName: widget.clientName,
  //       sariName: sariNameController.text.trim(),
  //       designNo: int.tryParse(designNoController.text),
  //       imageUrl: url!,
  //     ),
  //   );
  //   return true;
  // }
  bool validateAndSave() {
    if (!_validate()) {
      return false;
    }

    widget.infoUpdate(
      InfoModel(
        clientName: widget.clientName,
        sariName: sariNameController.text.trim(),
        designNo: designNoController.text.trim().isEmpty
            ? null
            : int.tryParse(designNoController.text),
        imageUrl: url!,
      ),
    );
    return true;
  }

  Future saveInfoModelToParent() async {
    widget.infoUpdate(
      InfoModel(
        clientName: widget.clientName,
        sariName: sariNameController.text.trim(),
        designNo: designNoController.text.trim().isEmpty
            ? null
            : int.tryParse(designNoController.text),
        imageUrl: url ?? '',
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
        if (hasValidated) {
          imageError = null;
        }
      });
      _updateFormValidity();
    } else {
      log('No image selected.');
    }
    setState(() {
      isImageUploading = false;
    });
    widget.setIsNavigationDisabled(false);
  }
}
