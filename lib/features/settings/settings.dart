// import 'package:flutter/material.dart';
// import '../../models/aruco_settings.dart';

// /// Widget für die Konfiguration der ArUco-Einstellungen
// class SettingsPanel extends StatefulWidget {
//   final ArucoDictionary currentDictionary;
//   final PerformanceSettings performanceSettings;
//   final bool showPose;
//   final ValueChanged<ArucoDictionary> onDictionaryChanged;
//   final ValueChanged<PerformanceSettings> onPerformanceChanged;
//   final ValueChanged<bool> onShowPoseChanged;

//   const SettingsPanel({
//     super.key,
//     required this.currentDictionary,
//     required this.performanceSettings,
//     required this.showPose,
//     required this.onDictionaryChanged,
//     required this.onPerformanceChanged,
//     required this.onShowPoseChanged,
//   });

//   @override
//   State<SettingsPanel> createState() => _SettingsPanelState();
// }

// class _SettingsPanelState extends State<SettingsPanel> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.black87,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             children: [
//               const Icon(Icons.settings, color: Colors.white, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'ArUco Einstellungen',
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Dictionary Auswahl
//           _buildDictionarySelector(),
//           const SizedBox(height: 16),

//           // Performance Einstellungen
//           _buildPerformanceSettings(),
//           const SizedBox(height: 16),

//           // Pose-Schätzung
//           _buildPoseSettings(),
//         ],
//       ),
//     );
//   }

//   Widget _buildDictionarySelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'ArUco Dictionary:',
//           style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.white10,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.white30),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<ArucoDictionary>(
//               value: widget.currentDictionary,
//               dropdownColor: Colors.grey[800],
//               style: const TextStyle(color: Colors.white),
//               items: ArucoDictionary.values.map((dictionary) {
//                 return DropdownMenuItem(
//                   value: dictionary,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [Text(dictionary.displayName)],
//                   ),
//                 );
//               }).toList(),
//               onChanged: (dictionary) {
//                 if (dictionary != null) {
//                   widget.onDictionaryChanged(dictionary);
//                 }
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPerformanceSettings() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Performance:',
//           style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),

//         // Downscale Factor
//         _buildSliderSetting(
//           'Skalierung',
//           widget.performanceSettings.downscaleFactor,
//           0.1,
//           1.0,
//           '${(widget.performanceSettings.downscaleFactor * 100).round()}%',
//           (value) {
//             final newSettings = widget.performanceSettings.copyWith(
//               downscaleFactor: value,
//             );
//             widget.onPerformanceChanged(newSettings);
//           },
//         ),

//         const SizedBox(height: 12),

//         // Max FPS
//         _buildSliderSetting(
//           'Max FPS',
//           widget.performanceSettings.maxFps.toDouble(),
//           10.0,
//           60.0,
//           '${widget.performanceSettings.maxFps}',
//           (value) {
//             final newSettings = widget.performanceSettings.copyWith(
//               maxFps: value.round(),
//             );
//             widget.onPerformanceChanged(newSettings);
//           },
//         ),

//         const SizedBox(height: 12),

//         // Graustufen-Modus
//         _buildSwitchSetting(
//           'Async-Verarbeitung',
//           widget.performanceSettings.useAsyncProcessing,
//           (value) {
//             final newSettings = widget.performanceSettings.copyWith(
//               useAsyncProcessing: value,
//             );
//             widget.onPerformanceChanged(newSettings);
//           },
//         ),

//         const SizedBox(height: 8),

//         // Performance-Profile
//         _buildPerformanceProfiles(),
//       ],
//     );
//   }

//   Widget _buildPerformanceProfiles() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Profile:',
//           style: TextStyle(color: Colors.white60, fontSize: 12),
//         ),
//         const SizedBox(height: 4),
//         Row(
//           children: [
//             _buildProfileButton('Schnell', PerformanceSettings.fast),
//             const SizedBox(width: 8),
//             _buildProfileButton('Ausgewogen', PerformanceSettings.balanced),
//             const SizedBox(width: 8),
//             _buildProfileButton('Qualität', PerformanceSettings.quality),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildProfileButton(String label, PerformanceSettings settings) {
//     final isSelected = _isCurrentProfile(settings);

//     return Expanded(
//       child: GestureDetector(
//         onTap: () => widget.onPerformanceChanged(settings),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           decoration: BoxDecoration(
//             color: isSelected ? Colors.blue[700] : Colors.white10,
//             borderRadius: BorderRadius.circular(6),
//             border: Border.all(
//               color: isSelected ? Colors.blue[400]! : Colors.white30,
//             ),
//           ),
//           child: Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: isSelected ? Colors.white : Colors.white70,
//               fontSize: 11,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   bool _isCurrentProfile(PerformanceSettings profile) {
//     final current = widget.performanceSettings;
//     return current.downscaleFactor == profile.downscaleFactor &&
//         current.maxFps == profile.maxFps &&
//         current.useAsyncProcessing == profile.useAsyncProcessing &&
//         current.enablePoseEstimation == profile.enablePoseEstimation;
//   }

//   Widget _buildPoseSettings() {
//     return _buildSwitchSetting(
//       'Pose-Schätzung',
//       widget.showPose,
//       widget.onShowPoseChanged,
//       subtitle: 'Benötigt Kamera-Kalibrierung',
//     );
//   }

//   Widget _buildSliderSetting(
//     String label,
//     double value,
//     double min,
//     double max,
//     String displayValue,
//     ValueChanged<double> onChanged,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(color: Colors.white60, fontSize: 12),
//             ),
//             Text(
//               displayValue,
//               style: const TextStyle(color: Colors.white, fontSize: 12),
//             ),
//           ],
//         ),
//         SliderTheme(
//           data: SliderTheme.of(context).copyWith(
//             activeTrackColor: Colors.blue[400],
//             inactiveTrackColor: Colors.white30,
//             thumbColor: Colors.blue[300],
//             overlayColor: Colors.blue.withOpacity(0.2),
//             trackHeight: 4,
//           ),
//           child: Slider(value: value, min: min, max: max, onChanged: onChanged),
//         ),
//       ],
//     );
//   }

//   Widget _buildSwitchSetting(
//     String label,
//     bool value,
//     ValueChanged<bool> onChanged, {
//     String? subtitle,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(color: Colors.white60, fontSize: 12),
//               ),
//               if (subtitle != null) ...[
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: const TextStyle(color: Colors.white38, fontSize: 10),
//                 ),
//               ],
//             ],
//           ),
//         ),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: Colors.blue[400],
//           activeTrackColor: Colors.blue[200],
//           inactiveThumbColor: Colors.white60,
//           inactiveTrackColor: Colors.white30,
//         ),
//       ],
//     );
//   }
// }
