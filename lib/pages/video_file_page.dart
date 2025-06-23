import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/successAnimation.dart';

class VideoFilePage extends StatefulWidget {
  @override
  _VideoFilePageState createState() => _VideoFilePageState();
}

class _VideoFilePageState extends State<VideoFilePage> {
  String? _videoPath;
  String? _processedVideoPath;
  bool _isProcessing = false;
  bool _useDenoisedAudio = false;
  bool _useClarifiedAudio = false;
  VideoPlayerController? _videoController;
  VideoPlayerController? _processedVideoController;
  bool _showVideoPopup = false;
  bool _isProcessingVideo = false;
  bool _isOriginalVideo = true;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;
  bool _shouldSaveAfterAd = false;
  String? _videoPathToSaveAfterAd;

  @override
  void initState() {
    super.initState();
    _loadRewardedInterstitialAd();
  }

  @override
  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _videoController?.dispose();
    _processedVideoController?.dispose();
    super.dispose();
  }

  // Load a rewarded interstitial ad
  Future<void> _loadRewardedInterstitialAd() async {
    await MobileAds.instance.initialize();

    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5354046379', // Test ad unit ID
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
  Future<void> _showRewardedInterstitialAd(String videoPath) async {
    if (_isAdLoaded && _rewardedInterstitialAd != null && !_isAdShowing) {
      _isAdShowing = true;
      _shouldSaveAfterAd = true;
      _videoPathToSaveAfterAd = videoPath;

      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // User watched the ad completely and earned reward
          if (_shouldSaveAfterAd) {
            _actuallySaveVideo(_videoPathToSaveAfterAd!);
          }
          _shouldSaveAfterAd = false;
          _videoPathToSaveAfterAd = null;
        },
      );
    } else {
      // If ad isn't loaded, save directly
      await _actuallySaveVideo(videoPath);
    }
  }

  Future<String> _getFilePath(String name) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$name';
  }

  Future<void> _pickVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _videoPath = result.files.single.path;
        _processedVideoPath = null;
        _useDenoisedAudio = false;
        _useClarifiedAudio = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoPath == null) return;

    if (_videoController != null) {
      await _videoController!.dispose();
    }

    setState(() => _isProcessingVideo = true);

    try {
      _videoController = VideoPlayerController.file(File(_videoPath!))
        ..initialize().then((_) {
          setState(() => _isProcessingVideo = false);
          _videoController!.play();
        });
    } catch (e) {
      setState(() => _isProcessingVideo = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading video: $e')));
    }
  }

  Future<void> _initializeProcessedVideoPlayer() async {
    if (_processedVideoPath == null) return;

    if (_processedVideoController != null) {
      await _processedVideoController!.dispose();
    }

    setState(() => _isProcessingVideo = true);

    try {
      _processedVideoController = VideoPlayerController.file(
          File(_processedVideoPath!),
        )
        ..initialize().then((_) {
          setState(() => _isProcessingVideo = false);
          _processedVideoController!.play();
        });
    } catch (e) {
      setState(() => _isProcessingVideo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading processed video: $e')),
      );
    }
  }

  Future<void> _processVideo() async {
    if (_videoPath == null) return;

    setState(() => _isProcessing = true);

    try {
      // Step 1: Extract audio from video
      final audioPath = await _getFilePath('extracted_audio.aac');
      await FFmpegKit.execute('-i "$_videoPath" -vn -acodec copy "$audioPath"');

      // Step 2: Process audio based on selected options
      final processedAudioPath = await _getFilePath('processed_audio.aac');
      String audioFilter = '';

      if (_useDenoisedAudio && _useClarifiedAudio) {
        audioFilter =
            'afftdn,highpass=f=80,anlmdn=s=60, acompressor=threshold=-18dB:ratio=3:attack=20:release=250, treble=g=3, volume=17dB';
      } else if (_useDenoisedAudio) {
        audioFilter = 'afftdn,highpass=f=80,anlmdn=s=60';
      } else if (_useClarifiedAudio) {
        audioFilter =
            'acompressor=threshold=-18dB:ratio=3:attack=20:release=250, treble=g=3, volume=17dB';
      }

      if (audioFilter.isNotEmpty) {
        await FFmpegKit.execute(
          '-i "$audioPath" -af "$audioFilter" "$processedAudioPath"',
        );
      }

      // Step 3: Mux processed audio with original video
      final outputPath = await _getFilePath(
        'processed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await FFmpegKit.execute(
        '-i "$_videoPath" -i "${audioFilter.isNotEmpty ? processedAudioPath : audioPath}" '
        '-c:v copy -map 0:v:0 -map 1:a:0 -shortest "$outputPath"',
      );

      setState(() {
        _processedVideoPath = outputPath;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing video: $e')));
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

  Future<void> _saveProcessedVideo() async {
    if (_processedVideoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ No processed video available.")),
      );
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
      await _showRewardedInterstitialAd(_processedVideoPath!);
    }
  }

  Future<void> _actuallySaveVideo(String videoPath) async {
    try {
      if (!await _requestStoragePermission(context)) return;

      final downloadsDir =
          Platform.isAndroid
              ? Directory('/storage/emulated/0/Download')
              : await getDownloadsDirectory();

      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Could not access Downloads folder.")),
        );
        return;
      }

      final fileName =
          'echoza_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final newFilePath = '${downloadsDir.path}/$fileName';

      await File(videoPath).copy(newFilePath);

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

  void _showVideoPlayer(bool isOriginal) async {
    if (isOriginal && _videoPath == null) return;
    if (!isOriginal && _processedVideoPath == null) return;

    setState(() {
      _isOriginalVideo = isOriginal;
      _showVideoPopup = true;
    });

    if (isOriginal) {
      await _initializeVideoPlayer();
    } else {
      await _initializeProcessedVideoPlayer();
    }
  }

  Widget _buildVideoPlayerCard() {
    final controller =
        _isOriginalVideo ? _videoController : _processedVideoController;
    final title = _isOriginalVideo ? 'Original Video' : 'Processed Video';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Color(0xFFE7E7FF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          padding: EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5867E1),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFFFE5B54)),
                    onPressed: () {
                      setState(() {
                        _showVideoPopup = false;
                        controller?.pause();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black,
                ),
                child:
                    _isProcessingVideo
                        ? Container(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFE5B54),
                              ),
                            ),
                          ),
                        )
                        : (controller != null && controller.value.isInitialized
                            ? AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  VideoPlayer(controller!),
                                  VideoProgressIndicator(
                                    controller!,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: Color(0xFFFE5B54),
                                      bufferedColor: Colors.grey,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: IconButton(
                                      icon: Icon(
                                        controller.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 50,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          controller.value.isPlaying
                                              ? controller.pause()
                                              : controller.play();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Container(
                              height: 200,
                              child: Center(
                                child: Text(
                                  'Video not available',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7E7FF),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 7),
                Image.asset('assets/vedioFile.png', height: 80),
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
                  "Remove background noise from selected vedio.",
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
                    boxShadow: [
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
                  child: ElevatedButton(
                    onPressed: _pickVideoFile,
                    child: Text(
                      "Choose Video File",
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
                SizedBox(height: 15),
                if (_videoPath != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 40.0, right: 30),
                    child: SizedBox(
                      height: 23,
                      child: Text(
                        "Vedio Selected!",
                        style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showVideoPlayer(true),
                    icon: Icon(Icons.play_circle, color: Color(0xFF5867E1)),
                    label: Text(
                      "Play Original Video",
                      style: GoogleFonts.lato(
                        color: Color(0xFF5867E1),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(
                    left: 36,
                    right: 36,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          boxShadow: [
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
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 18),
                      Switch(
                        value: _useDenoisedAudio,
                        activeColor: Color(0xFF4754C5),
                        onChanged:
                            _videoPath != null
                                ? (val) =>
                                    setState(() => _useDenoisedAudio = val)
                                : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 36, right: 36, top: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          boxShadow: [
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
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 2),
                      Switch(
                        value: _useClarifiedAudio,
                        activeColor: Color(0xFF4754C5),
                        onChanged:
                            _videoPath != null
                                ? (val) =>
                                    setState(() => _useClarifiedAudio = val)
                                : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                if (_videoPath != null && !_isProcessing) ...[
                  Container(
                    width: 177,
                    height: 52,
                    decoration: BoxDecoration(
                      boxShadow: [
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
                    child: ElevatedButton(
                      onPressed: _processVideo,
                      child: Text(
                        "Process Video",
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
                ] else if (_isProcessing) ...[
                  Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFE5B54),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text("Processing video...", style: GoogleFonts.lato()),
                    ],
                  ),
                ],
                SizedBox(height: 5),
                if (_processedVideoPath != null) ...[
                  TextButton.icon(
                    onPressed: () => _showVideoPlayer(false),
                    icon: Icon(Icons.play_circle, color: Color(0xFF5867E1)),
                    label: Text(
                      "Play Processed Video",
                      style: GoogleFonts.lato(
                        color: Color(0xFF5867E1),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
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
                      onPressed: _saveProcessedVideo,
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
                ],
              ],
            ),
          ),
          if (_showVideoPopup) ...[
            ModalBarrier(
              color: Colors.black.withOpacity(0.5),
              dismissible: true,
              onDismiss: () {
                setState(() {
                  _showVideoPopup = false;
                  if (_isOriginalVideo) {
                    _videoController?.pause();
                  } else {
                    _processedVideoController?.pause();
                  }
                });
              },
            ),
            _buildVideoPlayerCard(),
          ],
        ],
      ),
    );
  }
}
