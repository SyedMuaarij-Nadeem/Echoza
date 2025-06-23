import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/custom_audio_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../widgets/successAnimation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AudioFilePage extends StatefulWidget {
  @override
  _AudioFilePageState createState() => _AudioFilePageState();
}

class _AudioFilePageState extends State<AudioFilePage> {
  FlutterSoundPlayer _originalPlayer = FlutterSoundPlayer();
  FlutterSoundPlayer _processedPlayer = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isPlayingProcessed = false;
  double _sliderValue = 0.0;
  double _sliderValueProcessed = 0.0;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration _audioDurationProcessed = Duration.zero;
  Duration _currentPositionProcessed = Duration.zero;

  String? _selectedFilePath;
  String? _denoisedFilePath;
  String? _clarifiedFilePath;
  String? _denoisedAndClarifiedPath;
  bool _useDenoisedAudio = false;
  bool _useClarifiedAudio = false;
  bool _showOriginalPlayer = false;
  bool _showProcessedPlayer = false;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;
  bool _shouldSaveAfterAd = false;
  String? _audioPathToSaveAfterAd;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _loadRewardedInterstitialAd();
  }

  Future<void> _initAudio() async {
    await _originalPlayer.openPlayer();
    await _processedPlayer.openPlayer();
    _originalPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
    _processedPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));
    await Permission.manageExternalStorage.request();
    await Permission.storage.request();
  }

  Future<String> _getFilePath(String name) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$name';
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _showOriginalPlayer = true;
        _useDenoisedAudio = false;
        _useClarifiedAudio = false;
        _showProcessedPlayer = false;
      });

      // Apply processing immediately after selecting file
      await _applyNoiseSuppression();
      await _applyVoiceClarification();
      await _applyNoiseSuppressionAndClarification();
    }
  }

  Future<void> _playPauseAudio() async {
    if (_isPlaying) {
      await _originalPlayer.stopPlayer();
      setState(() => _isPlaying = false);
    } else if (_selectedFilePath != null) {
      _originalPlayer.onProgress?.listen((e) {
        if (e != null && mounted) {
          setState(() {
            _currentPosition = e.position;
            _audioDuration = e.duration;
            _sliderValue =
                (_audioDuration.inMilliseconds > 0)
                    ? (_currentPosition.inMilliseconds /
                            _audioDuration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;
          });
        }
      });

      await _originalPlayer.startPlayer(
        fromURI: _selectedFilePath!,
        whenFinished:
            () => setState(() {
              _isPlaying = false;
              _sliderValue = 0.0;
              _currentPosition = Duration.zero;
            }),
      );
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _playPauseProcessed() async {
    setState(() => _isPlayingProcessed = !_isPlayingProcessed);

    if (!_isPlayingProcessed) {
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
        _isPlayingProcessed = false;
        _showProcessedPlayer = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Audio file not found")));
      return;
    }

    _processedPlayer.onProgress?.listen((e) {
      if (mounted && e != null) {
        setState(() {
          _currentPositionProcessed = e.position;
          _audioDurationProcessed = e.duration;
          _sliderValueProcessed =
              (_audioDurationProcessed.inMilliseconds > 0)
                  ? (_currentPositionProcessed.inMilliseconds /
                          _audioDurationProcessed.inMilliseconds)
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
              _isPlayingProcessed = false;
              _sliderValueProcessed = 0.0;
              _currentPositionProcessed = Duration.zero;
            });
          }
        },
      );
    } catch (e) {
      setState(() => _isPlayingProcessed = false);
      debugPrint("Player error: $e");
    }
  }

  Future<void> _applyNoiseSuppression() async {
    if (_selectedFilePath == null) return;

    final outputPath = await _getFilePath('denoised_audio.wav');
    String cmd =
        "-y -i '$_selectedFilePath' -af \"afftdn,highpass=f=80,anlmdn=s=60\" '${outputPath}'";

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
  }

  Future<void> _applyVoiceClarification({bool onFinalOutput = false}) async {
    final inputPath = onFinalOutput ? _denoisedFilePath : _selectedFilePath;

    if (inputPath == null) return;

    final outputPath = await _getFilePath(
      onFinalOutput
          ? 'denoised_and_clarified_audio.wav'
          : 'clarified_audio.wav',
    );

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
    if (_selectedFilePath == null) return;

    // Step 1: Apply Noise Suppression
    final denoisedFilePath = await _getFilePath('denoised_audio.wav');
    String noiseSuppressionCmd =
        "-y -i '$_selectedFilePath' -af \"afftdn,highpass=f=80,anlmdn=s=60\" '$denoisedFilePath'";

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

    // Step 2: Apply Voice Clarification to the Denoised Audio
    final clarifiedFilePath = await _getFilePath(
      'denoised_and_clarified_audio.wav',
    );
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

  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Allow storage access in settings.")),
      );
      return false;
    }
    return true;
  }

  // Load a rewarded interstitial ad
  Future<void> _loadRewardedInterstitialAd() async {
    await MobileAds.instance.initialize();

    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5354046379', //Test-adUnitId
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
          _isAdLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
              _isAdShowing = false;
              ad.dispose();
              _loadRewardedInterstitialAd(); // Load a new ad for next time
            },
            onAdFailedToShowFullScreenContent: (
              RewardedInterstitialAd ad,
              AdError error,
            ) {
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

      // _rewardedInterstitialAd!.setOnPaidEventListener((AdValue value) {
      //   // Handle ad value if needed
      // });

      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // User watched the ad completely and earned reward
          if (_shouldSaveAfterAd) {
            _actuallySaveAudio(_audioPathToSaveAfterAd!);
          }
          _shouldSaveAfterAd = false;
          _audioPathToSaveAfterAd = null;
        },
      );
    } else {
      // If ad isn't loaded, save directly
      await _actuallySaveAudio(audioPath);
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    return await getDownloadsDirectory();
  }

  // Modify your save method to show the rewarded ad
  Future<void> _saveProcessedAudio() async {
    String? audioPath;
    if (_useDenoisedAudio && _useClarifiedAudio) {
      audioPath = _denoisedAndClarifiedPath;
    } else if (_useDenoisedAudio) {
      audioPath = _denoisedFilePath;
    } else if (_useClarifiedAudio) {
      audioPath = _clarifiedFilePath;
    }

    if (audioPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ No processed audio selected.")));
      return;
    }

    // Show a confirmation dialog before showing ad
    bool? proceed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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

  // Your existing save logic (unchanged)
  Future<void> _actuallySaveAudio(String audioPath) async {
    try {
      if (!await _requestStoragePermission(context)) return;

      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Could not access Downloads folder.")),
        );
        return;
      }

      final fileName =
          'echoza_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      final newFilePath = '${downloadsDir.path}/$fileName';

      await File(audioPath).copy(newFilePath);

      await showDialog(
        context: context,
        builder:
            (context) => SuccessAnimation(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7E7FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 7),
                    Image.asset('assets/audioFile.png', height: 90),
                    SizedBox(height: 3),
                    Text(
                      "Realtime Noise Supression\n & Enhancement",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      "Remove background noise from selected audio\nfiles.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 7),
                    Container(
                      width: 177,
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
                        onPressed: _pickAudioFile,
                        label: Text(
                          "Choose Audio File",
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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
                    SizedBox(height: 14),
                    if (_showOriginalPlayer)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: CustomAudioPlayer(
                          player: _originalPlayer,
                          isPlaying: _isPlaying,
                          onPlayPause: _playPauseAudio,
                          currentPosition: _currentPosition,
                          totalDuration: _audioDuration,
                          sliderValue: _sliderValue,
                          onSliderChange: (value) async {
                            final newPos =
                                (_audioDuration.inMilliseconds * value).toInt();
                            await _originalPlayer.seekToPlayer(
                              Duration(milliseconds: newPos),
                            );
                            setState(() {
                              _sliderValue = value;
                              _currentPosition = Duration(milliseconds: newPos);
                            });
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 10,
                      ),
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
                              Icons.surround_sound_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Apply Noise Supression",
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 15),
                          Switch(
                            value: _useDenoisedAudio,
                            activeColor: Color(0xFF4754C5),
                            onChanged:
                                (_selectedFilePath == null)
                                    ? null
                                    : (val) async {
                                      setState(() {
                                        _useDenoisedAudio = val;
                                        _showProcessedPlayer =
                                            (_useClarifiedAudio ||
                                                _useDenoisedAudio);
                                      });
                                    },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 10,
                      ),
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
                              Icons.volume_up,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Apply Voice Enhancement",
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 2),
                          Switch(
                            value: _useClarifiedAudio,
                            activeColor: Color(0xFF4754C5),
                            onChanged:
                                (_selectedFilePath == null)
                                    ? null
                                    : (val) async {
                                      setState(() {
                                        _useClarifiedAudio = val;
                                        _showProcessedPlayer =
                                            (_useClarifiedAudio ||
                                                _useDenoisedAudio);
                                      });
                                    },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_showProcessedPlayer)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 37),
                              Text(
                                "Processed Audio",
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: CustomAudioPlayer(
                              player: _processedPlayer,
                              isPlaying: _isPlayingProcessed,
                              onPlayPause: _playPauseProcessed,
                              currentPosition: _currentPositionProcessed,
                              totalDuration: _audioDurationProcessed,
                              sliderValue: _sliderValueProcessed,
                              onSliderChange: (value) async {
                                final newPos =
                                    (_audioDurationProcessed.inMilliseconds *
                                            value)
                                        .toInt();
                                await _processedPlayer.seekToPlayer(
                                  Duration(milliseconds: newPos),
                                );
                                setState(() {
                                  _sliderValueProcessed = value;
                                  _currentPositionProcessed = Duration(
                                    milliseconds: newPos,
                                  );
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
                        onPressed: _saveProcessedAudio,
                        icon: Icon(Icons.download, color: Colors.white),
                        label: Text(
                          "Save",
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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
      ),
    );
  }

  @override
  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _originalPlayer.closePlayer();
    _processedPlayer.closePlayer();
    super.dispose();
  }
}
