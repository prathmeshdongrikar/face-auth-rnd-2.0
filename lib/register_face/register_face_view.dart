// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:face_auth/authenticate_face/local_auth_db.dart';
import 'package:face_auth/common/utils/custom_snackbar.dart';
import 'package:face_auth/common/utils/extract_face_feature.dart';
import 'package:face_auth/common/views/camera_view.dart';
import 'package:face_auth/common/views/custom_button.dart';
import 'package:face_auth/common/utils/extensions/size_extension.dart';
import 'package:face_auth/constants/theme.dart';
import 'package:face_auth/model/user_dto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:uuid/uuid.dart';

class RegisterFaceView extends StatefulWidget {
  const RegisterFaceView({Key? key}) : super(key: key);

  @override
  State<RegisterFaceView> createState() => _RegisterFaceViewState();
}

class _RegisterFaceViewState extends State<RegisterFaceView> {
  TextEditingController nameController = TextEditingController();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  String? _image;
  FaceFeatures? _faceFeatures;

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: appBarColor,
        title: const Text("Register User"),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scaffoldTopGradientClr,
              scaffoldBottomGradientClr,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 0.82.sh,
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(0.05.sw, 0.025.sh, 0.05.sw, 0.04.sh),
              decoration: BoxDecoration(
                color: overlayContainerClr,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0.03.sh),
                  topRight: Radius.circular(0.03.sh),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CameraView(
                    onImage: (image) {
                      setState(() {
                        _image = base64Encode(image);
                      });
                    },
                    onInputImage: (inputImage) async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: accentColor,
                          ),
                        ),
                      );
                      _faceFeatures =
                          await extractFaceFeatures(inputImage, _faceDetector);
                      setState(() {});
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'Name (Optional)',
                          hintStyle:
                              TextStyle(fontSize: 14, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          )),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (_image != null)
                  CustomButton(
                    text: "Start Registering",
                    onTap: () async {
                      if (_faceFeatures != null) {
                        final generatedId = const Uuid().v4();
                        await LocalAuthDB.addNewUser(
                            newUser: UserDto(
                          faceFeatures: _faceFeatures,
                          id: generatedId,
                          name: nameController.text.trim().isEmpty
                              ? 'User-$generatedId'
                              : nameController.text.trim(),
                          image: _image,
                        ));

                        CustomSnackBar.showToast(
                            msg: 'Face registered successfully!');

                        Navigator.of(context).pop();
                      } else {
                        CustomSnackBar.showToast(
                            isSuccess: false,
                            position: ToastGravity.TOP,
                            msg: 'Face not detected, Please try again!');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
