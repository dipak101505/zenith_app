import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rbd_app/pages/videoPlayer/video_player.dart';
import 'package:logger/logger.dart';
import 'package:rbd_app/authentication/login_page.dart';

class SubjectPage extends StatefulWidget {
  final String subjectName;
  final List<Map<String, dynamic>> subjectVideos;

  const SubjectPage({
    Key? key,
    required this.subjectName,
    required this.subjectVideos,
  }) : super(key: key);

  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Logger logger = Logger();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredVideos = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    filteredVideos = widget.subjectVideos;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredVideos = widget.subjectVideos;
        isSearching = false;
      } else {
        filteredVideos =
            widget.subjectVideos.where((video) {
              final topic = video['topic'].toString().toLowerCase();
              final subtopic = video['subtopic'].toString().toLowerCase();
              final name = video['name'].toString().toLowerCase();
              return topic.contains(query) ||
                  subtopic.contains(query) ||
                  name.contains(query);
            }).toList();
        isSearching = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> organizedVideos = {};

    for (var video in filteredVideos) {
      String topic = video['topic'];
      if (!organizedVideos.containsKey(topic)) {
        organizedVideos[topic] = [];
      }
      organizedVideos[topic]!.add(video);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search videos by topic or name...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Search Results Info
          if (isSearching)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Text(
                    'Found ${filteredVideos.length} video${filteredVideos.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Videos List
          Expanded(
            child:
                filteredVideos.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            isSearching
                                ? 'No videos found'
                                : 'No videos available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            isSearching
                                ? 'Try different keywords'
                                : 'Videos will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView(
                      padding: EdgeInsets.all(16),
                      children:
                          organizedVideos.entries.map((topicEntry) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Colors.grey.shade50],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  topicEntry.key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${topicEntry.value.length} video${topicEntry.value.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                children:
                                    topicEntry.value.map((video) {
                                      return ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        title: Text(
                                          video['subtopic'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Batch: ${video['batch']} | Size: ${video['size']} MB',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.blue.shade400,
                                                Colors.blue.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                    context,
                                                  ) => VideoPlayerScreen(
                                                    videoUrl:
                                                        'https://vz-d5d4ebc7-6d2.b-cdn.net/${video['bunnyVideoId']}/playlist.m3u8',
                                                    actorName: user!.email!,
                                                    videoName: video['name'],
                                                  ),
                                            ),
                                          );
                                          logger.i(
                                            "Navigating to video: ${video['name']} for student: ${user!.email}",
                                          );
                                        },
                                      );
                                    }).toList(),
                              ),
                            );
                          }).toList(),
                    ),
          ),
        ],
      ),
    );
  }
}
