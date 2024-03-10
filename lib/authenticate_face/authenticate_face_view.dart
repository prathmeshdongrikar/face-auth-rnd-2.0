import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:face_auth/authenticate_face/local_auth_db.dart';
import 'package:face_auth/authenticate_face/scanning_animation/animated_view.dart';
import 'package:face_auth/authenticate_face/home_screen.dart';
import 'package:face_auth/common/utils/extensions/size_extension.dart';
import 'package:face_auth/common/utils/extract_face_feature.dart';
import 'package:face_auth/common/views/camera_view.dart';
import 'package:face_auth/common/views/custom_button.dart';
import 'package:face_auth/constants/theme.dart';
import 'package:face_auth/model/user_dto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_face_api/face_api.dart' as regula;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class AuthenticateFaceView extends StatefulWidget {
  const AuthenticateFaceView({Key? key}) : super(key: key);

  @override
  State<AuthenticateFaceView> createState() => _AuthenticateFaceViewState();
}

class _AuthenticateFaceViewState extends State<AuthenticateFaceView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  FaceFeatures? _faceFeatures;
  var image1 = regula.MatchFacesImage();
  var image2 = regula.MatchFacesImage();

  String _similarity = "";
  bool _canAuthenticate = false;
  List<dynamic> users = [];
  bool userExists = false;
  UserDto? loggingUser;
  bool isMatching = false;
  int trialNumber = 1;

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: appBarColor,
        title: const Text("Authenticate Face"),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constrains) => Stack(
          children: [
            Container(
              width: constrains.maxWidth,
              height: constrains.maxHeight,
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
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 0.82.sh,
                      width: double.infinity,
                      padding:
                          EdgeInsets.fromLTRB(0.05.sw, 0.025.sh, 0.05.sw, 0),
                      decoration: BoxDecoration(
                        color: overlayContainerClr,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0.03.sh),
                          topRight: Radius.circular(0.03.sh),
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CameraView(
                                onImage: (image) {
                                  _setImage(image);
                                },
                                onInputImage: (inputImage) async {
                                  setState(() => isMatching = true);
                                  _faceFeatures = await extractFaceFeatures(
                                      inputImage, _faceDetector);
                                  setState(() => isMatching = false);
                                },
                              ),
                              if (isMatching)
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 0.064.sh),
                                    child: const AnimatedView(),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          if (_canAuthenticate)
                            CustomButton(
                              text: "Authenticate",
                              onTap: () async {
                                setState(() => isMatching = true);
                                _fetchUsersAndMatchFace();
                              },
                            ),
                          SizedBox(height: 0.038.sh),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future _setImage(Uint8List imageToAuthenticate) async {
    image2.bitmap = base64Encode(imageToAuthenticate);
    image2.imageType = regula.ImageType.PRINTED;

    setState(() {
      _canAuthenticate = true;
    });
  }

  double compareFaces(FaceFeatures face1, FaceFeatures face2) {
    double distEar1 = euclideanDistance(face1.rightEar!, face1.leftEar!);
    double distEar2 = euclideanDistance(face2.rightEar!, face2.leftEar!);

    double ratioEar = distEar1 / distEar2;

    double distEye1 = euclideanDistance(face1.rightEye!, face1.leftEye!);
    double distEye2 = euclideanDistance(face2.rightEye!, face2.leftEye!);

    double ratioEye = distEye1 / distEye2;

    double distCheek1 = euclideanDistance(face1.rightCheek!, face1.leftCheek!);
    double distCheek2 = euclideanDistance(face2.rightCheek!, face2.leftCheek!);

    double ratioCheek = distCheek1 / distCheek2;

    double distMouth1 = euclideanDistance(face1.rightMouth!, face1.leftMouth!);
    double distMouth2 = euclideanDistance(face2.rightMouth!, face2.leftMouth!);

    double ratioMouth = distMouth1 / distMouth2;

    double distNoseToMouth1 =
        euclideanDistance(face1.noseBase!, face1.bottomMouth!);
    double distNoseToMouth2 =
        euclideanDistance(face2.noseBase!, face2.bottomMouth!);

    double ratioNoseToMouth = distNoseToMouth1 / distNoseToMouth2;

    double ratio =
        (ratioEye + ratioEar + ratioCheek + ratioMouth + ratioNoseToMouth) / 5;
    log(ratio.toString(), name: "Ratio");

    return ratio;
  }

// A function to calculate the Euclidean distance between two points
  double euclideanDistance(Points p1, Points p2) {
    final sqr =
        math.sqrt(math.pow((p1.x! - p2.x!), 2) + math.pow((p1.y! - p2.y!), 2));
    return sqr;
  }

  _fetchUsersAndMatchFace() async {
    if (_faceFeatures == null) {
      _showFailureDialog(
        title: "Failed to Detect",
        description: "Face not detected. Please try again.",
      );
      return;
    }

    final allUsers = await LocalAuthDB.getUsersData();
    print('Total Local Users : ${allUsers.length}');

    if (allUsers.isNotEmpty) {
      users.clear();
      for (var user in allUsers) {
        double similarity = compareFaces(_faceFeatures!, user.faceFeatures!);
        if (similarity >= 0.8 && similarity <= 1.5) {
          users.add([user, similarity]);
        }
      }
      setState(() {
        //Sorts the users based on the similarity.
        //More similar face is put first.
        users.sort((a, b) => (((a.last as double) - 1).abs())
            .compareTo(((b.last as double) - 1).abs()));
      });

      if (users.isNotEmpty) {
        print(users[0].toString());
      }

      _matchFaces();
    } else {
      _showFailureDialog(
        title: "No Users Registered",
        description:
            "Make sure users are registered first before Authenticating.",
      );
    }
  }

  _matchFaces() async {
    bool faceMatched = false;
    for (List user in users) {
      image1.bitmap = (user.first as UserDto).image;
      image1.imageType = regula.ImageType.PRINTED;

      //Face comparing logic.
      var request = regula.MatchFacesRequest();
      request.images = [image1, image2];
      dynamic value = await regula.FaceSDK.matchFaces(jsonEncode(request));

      var response = regula.MatchFacesResponse.fromJson(json.decode(value));
      dynamic str = await regula.FaceSDK.matchFacesSimilarityThresholdSplit(
          jsonEncode(response!.results), 0.75);

      var split =
          regula.MatchFacesSimilarityThresholdSplit.fromJson(json.decode(str));
      setState(() {
        _similarity = split!.matchedFaces.isNotEmpty
            ? (split.matchedFaces[0]!.similarity! * 100).toStringAsFixed(2)
            : "error";
        log("similarity: $_similarity");

        if (_similarity != "error" && double.parse(_similarity) > 90.00) {
          faceMatched = true;
          loggingUser = user.first;
        } else {
          faceMatched = false;
        }
      });

      if (faceMatched) {
        setState(() {
          isMatching = false;
        });

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HomeScreen(user: loggingUser!),
            ),
          );
        }
        break;
      }
    }

    if (!faceMatched) {
      _showFailureDialog(
        title: "Failed to Recognize",
        description: "Face doesn't match. Please try again.",
      );
    }
  }

  _showFailureDialog({
    required String title,
    required String description,
  }) {
    setState(() => isMatching = false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          content: Text(
            description,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Ok",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
