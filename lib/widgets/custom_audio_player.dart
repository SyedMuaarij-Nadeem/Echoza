import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAudioPlayer extends StatelessWidget {
  final FlutterSoundPlayer player;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final Duration currentPosition;
  final Duration totalDuration;
  final double sliderValue;
  final Function(double) onSliderChange;

  const CustomAudioPlayer({
    super.key,
    required this.player,
    required this.isPlaying,
    required this.onPlayPause,
    required this.currentPosition,
    required this.totalDuration,
    required this.sliderValue,
    required this.onSliderChange,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded, color:Color(0xFF4754C5),size: 30,),
              onPressed: () {
                onPlayPause(); // This should trigger _playPauseProcessed
              },
            ),
            Expanded(
              child: Slider(
                value: sliderValue,
                onChanged: onSliderChange,
                activeColor: const Color(0xFF4754C5),
                inactiveColor: Colors.black26,
              ),
            ),
            Text(
              "${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}",
              style: GoogleFonts.lato(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
