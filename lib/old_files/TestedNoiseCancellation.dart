//
// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
// import 'dart:io';
//
//
// void main() {
//   runApp(EchozaApp());
// }
//
// class EchozaApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
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
//   FlutterSoundPlayer _player = FlutterSoundPlayer();
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
//
//
//   @override
//   void initState() {
//     super.initState();
//     _initRecorder();
//   }
//
//   Future<void> _initRecorder() async {
//     await _recorder.openRecorder();
//     await _player.openPlayer();
//     await Permission.microphone.request();
//
//     // Initialize player subscription
//     _player.setSubscriptionDuration(const Duration(milliseconds: 100));
//   }
//
//   Future<String> _getFilePath() async {
//     final dir = await getTemporaryDirectory();
//     return '${dir.path}/recorded_audio.aac';
//   }
//
//   Future<void> _startRecording() async {
//     String filePath = await _getFilePath();
//     await _recorder.startRecorder(toFile: filePath);
//     setState(() {
//       _isRecording = true;
//       _recordedFilePath = filePath;
//     });
//
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
//     });
//   }
//
//   //
//
//   Future<void> _playPauseRecording() async {
//     if (_isPlaying) {
//       await _player.stopPlayer();
//       setState(() {
//         _isPlaying = false;
//       });
//     } else if (_recordedFilePath != null) {
//       // Set up the progress listener before starting playback
//       _player.onProgress!.listen((e) {
//         if (e != null && mounted) {
//           setState(() {
//             _currentPosition = e.position;
//             _audioDuration = e.duration;
//             if (_audioDuration.inMilliseconds > 0) {
//               _sliderValue = _currentPosition.inMilliseconds / _audioDuration.inMilliseconds;
//               _sliderValue = _sliderValue.clamp(0.0, 1.0);
//             }
//           });
//         }
//       });
//
//       await _player.startPlayer(
//         fromURI: _recordedFilePath!,
//         whenFinished: () {
//           setState(() {
//             _isPlaying = false;
//             _sliderValue = 0.0;
//             _currentPosition = Duration.zero;
//           });
//         },
//       );
//
//       setState(() {
//         _isPlaying = true;
//       });
//     }
//   }
//
//
//
//
//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$minutes:$seconds';
//   }
//
//   Future<void> _applyNoiseSuppression() async {
//     if (_recordedFilePath != null) {
//       final dir = await getTemporaryDirectory();
//       String outputPath = '${dir.path}/denoised_audio.wav'; // Update to WAV format
//
//       // Correct FFmpeg command with proper path handling and syntax
//       String ffmpegCommand = "-y -i ${_recordedFilePath!} -af \"afftdn,anlmdn=s=150\" $outputPath";
//
//       try {
//         var session = await FFmpegKit.execute(ffmpegCommand);
//         final returnCode = await session.getReturnCode();
//
//         if (returnCode != null && returnCode.isValueSuccess()) {
//           setState(() {
//             _denoisedFilePath = outputPath;
//           });
//           print("✅ Noise suppression applied successfully!");
//         } else {
//           String errorMsg = returnCode != null ? returnCode.getValue().toString() : 'Unknown error';
//           print("❌ Failed to apply noise suppression: $errorMsg");
//         }
//       } catch (e) {
//         print("❌ Error occurred during noise suppression: $e");
//       }
//     }
//   }
//
//
//   Future<void> _playPauseDenoised() async {
//     if (_isPlayingDenoised) {
//       await _player.stopPlayer();
//       setState(() {
//         _isPlayingDenoised = false;
//       });
//     } else if (_denoisedFilePath != null) {
//       _player.onProgress!.listen((e) {
//         if (e != null && mounted) {
//           setState(() {
//             _currentPositionDenoised = e.position;
//             _audioDurationDenoised = e.duration;
//             if (_audioDurationDenoised.inMilliseconds > 0) {
//               _sliderValueDenoised = _currentPositionDenoised.inMilliseconds / _audioDurationDenoised.inMilliseconds;
//               _sliderValueDenoised = _sliderValueDenoised.clamp(0.0, 1.0);
//             }
//           });
//         }
//       });
//
//       await _player.startPlayer(
//         fromURI: _denoisedFilePath!,
//         whenFinished: () {
//           setState(() {
//             _isPlayingDenoised = false;
//             _sliderValueDenoised = 0.0;
//             _currentPositionDenoised = Duration.zero;
//           });
//         },
//       );
//
//       setState(() {
//         _isPlayingDenoised = true;
//       });
//     }
//   }
//
//
//
//
//
//
//   @override
//   void dispose() {
//     _recorder.closeRecorder();
//     _player.closePlayer();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.symmetric(vertical: 25),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF323D95), Color(0xFF5867E1)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(40),
//                 bottomRight: Radius.circular(40),
//               ),
//             ),
//             child: Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.change_circle, color: Colors.white, size: 30),
//                   SizedBox(width: 10),
//                   Text(
//                     "Echoza",
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           SizedBox(height: 25),
//           GestureDetector(
//             onTap: () {
//               _isRecording ? _stopRecording() : _startRecording();
//             },
//             child: Container(
//               width: 130,
//               height: 130,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
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
//
//           SizedBox(height: 15),
//
//           Text(
//             "Noise Cancellation",
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
//           ),
//
//           SizedBox(height: 7),
//
//           Text(
//             "Remove background noise from calls and audio\nfiles with advanced AI processing.",
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//           ),
//           SizedBox(height: 14),
//           if (_recordedFilePath != null)
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(
//                       _isPlaying ? Icons.pause : Icons.play_arrow,
//                       color: Color(0xFF5867E1),
//                       size: 30,
//                     ),
//                     onPressed: _playPauseRecording,
//                   ),
//                   Expanded(
//                     child: Slider(
//                       value: _sliderValue,
//                       onChanged: (value) async {
//                         if (_audioDuration.inMilliseconds > 0) {
//                           final newPosition = (_audioDuration.inMilliseconds * value).toInt();
//                           await _player.seekToPlayer(Duration(milliseconds: newPosition));
//                           setState(() {
//                             _sliderValue = value;
//                             _currentPosition = Duration(milliseconds: newPosition);
//                           });
//                         }
//                       },
//                       activeColor: Color(0xFF5867E1),
//                       inactiveColor: Colors.grey.shade300,
//                     ),
//                   ),
//                   Text(
//                     "${_formatDuration(_currentPosition)} / ${_formatDuration(_audioDuration)}",
//                     style: TextStyle(color: Colors.black, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//
//
//           GestureDetector(
//             onTap: _applyNoiseSuppression,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(Icons.surround_sound_rounded, color: Colors.white, size: 30),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     'Apply Noise Reduction',
//                     style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                   )
//                 ],
//               ),
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(Icons.volume_up, color: Colors.white, size: 30),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Slider(
//                         value: 0.5,
//                         onChanged: (value) {},
//                         activeColor: Colors.grey.shade400,
//                         inactiveColor: Colors.grey.shade300,
//                       ),
//                       Text(
//                         'Voice Enhancement',
//                         style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           if (_denoisedFilePath != null)
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(
//                       _isPlayingDenoised ? Icons.pause : Icons.play_arrow,
//                       color: Color(0xFF5867E1),
//                       size: 30,
//                     ),
//                     onPressed: _playPauseDenoised,
//                   ),
//                   Expanded(
//                     child: Slider(
//                       value: _sliderValueDenoised,
//                       onChanged: (value) async {
//                         if (_audioDurationDenoised.inMilliseconds > 0) {
//                           final newPosition = (_audioDurationDenoised.inMilliseconds * value).toInt();
//                           await _player.seekToPlayer(Duration(milliseconds: newPosition));
//                           setState(() {
//                             _sliderValueDenoised = value;
//                             _currentPositionDenoised = Duration(milliseconds: newPosition);
//                           });
//                         }
//                       },
//                       activeColor: Color(0xFF5867E1),
//                       inactiveColor: Colors.grey.shade300,
//                     ),
//                   ),
//                   Text(
//                     "${_formatDuration(_currentPositionDenoised)} / ${_formatDuration(_audioDurationDenoised)}",
//                     style: TextStyle(color: Colors.black, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//
//           Spacer(),
//
//           Container(
//             width: 180,
//             height: 50,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF5867E1), Color(0xFF323D95)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 // Save logic here
//               },
//               icon: Icon(Icons.download, color: Colors.white),
//               label: Text(
//                 "Save",
//                 style: TextStyle(fontSize: 16, color: Colors.white),
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
//
//           SizedBox(height: 20),
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
//               selectedItemColor: Colors.white,
//               unselectedItemColor: Colors.white70,
//               showSelectedLabels: false,
//               showUnselectedLabels: false,
//               items: [
//                 BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ""),
//                 BottomNavigationBarItem(icon: Icon(Icons.call, size: 30), label: ""),
//                 BottomNavigationBarItem(icon: Icon(Icons.graphic_eq, size: 30), label: ""),
//                 BottomNavigationBarItem(icon: Icon(Icons.settings, size: 30), label: ""),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import '../widgets/custom_audio_player.dart';
import 'dart:io';

void main() {
  runApp(EchozaApp());
}

class EchozaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _originalPlayer = FlutterSoundPlayer();
  FlutterSoundPlayer _denoisedPlayer = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  String? _recordedFilePath;
  String? _denoisedFilePath;
  bool _isPlayingDenoised = false;
  double _sliderValueDenoised = 0.0;
  Duration _audioDurationDenoised = Duration.zero;
  Duration _currentPositionDenoised = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await _originalPlayer.openPlayer();
    await _denoisedPlayer.openPlayer();
    await Permission.microphone.request();
    _originalPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
    _denoisedPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  Future<String> _getFilePath(String name) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$name';
  }

  Future<void> _startRecording() async {
    String filePath = await _getFilePath('recorded_audio.aac');
    await _recorder.startRecorder(toFile: filePath);
    setState(() {
      _isRecording = true;
      _recordedFilePath = filePath;
    });
    Future.delayed(Duration(minutes: 5), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    String? filePath = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _recordedFilePath = filePath;
    });
  }

  Future<void> _playPauseRecording() async {
    if (_isPlaying) {
      await _originalPlayer.stopPlayer();
      setState(() => _isPlaying = false);
    } else if (_recordedFilePath != null) {
      _originalPlayer.onProgress!.listen((e) {
        if (e != null && mounted) {
          setState(() {
            _currentPosition = e.position;
            _audioDuration = e.duration;
            _sliderValue = (_audioDuration.inMilliseconds > 0)
                ? (_currentPosition.inMilliseconds / _audioDuration.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;
          });
        }
      });

      await _originalPlayer.startPlayer(
        fromURI: _recordedFilePath!,
        whenFinished: () => setState(() {
          _isPlaying = false;
          _sliderValue = 0.0;
          _currentPosition = Duration.zero;
        }),
      );
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _applyNoiseSuppression() async {
    if (_recordedFilePath != null) {
      final outputPath = await _getFilePath('denoised_audio.wav');
      String cmd = "-y -i ${_recordedFilePath!} -af \"afftdn,anlmdn=s=150\" $outputPath";
      try {
        var session = await FFmpegKit.execute(cmd);
        final returnCode = await session.getReturnCode();
        if (returnCode != null && returnCode.isValueSuccess()) {
          setState(() => _denoisedFilePath = outputPath);
          print("✅ Noise suppression applied successfully!");
        } else {
          print("❌ Failed: \${returnCode?.getValue()}");
        }
      } catch (e) {
        print("❌ Error: $e");
      }
    }
  }

  Future<void> _playPauseDenoised() async {
    if (_isPlayingDenoised) {
      await _denoisedPlayer.stopPlayer();
      setState(() => _isPlayingDenoised = false);
    } else if (_denoisedFilePath != null) {
      _denoisedPlayer.onProgress!.listen((e) {
        if (e != null && mounted) {
          setState(() {
            _currentPositionDenoised = e.position;
            _audioDurationDenoised = e.duration;
            _sliderValueDenoised = (_audioDurationDenoised.inMilliseconds > 0)
                ? (_currentPositionDenoised.inMilliseconds / _audioDurationDenoised.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;
          });
        }
      });
      await _denoisedPlayer.startPlayer(
        fromURI: _denoisedFilePath!,
        whenFinished: () => setState(() {
          _isPlayingDenoised = false;
          _sliderValueDenoised = 0.0;
          _currentPositionDenoised = Duration.zero;
        }),
      );
      setState(() => _isPlayingDenoised = true);
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _originalPlayer.closePlayer();
    _denoisedPlayer.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF323D95), Color(0xFF5867E1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.change_circle, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text(
                    "Echoza",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 25),
          GestureDetector(
            onTap: () => _isRecording ? _stopRecording() : _startRecording(),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 15),
          Text("Noise Cancellation", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          SizedBox(height: 7),
          Text(
            "Remove background noise from calls and audio\nfiles with advanced AI processing.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          SizedBox(height: 14),
          if (_recordedFilePath != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CustomAudioPlayer(
                player: _originalPlayer,
                isPlaying: _isPlaying,
                onPlayPause: _playPauseRecording,
                currentPosition: _currentPosition,
                totalDuration: _audioDuration,
                sliderValue: _sliderValue,
                onSliderChange: (value) async {
                  final newPos = (_audioDuration.inMilliseconds * value).toInt();
                  await _originalPlayer.seekToPlayer(Duration(milliseconds: newPos));
                  setState(() {
                    _sliderValue = value;
                    _currentPosition = Duration(milliseconds: newPos);
                  });
                },
              ),
            ),
          GestureDetector(
            onTap: _applyNoiseSuppression,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.surround_sound_rounded, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: 10),
                  Text('Apply Noise Reduction', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
                ],
              ),
            ),
          ),
          if (_denoisedFilePath != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CustomAudioPlayer(
                player: _denoisedPlayer,
                isPlaying: _isPlayingDenoised,
                onPlayPause: _playPauseDenoised,
                currentPosition: _currentPositionDenoised,
                totalDuration: _audioDurationDenoised,
                sliderValue: _sliderValueDenoised,
                onSliderChange: (value) async {
                  final newPos = (_audioDurationDenoised.inMilliseconds * value).toInt();
                  await _denoisedPlayer.seekToPlayer(Duration(milliseconds: newPos));
                  setState(() {
                    _sliderValueDenoised = value;
                    _currentPositionDenoised = Duration(milliseconds: newPos);
                  });
                },
              ),
            ),
          Spacer(),
          Container(
            width: 180,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5867E1), Color(0xFF323D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                // Save logic here
              },
              icon: Icon(Icons.download, color: Colors.white),
              label: Text(
                "Save",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5867E1), Color(0xFF323D95)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 2),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.call, size: 30), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.graphic_eq, size: 30), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.settings, size: 30), label: ""),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

