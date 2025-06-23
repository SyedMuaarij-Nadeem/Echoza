// import 'package:echoza/echoza_splash.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
// import 'custom_audio_player.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'dart:io';
// import 'successAnimation.dart';
// import 'package:file_saver/file_saver.dart';
//
//
//
// void main() {
//   runApp(EchozaApp());
// }
//
// class EchozaApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen());
//   }
// }
//
// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//   FlutterSoundPlayer _originalPlayer = FlutterSoundPlayer();
//   FlutterSoundPlayer _processedPlayer = FlutterSoundPlayer();
//   bool _isRecording = false;
//   bool _isPlaying = false;
//   double _sliderValue = 0.0;
//   Duration _audioDuration = Duration.zero;
//   Duration _currentPosition = Duration.zero;
//   String? _recordedFilePath;
//   String? _denoisedFilePath;
//   bool _isPlayingDenoised = false;
//   double _sliderValueDenoised = 0.0;
//   Duration _audioDurationDenoised = Duration.zero;
//   Duration _currentPositionDenoised = Duration.zero;
//   bool _useDenoisedAudio = false;
//   bool _useClarifiedAudio = false;
//   String? _clarifiedFilePath;
//   String? _denoisedAndClarifiedPath;
//   bool _showOriginalPlayer = false;
//   bool _showDenoisedPlayer = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initRecorder();
//   }
//
//   Future<void> _initRecorder() async {
//     await _recorder.openRecorder();
//     await _originalPlayer.openPlayer();
//     await _processedPlayer.openPlayer();
//     await Permission.microphone.request();
//     _originalPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
//     _processedPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
//   }
//
//   Future<String> _getFilePath(String name) async {
//     final dir = await getTemporaryDirectory();
//     return '${dir.path}/$name';
//   }
//
//   Future<void> _startRecording() async {
//     String filePath = await _getFilePath('recorded_audio.aac');
//
//     // Reset toggle and delete denoised file if exists
//     if (_denoisedFilePath != null) {
//       final denoisedFile = File(_denoisedFilePath!);
//       if (await denoisedFile.exists()) {
//         await denoisedFile.delete();
//         print("🗑️ Deleted existing denoised file");
//       }
//     }
//     setState(() {
//       _showOriginalPlayer = false;
//       _showDenoisedPlayer = false;
//       _useClarifiedAudio = false;
//       _useDenoisedAudio = false;
//       // _denoisedFilePath = null;
//
//     });
//
//     await _recorder.startRecorder(toFile: filePath);
//     setState(() {
//       _isRecording = true;
//       _recordedFilePath = filePath;
//     });
//     Future.delayed(Duration(minutes: 5), () {
//       if (_isRecording) {
//         _stopRecording();
//       }
//     });
//   }
//
//   Future<void> _stopRecording() async {
//     String? filePath = await _recorder.stopRecorder();
//     setState(() {
//       _isRecording = false;
//       _recordedFilePath = filePath;
//       _showOriginalPlayer = true;
//     });
//     await _applyNoiseSuppression();
//     await _applyVoiceClarification();
//     await _applyNoiseSuppressionAndClarification();
//   }
//
//   Future<void> _playPauseRecording() async {
//     if (_isPlaying) {
//       await _originalPlayer.stopPlayer();
//       setState(() => _isPlaying = false);
//     } else if (_recordedFilePath != null) {
//       _originalPlayer.onProgress?.listen((e) {
//         if (e != null && mounted) {
//           setState(() {
//             _currentPosition = e.position;
//             _audioDuration = e.duration;
//             _sliderValue = (_audioDuration.inMilliseconds > 0)
//                 ? (_currentPosition.inMilliseconds / _audioDuration.inMilliseconds).clamp(0.0, 1.0)
//                 : 0.0;
//           });
//         }
//       });
//
//       await _originalPlayer.startPlayer(
//         fromURI: _recordedFilePath!,
//         whenFinished: () => setState(() {
//           _isPlaying = false;
//           _sliderValue = 0.0;
//           _currentPosition = Duration.zero;
//         }),
//       );
//       setState(() => _isPlaying = true);
//     }
//   }
//
// // ✅ Apply Noise Suppression function
//   Future<void> _applyNoiseSuppression() async {
//     if (_recordedFilePath == null) return;
//
//     final outputPath = await _getFilePath('denoised_audio.wav');
//     String cmd =
//         "-y -i '$_recordedFilePath' -af \"afftdn,highpass=f=80,anlmdn=s=60\" '${outputPath}'";
//
//
//     try {
//       var session = await FFmpegKit.execute(cmd);
//       final returnCode = await session.getReturnCode();
//       if (returnCode != null && returnCode.isValueSuccess()) {
//         setState(() {
//           _denoisedFilePath = outputPath;
//         });
//         print("✅ Noise suppression applied successfully!");
//       } else {
//         print("❌ Failed: \${returnCode?.getValue()}");
//       }
//     } catch (e) {
//       print("❌ Error: $e");
//     }
//     if (await File(outputPath).exists()) {
//       setState(() {
//         _denoisedFilePath = outputPath;
//       });
//       print("✅ Noise suppression applied and file exists.");
//     } else {
//       print("❌ Denoised file not found after FFmpeg execution!");
//     }
//
//   }
//
//   // ✅ Apply Voice Clarification function
//   Future<void> _applyVoiceClarification({bool onFinalOutput = false}) async {
//     final inputPath = onFinalOutput
//         ? _denoisedFilePath
//         : _recordedFilePath;
//
//     if (inputPath == null) return;
//
//     final outputPath = await _getFilePath(
//         onFinalOutput ? 'denoised_and_clarified_audio.wav' : 'clarified_audio.wav');
//
//     String cmd =
//         "-y -i '$inputPath' -af \"acompressor=threshold=-18dB:ratio=3:attack=20:release=250, treble=g=3, volume=17dB\" '$outputPath'";
//
//     try {
//       var session = await FFmpegKit.execute(cmd);
//       final returnCode = await session.getReturnCode();
//       if (returnCode != null && returnCode.isValueSuccess()) {
//         setState(() {
//           if (onFinalOutput) {
//             _denoisedAndClarifiedPath = outputPath;
//           } else {
//             _clarifiedFilePath = outputPath;
//           }
//         });
//         print("✅ Voice clarification applied successfully!");
//       } else {
//         print("❌ Clarification failed: \${returnCode?.getValue()}");
//       }
//     } catch (e) {
//       print("❌ Clarification error: $e");
//     }
//   }
//
//   Future<void> _applyNoiseSuppressionAndClarification() async {
//     if (_recordedFilePath == null) return;
//
//     // Step 1: Apply Noise Suppression
//     final denoisedFilePath = await _getFilePath('denoised_audio.wav');
//     String noiseSuppressionCmd =
//         "-y -i '$_recordedFilePath' -af \"afftdn,highpass=f=80,anlmdn=s=60\" '$denoisedFilePath'";
//
//
//     try {
//       var session = await FFmpegKit.execute(noiseSuppressionCmd);
//       final returnCode = await session.getReturnCode();
//       if (returnCode != null && returnCode.isValueSuccess()) {
//         print("✅ Noise suppression applied successfully!");
//       } else {
//         print("❌ Failed: ${returnCode?.getValue()}");
//         return;
//       }
//     } catch (e) {
//       print("❌ Error applying noise suppression: $e");
//       return;
//     }
//
//     // Step 2: Apply Voice Clarification to the Denoised Audio
//     final clarifiedFilePath = await _getFilePath('denoised_and_clarified_audio.wav');
//     String clarificationCmd =
//         "-y -i '$denoisedFilePath' -af \"acompressor=threshold=-18dB:ratio=3:attack=20:release=250, treble=g=3, volume=17dB\" '$clarifiedFilePath'";
//
//
//     try {
//       var session = await FFmpegKit.execute(clarificationCmd);
//       final returnCode = await session.getReturnCode();
//       if (returnCode != null && returnCode.isValueSuccess()) {
//         setState(() {
//           _denoisedAndClarifiedPath = clarifiedFilePath;
//         });
//         print("✅ Voice clarification applied successfully!");
//       } else {
//         print("❌ Failed: ${returnCode?.getValue()}");
//       }
//     } catch (e) {
//       print("❌ Error applying voice clarification: $e");
//     }
//   }
//
//
//
//   Future<void> _playPauseProcessed() async {
//     // Immediately toggle state to reflect UI change
//     setState(() => _isPlayingDenoised = !_isPlayingDenoised);
//
//     if (!_isPlayingDenoised) {
//       await _processedPlayer.stopPlayer();
//       return;
//     }
//
//     String? playPath;
//     if (_useDenoisedAudio && _useClarifiedAudio) {
//       playPath = _denoisedAndClarifiedPath;
//     } else if (_useDenoisedAudio) {
//       playPath = _denoisedFilePath;
//     } else if (_useClarifiedAudio) {
//       playPath = _clarifiedFilePath;
//     }
//
//     if (playPath == null || !await File(playPath).exists()) {
//       setState(() {
//         _isPlayingDenoised = false;
//         _showDenoisedPlayer = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Audio file not found")),
//       );
//       return;
//     }
//
//     // Setup progress listener
//     _processedPlayer.onProgress?.listen((e) {
//       if (mounted && e != null) {
//         setState(() {
//           _currentPositionDenoised = e.position;
//           _audioDurationDenoised = e.duration;
//           _sliderValueDenoised = (_audioDurationDenoised.inMilliseconds > 0)
//               ? (_currentPositionDenoised.inMilliseconds /
//               _audioDurationDenoised.inMilliseconds)
//               .clamp(0.0, 1.0)
//               : 0.0;
//         });
//       }
//     });
//
//     try {
//       await _processedPlayer.startPlayer(
//         fromURI: playPath,
//         whenFinished: () {
//           if (mounted) {
//             setState(() {
//               _isPlayingDenoised = false;
//               _sliderValueDenoised = 0.0;
//               _currentPositionDenoised = Duration.zero;
//             });
//           }
//         },
//       );
//     } catch (e) {
//       setState(() => _isPlayingDenoised = false);
//       debugPrint("Player error: $e");
//     }
//   }
//
//   Future<String?> _convertToMp3(String inputPath) async {
//     try {
//       // 1. Validate input file
//       final inputFile = File(inputPath);
//       if (!await inputFile.exists()) {
//         debugPrint("❌ Input file does not exist: $inputPath");
//         return null;
//       }
//
//       // 2. Prepare output path
//       final tempDir = await getTemporaryDirectory();
//       final outputPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.mp3';
//       debugPrint("🗂️ Temp output path: $outputPath");
//
//       // 3. Simple FFmpeg command (VBR quality)
//       final cmd = '-y -i "$inputPath" -c:a libmp3lame -q:a 2 "$outputPath"';
//       debugPrint("⚙️ FFmpeg command: $cmd");
//
//       // 4. Execute and log
//       final session = await FFmpegKit.execute(cmd);
//       final returnCode = await session.getReturnCode();
//       final logs = await session.getAllLogsAsString();
//
//       debugPrint("📜 FFmpeg logs:\n$logs");
//
//       // 5. Verify output
//       if (returnCode != null && returnCode.isValueSuccess()) {
//         if (await File(outputPath).exists()) {
//           debugPrint("✅ Conversion successful: $outputPath");
//           return outputPath;
//         } else {
//           debugPrint("❌ Output file not created");
//         }
//       } else {
//         debugPrint("❌ FFmpeg failed with code: ${returnCode?.getValue()}");
//       }
//       return null;
//     } catch (e) {
//       debugPrint("💥 Exception in _convertToMp3: ${e.toString()}");
//       return null;
//     }
//   }
//
//
//
//   Future<void> _saveProcessedAudio(BuildContext context) async {
//     // 1. Determine which audio file to save
//     String? audioPath;
//     if (_useDenoisedAudio && _useClarifiedAudio) {
//       audioPath = _denoisedAndClarifiedPath;
//     } else if (_useDenoisedAudio) {
//       audioPath = _denoisedFilePath;
//     } else if (_useClarifiedAudio) {
//       audioPath = _clarifiedFilePath;
//     }
//
//     if (audioPath == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ No processed audio selected.")),
//       );
//       return;
//     }
//
//     try {
//       // 2. Request MANAGE_EXTERNAL_STORAGE permission (required for Downloads)
//       if (!await _requestStoragePermission(context)) return;
//
//       // 3. Get the Downloads directory path
//       final downloadsDir = await _getDownloadsDirectory();
//       if (downloadsDir == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("❌ Could not access Downloads folder.")),
//         );
//         return;
//       }
//
//       // 4. Generate a unique filename
//       final fileName = 'echoza_audio_${DateTime.now().millisecondsSinceEpoch}';
//       final newFilePath = '${downloadsDir.path}/$fileName';
//
//       // 5. Copy the file to Downloads
//       await File(audioPath).copy(newFilePath);
//
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(content: Text("✅ Saved to Downloads: $fileName")),
//       // );
//
//       await showDialog(
//         context: context,
//         builder: (context) => SuccessAnimation(
//           filePath: newFilePath,
//           onClose: () => Navigator.pop(context),
//         ),
//       );
//
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Failed to save: ${e.toString()}")),
//       );
//       debugPrint("Save error details: $e");
//     }
//   }
//
// // Helper: Get Downloads directory (works on Android 10+)
//   Future<Directory?> _getDownloadsDirectory() async {
//     if (Platform.isAndroid) {
//       // Use the public Downloads folder
//       return Directory('/storage/emulated/0/Download');
//     }
//     return await getDownloadsDirectory(); // iOS/macOS fallback
//   }
//
// // Helper: Request storage permissions
//   Future<bool> _requestStoragePermission(BuildContext context) async {
//     if (Platform.isAndroid) {
//       // Android 11+ needs MANAGE_EXTERNAL_STORAGE for Downloads
//       if (await Permission.manageExternalStorage.request().isGranted) {
//         return true;
//       }
//       // Fallback for older Android versions
//       if (await Permission.storage.request().isGranted) {
//         return true;
//       }
//       // Show error if denied
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Allow storage access in settings.")),
//       );
//       return false;
//     }
//     return true; // Non-Android platforms
//   }
//
//
//
//   @override
//   void dispose() {
//     _recorder.closeRecorder();
//     _originalPlayer.closePlayer();
//     _processedPlayer.closePlayer();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFE7E7FF),
//       body: Column(
//         children: [
//           SizedBox(height: 27,),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Image.asset(
//                 'assets/echoza_logo.png', // Replace with your logo
//                 height: 60,
//               ),
//               SizedBox(width: 5,),
//               Text(
//                 'Echoza',
//                 style: TextStyle(
//                   fontSize: 42,
//                   fontFamily: 'omegle',
//                   foreground: Paint()
//                     ..shader = const LinearGradient(
//                       colors: [
//                         Color(0xFFFE5B54),
//                         Color(0xFFFF8764),
//                         Color(0xFFFE5B54),
//
//                       ],
//                       stops: [0.0, 0.5, 1.0], // Equal spread
//                       begin: Alignment.centerLeft,
//                       end: Alignment.centerRight,
//                     ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
//                 ),
//               ),
//             ],
//           ),
//
//           SizedBox(height: 15),
//           GestureDetector(
//             onTap: () => _isRecording ? _stopRecording() : _startRecording(),
//             child: Container(
//               width: 130,
//               height: 130,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black26,
//                     blurRadius: 5,
//                     offset: Offset(0, 3),
//                   ),
//                 ],
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Icon(
//                 _isRecording ? Icons.stop : Icons.mic,
//                 size: 60,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//           SizedBox(height: 15),
//           Text("Realtime Noise Supression", style: GoogleFonts.lato(fontSize: 21, fontWeight: FontWeight.w500)),
//           SizedBox(height: 7),
//           Text(
//             "Remove background noise from recorded audio\n with advanced AI processing.",
//             textAlign: TextAlign.center,
//             style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600),
//           ),
//           SizedBox(height: 14),
//           if (_showOriginalPlayer)
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: CustomAudioPlayer(
//                 player: _originalPlayer,
//                 isPlaying: _isPlaying,
//                 onPlayPause: _playPauseRecording,
//                 currentPosition: _currentPosition,
//                 totalDuration: _audioDuration,
//                 sliderValue: _sliderValue,
//                 onSliderChange: (value) async {
//                   final newPos = (_audioDuration.inMilliseconds * value).toInt();
//                   await _originalPlayer.seekToPlayer(Duration(milliseconds: newPos));
//                   setState(() {
//                     _sliderValue = value;
//                     _currentPosition = Duration(milliseconds: newPos);
//                   });
//                 },
//               ),
//             ),
//           // Updated UI with Switch
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 5,
//                         offset: Offset(0, 3),
//                       ),
//                     ],
//                     gradient: LinearGradient(
//                       colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(Icons.surround_sound_rounded, color: Colors.white, size: 30),
//                 ),
//
//                 SizedBox(width: 10),
//                 Text("Apply Noise Supression", style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
//                 SizedBox(width: 15,),
//                 Switch(
//                   value: _useDenoisedAudio,
//                   activeColor: Color(0xFF4754C5),
//                   onChanged: (_recordedFilePath == null)
//                       ? null
//                       : (val) async {
//                     setState(() {
//                       _useDenoisedAudio = val;
//                       _showDenoisedPlayer = (_useClarifiedAudio || _useDenoisedAudio);
//                     });
//                   },
//                 ),
//
//               ],
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     boxShadow: const [
//                       BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3)),
//                     ],
//                     gradient: LinearGradient(
//                       colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(Icons.volume_up, color: Colors.white, size: 30),
//                 ),
//                 SizedBox(width: 10),
//                 Text("Apply Voice Clarification", style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
//                 SizedBox(width: 10),
//                 Switch(
//                   value: _useClarifiedAudio,
//                   activeColor: Color(0xFF4754C5),
//                   onChanged: (_recordedFilePath == null)
//                       ? null
//                       : (val) async {
//                     setState(() {
//                       _useClarifiedAudio = val;
//                       _showDenoisedPlayer = (_useClarifiedAudio || _useDenoisedAudio);
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 8,),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               SizedBox(width: 37),
//               Text("Processed Audio", style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
//             ],
//           ),
//
//           // In your widget build method, conditionally show the player based on _showDenoisedPlayer
//           if (_showDenoisedPlayer)
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: CustomAudioPlayer(
//                 player: _processedPlayer,
//                 isPlaying: _isPlayingDenoised,
//                 onPlayPause: _playPauseProcessed,
//                 currentPosition: _currentPositionDenoised,
//                 totalDuration: _audioDurationDenoised,
//                 sliderValue: _sliderValueDenoised,
//                 onSliderChange: (value) async {
//                   final newPos = (_audioDurationDenoised.inMilliseconds * value).toInt();
//                   await _processedPlayer.seekToPlayer(Duration(milliseconds: newPos));
//                   setState(() {
//                     _sliderValueDenoised = value;
//                     _currentPositionDenoised = Duration(milliseconds: newPos);
//                   });
//                 },
//               ),
//             ),
//
//           Spacer(),
//           Container(
//             width: 150,
//             height: 52,
//             decoration: BoxDecoration(
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 5,
//                   offset: Offset(0, 3),
//                 ),
//               ],
//               gradient: LinearGradient(
//                 colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: ElevatedButton.icon(
//               onPressed: () async {
//                 await _saveProcessedAudio(context);
//               },
//               icon: Icon(Icons.download, color: Colors.white),
//               label: Text(
//                 "Save",
//                 style: GoogleFonts.lato(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 shadowColor: Colors.transparent,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 25),
//
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF5867E1), Color(0xFF323D95)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(30),
//                 topRight: Radius.circular(30),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 10,
//                   offset: Offset(0, -2),
//                 ),
//               ],
//             ),
//             padding: EdgeInsets.symmetric(vertical: 2),
//             child: BottomNavigationBar(
//               type: BottomNavigationBarType.fixed,
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               selectedItemColor: Color(0xFFFF8764),
//               unselectedItemColor: Colors.white70,
//               showSelectedLabels: false,
//               showUnselectedLabels: false,
//               items: [
//                 BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: "Home"),
//                 // BottomNavigationBarItem(icon: Icon(Icons.call, size: 30), label: "Call Integration"),
//                 BottomNavigationBarItem(icon: Icon(Icons.audiotrack_rounded, size: 30), label: "Audio Files"),
//                 BottomNavigationBarItem(icon: Icon(Icons.settings, size: 30), label: "Settings"),
//               ],
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
// }
