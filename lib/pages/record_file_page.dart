import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'dart:io';
import '../widgets/custom_audio_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import Google Mobile Ads
import '../widgets/successAnimation.dart';

class RecordFilePage extends StatefulWidget {
  @override
  _RecordFilePageState createState() => _RecordFilePageState();
}

class _RecordFilePageState extends State<RecordFilePage> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _originalPlayer = FlutterSoundPlayer();
  FlutterSoundPlayer _processedPlayer = FlutterSoundPlayer();
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
  bool _useDenoisedAudio = false;
  bool _useClarifiedAudio = false;
  String? _clarifiedFilePath;
  String? _denoisedAndClarifiedPath;
  bool _showOriginalPlayer = false;
  bool _showDenoisedPlayer = false;

  // Google Ads Variables
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;
  bool _shouldSaveAfterAd = false;
  String? _audioPathToSaveAfterAd; // Changed from _videoPathToSaveAfterAd

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadRewardedInterstitialAd(); // Load ad on init
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _originalPlayer.closePlayer();
    _processedPlayer.closePlayer();
    _rewardedInterstitialAd?.dispose(); // Dispose ad
    super.dispose();
  }

  // Load a rewarded interstitial ad
  Future<void> _loadRewardedInterstitialAd() async {
    await MobileAds.instance.initialize(); // Initialize MobileAds

    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5354046379', // Test ad unit ID
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
          _isAdLoaded = true;
          print('RewardedInterstitialAd loaded successfully!');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
              _isAdShowing = false;
              ad.dispose();
              _loadRewardedInterstitialAd(); // Load a new ad for next time
            },
            onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad,
                AdError error,) {
              _isAdShowing = false;
              ad.dispose();
              _loadRewardedInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
          print('RewardedInterstitialAd failed to load: $error');
        },
      ),
    );
  }

  // Show the rewarded interstitial ad
  Future<void> _showRewardedInterstitialAd(String audioPath) async {
    if (_isAdLoaded && _rewardedInterstitialAd != null && !_isAdShowing) {
      _isAdShowing = true;
      _shouldSaveAfterAd = true;
      _audioPathToSaveAfterAd = audioPath;

      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // User watched the ad completely and earned reward
          if (_shouldSaveAfterAd) {
            _actuallySaveAudio(_audioPathToSaveAfterAd!); // Call actual save
          }
          _shouldSaveAfterAd = false;
          _audioPathToSaveAfterAd = null;
        },
      );
    } else {
      // If ad isn't loaded, save directly
      print('Ad not loaded or already showing. Saving directly.');
      await _actuallySaveAudio(audioPath);
    }
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await _originalPlayer.openPlayer();
    await _processedPlayer.openPlayer();
    await Permission.microphone.request();
    _originalPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
    _processedPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  Future<String> _getFilePath(String name) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$name';
  }

  Future<void> _startRecording() async {
    String filePath = await _getFilePath('recorded_audio.aac');

    // Reset toggle and delete denoised file if exists
    if (_denoisedFilePath != null) {
      final denoisedFile = File(_denoisedFilePath!);
      if (await denoisedFile.exists()) {
        await denoisedFile.delete();
        print("🗑️ Deleted existing denoised file");
      }
    }
    setState(() {
      _showOriginalPlayer = false;
      _showDenoisedPlayer = false;
      _useClarifiedAudio = false;
      _useDenoisedAudio = false;
    });

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
      _showOriginalPlayer = true;
    });
    await _applyNoiseSuppression();
    await _applyVoiceClarification();
    await _applyNoiseSuppressionAndClarification();
  }

  Future<void> _playPauseRecording() async {
    if (_isPlaying) {
      await _originalPlayer.stopPlayer();
      setState(() => _isPlaying = false);
    } else if (_recordedFilePath != null) {
      _originalPlayer.onProgress?.listen((e) {
        if (e != null && mounted) {
          setState(() {
            _currentPosition = e.position;
            _audioDuration = e.duration;
            _sliderValue = (_audioDuration.inMilliseconds > 0)
                ? (_currentPosition.inMilliseconds /
                _audioDuration.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;
          });
        }
      });

      await _originalPlayer.startPlayer(
        fromURI: _recordedFilePath!,
        whenFinished: () =>
            setState(() {
              _isPlaying = false;
              _sliderValue = 0.0;
              _currentPosition = Duration.zero;
            }),
      );
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _applyNoiseSuppression() async {
    if (_recordedFilePath == null) return;

    final outputPath = await _getFilePath('denoised_audio.wav');
    String cmd =
        "-y -i '$_recordedFilePath' -af \"afftdn,highpass=f=80,anlmdn=s=60\" '${outputPath}'";

    try {
      var session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();
      if (returnCode != null && returnCode.isValueSuccess()) {
        setState(() {
          _denoisedFilePath = outputPath;
        });
        print("✅ Noise suppression applied successfully!");
      } else {
        print("❌ Failed: ${returnCode?.getValue()}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
    if (await File(outputPath).exists()) {
      setState(() {
        _denoisedFilePath = outputPath;
      });
      print("✅ Noise suppression applied and file exists.");
    } else {
      print("❌ Denoised file not found after FFmpeg execution!");
    }
  }

  Future<void> _applyVoiceClarification({bool onFinalOutput = false}) async {
    final inputPath = onFinalOutput
        ? _denoisedFilePath
        : _recordedFilePath;

    if (inputPath == null) return;

    final outputPath = await _getFilePath(
        onFinalOutput
            ? 'denoised_and_clarified_audio.wav'
            : 'clarified_audio.wav');

    String cmd =
        "-y -i '$inputPath' -af \"acompressor=threshold=-18dB:ratio=3:attack=20:release=250, treble=g=3, volume=17dB\" '$outputPath'";

    try {
      var session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();
      if (returnCode != null && returnCode.isValueSuccess()) {
        setState(() {
          if (onFinalOutput) {
            _denoisedAndClarifiedPath = outputPath;
          } else {
            _clarifiedFilePath = outputPath;
          }
        });
        print("✅ Voice clarification applied successfully!");
      } else {
        print("❌ Clarification failed: ${returnCode?.getValue()}");
      }
    } catch (e) {
      print("❌ Clarification error: $e");
    }
  }

  Future<void> _applyNoiseSuppressionAndClarification() async {
    if (_recordedFilePath == null) return;

    final denoisedFilePath = await _getFilePath('denoised_audio.wav');
    String noiseSuppressionCmd =
        "-y -i '$_recordedFilePath' -af \"afftdn,highpass=f=80,anlmdn=s=60\" '$denoisedFilePath'";

    try {
      var session = await FFmpegKit.execute(noiseSuppressionCmd);
      final returnCode = await session.getReturnCode();
      if (returnCode != null && returnCode.isValueSuccess()) {
        print("✅ Noise suppression applied successfully!");
      } else {
        print("❌ Failed: ${returnCode?.getValue()}");
        return;
      }
    } catch (e) {
      print("❌ Error applying noise suppression: $e");
      return;
    }

    final clarifiedFilePath = await _getFilePath(
        'denoised_and_clarified_audio.wav');
    String clarificationCmd =
        "-y -i '$denoisedFilePath' -af \"acompressor=threshold=-18dB:ratio=3:attack=20:release=250, treble=g=3, volume=17dB\" '$clarifiedFilePath'";

    try {
      var session = await FFmpegKit.execute(clarificationCmd);
      final returnCode = await session.getReturnCode();
      if (returnCode != null && returnCode.isValueSuccess()) {
        setState(() {
          _denoisedAndClarifiedPath = clarifiedFilePath;
        });
        print("✅ Voice clarification applied successfully!");
      } else {
        print("❌ Failed: ${returnCode?.getValue()}");
      }
    } catch (e) {
      print("❌ Error applying voice clarification: $e");
    }
  }

  Future<void> _playPauseProcessed() async {
    setState(() => _isPlayingDenoised = !_isPlayingDenoised);

    if (!_isPlayingDenoised) {
      await _processedPlayer.stopPlayer();
      return;
    }

    String? playPath;
    if (_useDenoisedAudio && _useClarifiedAudio) {
      playPath = _denoisedAndClarifiedPath;
    } else if (_useDenoisedAudio) {
      playPath = _denoisedFilePath;
    } else if (_useClarifiedAudio) {
      playPath = _clarifiedFilePath;
    }

    if (playPath == null || !await File(playPath).exists()) {
      setState(() {
        _isPlayingDenoised = false;
        _showDenoisedPlayer = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Audio file not found")),
      );
      return;
    }

    _processedPlayer.onProgress?.listen((e) {
      if (mounted && e != null) {
        setState(() {
          _currentPositionDenoised = e.position;
          _audioDurationDenoised = e.duration;
          _sliderValueDenoised = (_audioDurationDenoised.inMilliseconds > 0)
              ? (_currentPositionDenoised.inMilliseconds /
              _audioDurationDenoised.inMilliseconds)
              .clamp(0.0, 1.0)
              : 0.0;
        });
      }
    });

    try {
      await _processedPlayer.startPlayer(
        fromURI: playPath,
        whenFinished: () {
          if (mounted) {
            setState(() {
              _isPlayingDenoised = false;
              _sliderValueDenoised = 0.0;
              _currentPositionDenoised = Duration.zero;
            });
          }
        },
      );
    } catch (e) {
      setState(() => _isPlayingDenoised = false);
      debugPrint("Player error: $e");
    }
  }

  // Refactored to _promptForAdAndSave to use the ad logic
  Future<void> _promptForAdAndSave() async {
    String? audioPath;
    if (_useDenoisedAudio && _useClarifiedAudio) {
      audioPath = _denoisedAndClarifiedPath;
    } else if (_useDenoisedAudio) {
      audioPath = _denoisedFilePath;
    } else if (_useClarifiedAudio) {
      audioPath = _clarifiedFilePath;
    }

    if (audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ No processed audio selected.")),
      );
      return;
    }

    // Show a confirmation dialog before showing ad
    bool? proceed = await showDialog<bool>(
      context: context,
      builder:
          (context) =>
          AlertDialog(
            title: Text(
              "Save Audio",
              style: GoogleFonts.lato(), // Apply Lato font
            ),
            content: Text(
              "Watch a short ad to save your processed audio file?",
              style: GoogleFonts.lato(), // Apply Lato font
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.lato(), // Apply Lato font
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  "Continue",
                  style: GoogleFonts.lato(), // Apply Lato font
                ),
              ),
            ],
          ),
    );

    if (proceed == true) {
      await _showRewardedInterstitialAd(audioPath);
    }
  }

  // The actual save logic, now called by _showRewardedInterstitialAd
  Future<void> _actuallySaveAudio(String audioPath) async {
    try {
      if (!await _requestStoragePermission()) return;

      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Could not access Downloads folder.")),
        );
        return;
      }

      final fileName = 'echoza_audio_${DateTime
          .now()
          .millisecondsSinceEpoch}';
      final newFilePath = '${downloadsDir.path}/$fileName.wav';

      await File(audioPath).copy(newFilePath);

      await showDialog(
        context: context,
        builder: (context) =>
            SuccessAnimation(
              filePath: newFilePath,
              onClose: () => Navigator.pop(context),
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save: ${e.toString()}")),
      );
      debugPrint("Save error details: $e");
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    return await getDownloadsDirectory();
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage
          .request()
          .isGranted) {
        return true;
      }
      if (await Permission.storage
          .request()
          .isGranted) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Allow storage access in settings.")),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7E7FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(

              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () =>
                    _isRecording
                        ? _stopRecording()
                        : _startRecording(),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 67,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Realtime Noise Supression\n & Enhancement",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                        fontSize: 21, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 7),
                  Text(
                    "Remove background noise from recorded audio\n with advanced AI processing.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 14),
                  if (_showOriginalPlayer)
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
                          final newPos = (_audioDuration.inMilliseconds * value)
                              .toInt();
                          await _originalPlayer.seekToPlayer(
                              Duration(milliseconds: newPos));
                          setState(() {
                            _sliderValue = value;
                            _currentPosition = Duration(milliseconds: newPos);
                          });
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                              Icons.surround_sound_rounded, color: Colors.white,
                              size: 30),
                        ),
                        SizedBox(width: 10),
                        Text("Apply Noise Supression", style: GoogleFonts.lato(
                            fontWeight: FontWeight.w500)),
                        SizedBox(width: 15),
                        Switch(
                          value: _useDenoisedAudio,
                          activeColor: Color(0xFF4754C5),
                          onChanged: (_recordedFilePath == null)
                              ? null
                              : (val) async {
                            setState(() {
                              _useDenoisedAudio = val;
                              _showDenoisedPlayer =
                              (_useClarifiedAudio || _useDenoisedAudio);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(color: Colors.black26,
                                  blurRadius: 5,
                                  offset: Offset(0, 3)),
                            ],
                            gradient: LinearGradient(
                              colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                              Icons.volume_up, color: Colors.white, size: 30),
                        ),
                        SizedBox(width: 10),
                        Text("Apply Voice Enhancement", style: GoogleFonts.lato(
                            fontWeight: FontWeight.w500)),
                        SizedBox(width: 2),
                        Switch(
                          value: _useClarifiedAudio,
                          activeColor: Color(0xFF4754C5),
                          onChanged: (_recordedFilePath == null)
                              ? null
                              : (val) async {
                            setState(() {
                              _useClarifiedAudio = val;
                              _showDenoisedPlayer =
                              (_useClarifiedAudio || _useDenoisedAudio);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_showDenoisedPlayer)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 37),
                            Text("Processed Audio", style: GoogleFonts.lato(
                                fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: CustomAudioPlayer(
                            player: _processedPlayer,
                            isPlaying: _isPlayingDenoised,
                            onPlayPause: _playPauseProcessed,
                            currentPosition: _currentPositionDenoised,
                            totalDuration: _audioDurationDenoised,
                            sliderValue: _sliderValueDenoised,
                            onSliderChange: (value) async {
                              final newPos = (_audioDurationDenoised
                                  .inMilliseconds * value).toInt();
                              await _processedPlayer.seekToPlayer(
                                  Duration(milliseconds: newPos));
                              setState(() {
                                _sliderValueDenoised = value;
                                _currentPositionDenoised =
                                    Duration(milliseconds: newPos);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  Container(
                    width: 150,
                    height: 52,
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _promptForAdAndSave,
                      icon: Icon(Icons.download, color: Colors.white),
                      label: Text(
                        "Save",
                        style: GoogleFonts.lato(fontSize: 18, color: Colors
                            .white, fontWeight: FontWeight.w500),
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
                  SizedBox(height: 25),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}