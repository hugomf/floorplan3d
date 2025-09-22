import 'package:flutter/material.dart';
import 'dart:async';



class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TimerHome(),
    );
  }
}

class TimerHome extends StatefulWidget {
  const TimerHome({super.key});

  @override
  _TimerHomeState createState() => _TimerHomeState();
}

class _TimerHomeState extends State<TimerHome> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _remainingTime = 10; // Initial timer value in seconds
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: _remainingTime))
      ..addListener(() {
        setState(() {});
      });
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _remainingTime = 10; // Reset timer
    });
    _controller.reset();
    _controller.duration = Duration(seconds: _remainingTime);
    _controller.forward().whenComplete(() {
      setState(() {
        _isRunning = false;
      });
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime <= 1) {
        timer.cancel();
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text("Fun Timer App"),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 8,
                    backgroundColor: Colors.blueGrey[700],
                    valueColor: AlwaysStoppedAnimation(Colors.teal),
                  ),
                ),
                Text(
                  _remainingTime.toString(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: _isRunning ? null : _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                _isRunning ? "Running..." : "Start Timer",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
