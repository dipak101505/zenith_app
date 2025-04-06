import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String actorName;
  final String videoName;

  VideoPlayerScreen({
    required this.videoUrl,
    required this.actorName,
    required this.videoName,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _showControls = true;
  bool _hasError = false;
  String _errorMessage = "";
  bool _isFullScreen = false;
  final Logger logger = Logger();
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();

    // Log the video name
    logger.i("Opening video: ${widget.videoName}");
    logger.i("Video URL: ${widget.videoUrl}");

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _initializeVideoPlayerFuture = _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
          _controller.play();
        })
        .catchError((error) {
          logger.e("Video player error: $error");
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = "Failed to load video: $error";
            });
          }
          return null;
        });

    _controller.setLooping(true);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // Reset the timer to hide controls after 3 seconds
    _hideControlsTimer?.cancel();
    if (_showControls) {
      _hideControlsTimer = Timer(Duration(seconds: 3), () {
        setState(() {
          _showControls = false;
        });
      });
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _isFullScreen
              ? null // Remove the AppBar in fullscreen mode
              : AppBar(
                title: Text(
                  widget.videoName
                      .split('_')
                      .sublist(2)
                      .join('_'), // Extract chapter_video
                ),
                backgroundColor: Colors.orange,
              ),
      body:
          _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.orange, size: 48),
                    SizedBox(height: 16),
                    Text(
                      "Video playback error",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_errorMessage),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _controller = VideoPlayerController.network(
                            widget.videoUrl,
                          );
                          _initializeVideoPlayerFuture =
                              _controller.initialize();
                          _controller.setLooping(true);
                        });
                      },
                      child: Text("Try Again"),
                    ),
                  ],
                ),
              )
              : FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      !_hasError) {
                    return GestureDetector(
                      onTap: _toggleControls,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: Colors.black,
                            child:
                                _isFullScreen
                                    ? Center(
                                      child: VideoPlayer(_controller),
                                    ) // Fullscreen mode: Center the video
                                    : AspectRatio(
                                      aspectRatio:
                                          _controller.value.aspectRatio,
                                      child: VideoPlayer(_controller),
                                    ), // Normal mode: Maintain aspect ratio
                          ),
                          if (_showControls)
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.replay_10,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          final position =
                                              _controller.value.position -
                                              Duration(seconds: 10);
                                          _controller.seekTo(position);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _controller.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (_controller.value.isPlaying) {
                                              _controller.pause();
                                            } else {
                                              _controller.play();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.forward_10,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          final position =
                                              _controller.value.position +
                                              Duration(seconds: 10);
                                          _controller.seekTo(position);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isFullScreen
                                              ? Icons.fullscreen_exit
                                              : Icons.fullscreen,
                                          color: Colors.white,
                                        ),
                                        onPressed: _toggleFullScreen,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: Colors.orange,
                                bufferedColor: Colors.orange.withOpacity(0.3),
                                backgroundColor: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
                          SizedBox(height: 16),
                          Text("Loading video..."),
                        ],
                      ),
                    );
                  }
                },
              ),
    );
  }
}
