import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class HistoryPage extends StatefulWidget {
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  List<Map<String, dynamic>> _audioFiles = [];
  List<Map<String, dynamic>> _videoFiles = [];
  int? _currentlyPlayingIndex;
  bool _isPlaying = false;
  bool _showPlayer = false;
  double _sliderValue = 0.0;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  late TabController _tabController;

  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPlayer();
    _requestStoragePermission().then((_) {
      _loadAudioFiles();
      _loadVideoFiles();
    });
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    _player.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true;
  }

  Future<void> _loadAudioFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final appFilesDir = Directory('${appDir.path}/echoza_processed');
    final downloadsDir = Directory('/storage/emulated/0/Download');

    List<Map<String, dynamic>> files = [];

    if (await appFilesDir.exists()) {
      final appFiles = await appFilesDir.list().where((file) =>
      file.path.toLowerCase().endsWith('.wav') ||
          file.path.toLowerCase().endsWith('.mp3')).toList();

      files.addAll(appFiles.map((file) => {
        'file': file,
        'name': file.path.split('/').last,
        'isDownload': false
      }));
    }

    if (await downloadsDir.exists()) {
      final downloadFiles = await downloadsDir.list().where((file) =>
      file.path.split('/').last.startsWith('echoza_') &&
          (file.path.toLowerCase().endsWith('.wav') ||
              file.path.toLowerCase().endsWith('.mp3'))).toList();

      files.addAll(downloadFiles.map((file) => {
        'file': file,
        'name': file.path.split('/').last,
        'isDownload': true
      }));
    }

    files.sort((a, b) => b['file'].statSync().modified.compareTo(a['file'].statSync().modified));

    if(mounted){
      setState(() {
        _audioFiles = files;
      });
    }
  }

  Future<void> _loadVideoFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final appFilesDir = Directory('${appDir.path}/echoza_processed');
    final downloadsDir = Directory('/storage/emulated/0/Download');

    List<Map<String, dynamic>> files = [];

    if (await appFilesDir.exists()) {
      final appFiles = await appFilesDir.list().where((file) =>
      file.path.toLowerCase().endsWith('.mp4') ||
          file.path.toLowerCase().endsWith('.mov')).toList();

      files.addAll(appFiles.map((file) => {
        'file': file,
        'name': file.path.split('/').last,
        'isDownload': false
      }));
    }

    if (await downloadsDir.exists()) {
      final downloadFiles = await downloadsDir.list().where((file) =>
      file.path.split('/').last.startsWith('echoza_') &&
          (file.path.toLowerCase().endsWith('.mp4') ||
              file.path.toLowerCase().endsWith('.mov'))).toList();

      files.addAll(downloadFiles.map((file) => {
        'file': file,
        'name': file.path.split('/').last,
        'isDownload': true
      }));
    }

    files.sort((a, b) => b['file'].statSync().modified.compareTo(a['file'].statSync().modified));

    if(mounted){
      setState(() {
        _videoFiles = files;
      });
    }
  }

  Future<void> _playAudio(int index) async {
    if (_currentlyPlayingIndex == index && _isPlaying) {
      await _player.pausePlayer();
      if(mounted){
        setState(() {
          _isPlaying = false;
        });
      }
      return;
    }

    if (_isPlaying && _currentlyPlayingIndex != null) {
      await _player.stopPlayer();
    }

    final filePath = _audioFiles[index]['file'].path;

    _player.onProgress?.listen((e) {
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

    await _player.startPlayer(
      fromURI: filePath,
      whenFinished: () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _showPlayer = false;
            _currentlyPlayingIndex = null;
            _sliderValue = 0.0;
            _currentPosition = Duration.zero;
          });
        }
      },
    );

    if(mounted){
      setState(() {
        _currentlyPlayingIndex = index;
        _isPlaying = true;
        _showPlayer = true;
      });
    }
  }

  // Yahan se tabdeeli shuru hai
  void _playVideo(BuildContext context, int index) {
    _videoPlayerController?.dispose();
    final videoFile = _videoFiles[index];
    _videoPlayerController = VideoPlayerController.file(videoFile['file']);

    final Future<void> initializeVideoPlayerFuture =
    _videoPlayerController!.initialize();

    showDialog(
      context: context,
      barrierDismissible: true, // Dialog ko bahar click karke band kar sakte hain
      builder: (context) {
        return FutureBuilder(
          future: initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return AlertDialog(
                  title: Text('Video Error'),
                  content: Text('Video not loaded.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
                  ],
                );
              }
              _videoPlayerController!.play();
              return _VideoPlayerDialog(
                controller: _videoPlayerController!,
                title: videoFile['name'],
              );
            } else {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFE5B54)),
                ),
              );
            }
          },
        );
      },
    ).then((_) {
      // Dialog band hone par controller ko dispose kar dein
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
  }

  Future<void> _resumeAudio() async {
    await _player.resumePlayer();
    if(mounted){
      setState(() {
        _isPlaying = true;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  Widget _buildAudioList() {
    return _audioFiles.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No processed audio files found",
            style: GoogleFonts.lato(fontSize: 16),
          ),
          SizedBox(height: 10),
          ElevatedButton(
              onPressed: _loadAudioFiles,
              child: Text("Refresh", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5867E1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              )
          )
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: _loadAudioFiles,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _audioFiles.length,
        itemBuilder: (context, index) {
          final fileData = _audioFiles[index];
          final file = fileData['file'];
          final stat = file.statSync();
          final isPlaying = _currentlyPlayingIndex == index && _isPlaying;

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Color(0xFFE7E7FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF5867E1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.audio_file,
                    color: Color(0xFF5867E1),
                    size: 30,
                  ),
                ),
                title: Text(
                  fileData['name'],
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  "${_formatDateTime(stat.modified)} • ${fileData['isDownload'] ? 'Downloads' : 'App Storage'}",
                  style: GoogleFonts.lato(
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: isPlaying ? Color(0xFF5867E1) : Color(0xFF5867E1),
                  ),
                  onPressed: () => _playAudio(index),
                ),
                onTap: () => _playAudio(index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoList() {
    return _videoFiles.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No processed video files found",
            style: GoogleFonts.lato(fontSize: 16),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5867E1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _loadVideoFiles,
            child: Text("Refresh", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: _loadVideoFiles,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _videoFiles.length,
        itemBuilder: (context, index) {
          final fileData = _videoFiles[index];
          final file = fileData['file'];
          final stat = file.statSync();

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Color(0xFFE7E7FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF5867E1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.video_file,
                    color: Color(0xFF5867E1),
                    size: 30,
                  ),
                ),
                title: Text(
                  fileData['name'],
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  "${_formatDateTime(stat.modified)} • ${fileData['isDownload'] ? 'Downloads' : 'App Storage'}",
                  style: GoogleFonts.lato(
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.play_arrow,
                    color: Color(0xFF5867E1),
                  ),
                  onPressed: () => _playVideo(context, index),
                ),
                onTap: () => _playVideo(context, index),
              ),
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7E7FF),
      body: Column(
        children: [

          SizedBox(height: 5),
          Text(
            "Recents",
            style: GoogleFonts.lato(
              fontSize: 21,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Color(0x365867E1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Color(0xFF5867E1),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              labelStyle: GoogleFonts.lato(),

              tabs: [
                Tab(text: '      Audio      '),
                Tab(text: '      Video      '),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAudioList(),
                _buildVideoList(),
              ],
            ),
          ),
          // ...
          if (_showPlayer && _currentlyPlayingIndex != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5867E1), Color(0xFF323D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Yeh add karein
                    children: [
                      // Yahan tabdeeli ki gayi hai
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title ko center mein rakhne ke liye ek khali jaga
                          SizedBox(width: 22),
                          Text(
                            "Now Playing",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Close button
                          SizedBox(
                            height: 24, // Button ka size chota karne ke liye
                            width: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero, // Default padding hatane ke liye
                              icon: Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () async {
                                await _player.stopPlayer();
                                if (mounted) {
                                  setState(() {
                                    _isPlaying = false;
                                    _showPlayer = false;
                                    _currentlyPlayingIndex = null;
                                    _sliderValue = 0.0;
                                    _currentPosition = Duration.zero;
                                    _audioDuration = Duration.zero;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.audio_file,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _audioFiles[_currentlyPlayingIndex!]['name'],
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              if (_isPlaying) {
                                await _player.pausePlayer();
                                if (mounted) setState(() => _isPlaying = false);
                              } else {
                                await _resumeAudio();
                              }
                            },
                          ),
                        ],
                      ),
                      Slider(
                        value: _sliderValue,
                        onChanged: (value) async {
                          final newPos = (_audioDuration.inMilliseconds * value).toInt();
                          await _player.seekToPlayer(Duration(milliseconds: newPos));
                          if(mounted){
                            setState(() {
                              _sliderValue = value;
                              _currentPosition = Duration(milliseconds: newPos);
                            });
                          }
                        },
                        activeColor: Color(0xFFFF8764),
                        inactiveColor: Colors.white54,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition),
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_audioDuration),
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
//...
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _player.closePlayer();
    _videoPlayerController?.dispose();
    super.dispose();
  }
}

// Yeh naya widget hai jo dialog ko manage karega
class _VideoPlayerDialog extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;

  const _VideoPlayerDialog({required this.controller, required this.title});

  @override
  __VideoPlayerDialogState createState() => __VideoPlayerDialogState();
}

class __VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    // Listener set karein taake UI update ho jab video play/pause ho
    _listener = () {
      if (mounted) {
        setState(() {});
      }
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    // Widget khatam hone par listener ko हटा dein
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Color(0xFFE7E7FF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
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
                    'Video Player',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5867E1),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFFFE5B54)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                widget.title,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black,
                ),
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(widget.controller),
                      VideoProgressIndicator(
                        widget.controller,
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
                            widget.controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 50,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(() {
                              if (widget.controller.value.isPlaying) {
                                widget.controller.pause();
                              } else {
                                widget.controller.play();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}