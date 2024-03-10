import 'package:hive_flutter/hive_flutter.dart';
part 'user_dto.g.dart';

@HiveType(typeId: 0)
class UserDto {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? image;
  @HiveField(3)
  FaceFeatures? faceFeatures;

  UserDto({this.name, this.faceFeatures, this.id, this.image});

  UserDto.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    image = json['image'];
    faceFeatures = json['faceFeatures'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['faceFeatures'] = faceFeatures;
    return data;
  }
}

@HiveType(typeId: 1)
class FaceFeatures {
  @HiveField(0)
  Points? rightEar;
  @HiveField(1)
  Points? leftEar;
  @HiveField(2)
  Points? rightEye;
  @HiveField(3)
  Points? leftEye;
  @HiveField(4)
  Points? rightCheek;
  @HiveField(5)
  Points? leftCheek;
  @HiveField(6)
  Points? rightMouth;
  @HiveField(7)
  Points? leftMouth;
  @HiveField(8)
  Points? noseBase;
  @HiveField(9)
  Points? bottomMouth;

  FaceFeatures({
    this.rightMouth,
    this.leftMouth,
    this.leftCheek,
    this.rightCheek,
    this.leftEye,
    this.rightEar,
    this.leftEar,
    this.rightEye,
    this.noseBase,
    this.bottomMouth,
  });

  factory FaceFeatures.fromJson(Map<String, dynamic> json) => FaceFeatures(
        rightMouth: Points.fromJson(json["rightMouth"]),
        leftMouth: Points.fromJson(json["leftMouth"]),
        leftCheek: Points.fromJson(json["leftCheek"]),
        rightCheek: Points.fromJson(json["rightCheek"]),
        leftEye: Points.fromJson(json["leftEye"]),
        rightEar: Points.fromJson(json["rightEar"]),
        leftEar: Points.fromJson(json["leftEar"]),
        rightEye: Points.fromJson(json["rightEye"]),
        noseBase: Points.fromJson(json["noseBase"]),
        bottomMouth: Points.fromJson(json["bottomMouth"]),
      );

  Map<String, dynamic> toJson() => {
        "rightMouth": rightMouth?.toJson() ?? {},
        "leftMouth": leftMouth?.toJson() ?? {},
        "leftCheek": leftCheek?.toJson() ?? {},
        "rightCheek": rightCheek?.toJson() ?? {},
        "leftEye": leftEye?.toJson() ?? {},
        "rightEar": rightEar?.toJson() ?? {},
        "leftEar": leftEar?.toJson() ?? {},
        "rightEye": rightEye?.toJson() ?? {},
        "noseBase": noseBase?.toJson() ?? {},
        "bottomMouth": bottomMouth?.toJson() ?? {},
      };
}

@HiveType(typeId: 2)
class Points {
  @HiveField(0)
  int? x;
  @HiveField(1)
  int? y;

  Points({
    required this.x,
    required this.y,
  });

  factory Points.fromJson(Map<String, dynamic> json) => Points(
        x: (json['x'] ?? 0) as int,
        y: (json['y'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}
