import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {

  // final AudioContext audioContext = AudioContext(
  //   iOS: AudioContextIOS(
  //     defaultToSpeaker: true,
  //     category: AVAudioSessionCategory.ambient,
  //     options: [
  //       AVAudioSessionOptions.defaultToSpeaker,
  //       AVAudioSessionOptions.mixWithOthers,
  //     ],
  //   ),
  //   android: AudioContextAndroid(
  //     isSpeakerphoneOn: true,
  //     stayAwake: true,
  //     contentType: AndroidContentType.sonification,
  //     usageType: AndroidUsageType.assistanceSonification,
  //     audioFocus: AndroidAudioFocus.none,
  //   ),
  // );
  // AudioPlayer.global.setGlobalAudioContext(audioContext);

  runApp(MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicPlayer(),
    );
  }
}

class MusicPlayer extends StatefulWidget {
  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _currentStatus = "Stopped";

  void _playMusic() async {
    int result = await _audioPlayer.play(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Replace with your local or online MP3 file URL
      isLocal: false
    );
    if (result == 1) {
      setState(() {
        _isPlaying = true;
        _currentStatus = "Playing";
      });
    }
  }

  void _pauseMusic() async {
    int result = await _audioPlayer.pause();
    if (result == 1) {
      setState(() {
        _isPlaying = false;
        _currentStatus = "Paused";
      });
    }
  }

  void _stopMusic() async {
    int result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _isPlaying = false;
        _currentStatus = "Stopped";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Simple Music Player"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPlaying ? Icons.music_note : Icons.music_off,
              size: 100,
              color: Colors.teal,
            ),
            SizedBox(height: 20),
            Text(
              "Status: $_currentStatus",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _playMusic,
                  child: Text("Play"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _pauseMusic,
                  child: Text("Pause"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _stopMusic,
                  child: Text("Stop"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
