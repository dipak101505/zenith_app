import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:rbd_app/authentication/login_page.dart';
import 'package:rbd_app/pages/videoPlayer/video_player.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _actorNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActors();
  }

  Future<void> _fetchActors() async {
    try {
      final url = Uri.parse('http://api.tvmaze.com/people?page=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _actorNames =
              data
                  .map((actor) => actor['name']?.toString() ?? 'No Name')
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _actorNames = ['Error fetching data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _actorNames = ['Error: $e'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Actor List'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _actorNames.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => VideoPlayerScreen(
                                  videoUrl:
                                      'https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4', // Replace with actual video URL
                                  actorName: _actorNames[index],
                                  videoName: _actorNames[index],
                                ),
                          ),
                        );
                      },
                      child: Text(_actorNames[index]),
                    ),
                  );
                },
              ),
    );
  }
}
