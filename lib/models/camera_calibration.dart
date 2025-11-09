class CameraCalibration {
  final List<double> cameraMatrix;
  final List<double> distortionCoefficients;
  final int? imageWidth;
  final int? imageHeight;

  CameraCalibration({
    required this.cameraMatrix,
    required this.distortionCoefficients,
    this.imageWidth,
    this.imageHeight,
  });

  Map<String, dynamic> toJson() => {
    'cameraMatrix': cameraMatrix,
    'distortionCoefficients': distortionCoefficients,
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
  };

  factory CameraCalibration.fromJson(Map<String, dynamic> json) =>
      CameraCalibration(
        cameraMatrix: List<double>.from(json['cameraMatrix']),
        distortionCoefficients: List<double>.from(
          json['distortionCoefficients'],
        ),
        imageWidth: json['imageWidth'],
        imageHeight: json['imageHeight'],
      );
}
