// import 'dart:async';
// import 'dart:isolate';
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:geodesy/features/cv/cv_service.dart';
// import 'package:geodesy/models/aruco_settings.dart';
// import 'package:geodesy/models/marker_detection.dart';



//   /// Функция изолята для распознавания маркеров
//   static void _detectionIsolate(SendPort initialSendPort) async {
//     final receivePort = ReceivePort();
//     initialSendPort.send(
//       receivePort.sendPort,
//     ); // Handshaking: отправляем SendPort изолята

//     SendPort? mainResponseSendPort; // Для отправки detections в основной поток

//     final cvService = CvService();
//     ArucoDictionary currentDictionary = ArucoDictionary.dict4x4_50;
//     PerformanceSettings currentSettings = PerformanceSettings.balanced;
//     await cvService.init(
//       dictionary: currentDictionary,
//       settings: currentSettings,
//     );

//     receivePort.listen((message) async {
//       // Первое сообщение — это SendPort основного потока для ответов
//       if (mainResponseSendPort == null && message is SendPort) {
//         mainResponseSendPort = message;
//         print(
//           'Isolate received main response SendPort: ${mainResponseSendPort.hashCode}',
//         );
//         return;
//       }

//       // Последующие сообщения — данные изображения
//       if (message is Map<String, dynamic>) {
//         final imageBytes = message['imageBytes'] as List<int>?;
//         final width = message['width'] as int?;
//         final height = message['height'] as int?;
//         final dictionary = message['dictionary'] as ArucoDictionary?;
//         final settings = message['settings'] as PerformanceSettings?;

//         // print(
//         //   'Isolate processing image: ${imageBytes?.length} bytes, $width x $height',
//         // );

//         if (imageBytes != null &&
//             width != null &&
//             height != null &&
//             dictionary != null &&
//             settings != null) {
//           // Обновить словарь только если он изменился
//           if (dictionary != currentDictionary) {
//             await cvService.changeDictionary(dictionary);
//             currentDictionary = dictionary;
//             print('Смена словаря на: ${dictionary.displayName}');
//           }

//           // Обновить настройки только если они изменились
//           if (settings != currentSettings) {
//             cvService.updatePerformanceSettings(settings);
//             currentSettings = settings;
//             print(
//               'Настройки производительности обновлены: ${settings.displayName}',
//             );
//           }

//           // Распознать маркеры
//           final detections = await cvService.detectMarkersFromImageBytes(
//             Uint8List.fromList(imageBytes),
//             width,
//             height,
//           );
//           // print(
//           //   'Sending detections from isolate: type=${detections.runtimeType}, count=${detections.length}',
//           // );
//           if (mainResponseSendPort != null) {
//             mainResponseSendPort?.send(
//               detections,
//             ); // Отправляем в правильный SendPort
//           } else {
//             print('Ошибка: mainResponseSendPort не инициализирован');
//           }
//         }
//       }
//     });
//   }