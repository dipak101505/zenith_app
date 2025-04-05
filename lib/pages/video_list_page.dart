import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rbd_app/pages/videoPlayer/video_player.dart';
import 'package:logger/logger.dart';
import 'package:rbd_app/authentication/login_page.dart';

class VideoListPage extends StatefulWidget {
  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Logger logger = Logger();
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    if (user == null) return;

    try {
      final startTime = DateTime.now(); // Start time for fetching student data
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .where('email', isEqualTo: user!.email)
              .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          error = "Student not found";
          isLoading = false;
        });
        logger.e("Student not found for email: ${user!.email}");
        return;
      }

      DocumentSnapshot studentDoc = querySnapshot.docs.first;

      Map<String, dynamic> studentData =
          studentDoc.data() as Map<String, dynamic>;

      if (studentData['status'] != 'active') {
        setState(() {
          error =
              "Your account is currently inactive. Please contact administrator.";
          isLoading = false;
        });
        logger.w("Inactive student account for email: ${user!.email}");
        return;
      }

      final endTime = DateTime.now(); // End time for fetching student data
      logger.i(
        "Time taken to fetch student data: ${endTime.difference(startTime).inMilliseconds} ms",
      );

      fetchFiles(studentData);
    } catch (e) {
      setState(() {
        error = "Failed to fetch student data";
        isLoading = false;
      });
      logger.e("Failed to fetch student data for email: ${user!.email}");
    }
  }

  Future<void> fetchFiles(Map<String, dynamic> studentData) async {
    try {
      final startTime = DateTime.now(); // Start time for fetching files
      List<Map<String, dynamic>> videoFiles = await retrieveVideoFiles();
      // List<Map<String, dynamic>> pdfFiles = await fetchPdfFiles();
      List<Map<String, dynamic>> pdfFiles = [];
      List<Map<String, dynamic>> allFiles = [...videoFiles, ...pdfFiles];

      allFiles =
          allFiles.where((file) {
            return studentData['batch'].contains(file['batch']) &&
                studentData['subjects'].contains(file['subject']);
          }).toList();

      final endTime = DateTime.now(); // End time for fetching files
      logger.i(
        "Time taken to fetch files: ${endTime.difference(startTime).inMilliseconds} ms",
      );

      setState(() {
        videos = allFiles;
        isLoading = false;
      });
      logger.i("Fetched ${videos.length} files for student: ${user!.email}");
    } catch (e) {
      setState(() {
        error = "Failed to fetch files";
        isLoading = false;
      });
      logger.e("Failed to fetch files for student: ${user!.email}");
    }
  }

  Future<List<Map<String, dynamic>>> retrieveVideoFiles() async {
    List<Map<String, dynamic>> videoFiles = [];
    try {
      final startTime = DateTime.now(); // Start time for retrieving video files
      final response = await http.get(
        Uri.parse(
          'https://3mpoeitria4xncojcr3icdsdum0krrff.lambda-url.ap-south-1.on.aws/',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['videoFiles'] as List<dynamic>;

      videoFiles =
          items.map((item) {
            return {
              'name': item['name'],
              'batch': item['batch'],
              'subject': item['subject'],
              'topic': item['topic'],
              'subtopic': item['subtopic'],
              'lastModified': item['lastModified'],
              'size': item['size'],
              'type': item['type'],
              'bunnyVideoId': item['bunnyVideoId'],
            };
          }).toList();

      final endTime = DateTime.now(); // End time for retrieving video files
      logger.i(
        "Time taken to retrieve video files: ${endTime.difference(startTime).inMilliseconds} ms",
      );
      logger.i("Fetched ${videoFiles.length} video files from AWS Lambda");
    } catch (e) {
      logger.e("Failed to retrieve video files from AWS Lambda: $e");
    }
    return videoFiles;
  }

  Future<List<Map<String, dynamic>>> fetchPdfFiles() async {
    List<Map<String, dynamic>> pdfFiles = [];
    try {
      final startTime = DateTime.now(); // Start time for retrieving PDF files
      ListResult result = await FirebaseStorage.instance.ref('pdfs').listAll();

      for (Reference ref in result.items) {
        FullMetadata metadata = await ref.getMetadata();
        String name = ref.name;
        List<String> nameParts = name.replaceAll('.pdf', '').split('_');
        String batch = nameParts[0];
        String subject = nameParts[1];
        String topic = nameParts[2];
        String subtopic = nameParts.length > 3 ? nameParts[3] : 'untitled';

        pdfFiles.add({
          'name': name,
          'batch': batch,
          'subject': subject,
          'topic': topic,
          'subtopic': subtopic,
          'lastModified': metadata.timeCreated,
          'size': (1024).toStringAsFixed(2),
          'type': 'pdf',
        });
      }

      final endTime = DateTime.now(); // End time for retrieving PDF files
      logger.i(
        "Time taken to retrieve PDF files: ${endTime.difference(startTime).inMilliseconds} ms",
      );
      logger.i("Fetched ${pdfFiles.length} PDF files");
    } catch (e) {
      logger.e("Failed to retrieve PDF files");
    }
    return pdfFiles;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Video Library'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
            ),
          ],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Video Library'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
            ),
          ],
        ),
        body: Center(child: Text(error!)),
      );
    }

    Map<String, Map<String, List<Map<String, dynamic>>>> organizedVideos = {};

    for (var video in videos) {
      String subject = video['subject'];
      String topic = video['topic'];
      if (!organizedVideos.containsKey(subject)) {
        organizedVideos[subject] = {};
      }
      if (!organizedVideos[subject]!.containsKey(topic)) {
        organizedVideos[subject]![topic] = [];
      }
      organizedVideos[subject]![topic]!.add(video);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Library'),
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
      body: ListView(
        children:
            organizedVideos.entries.map((subjectEntry) {
              return ExpansionTile(
                title: Text(
                  subjectEntry.key,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                children:
                    subjectEntry.value.entries.map((topicEntry) {
                      return Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 15,
                        ),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            topicEntry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          children:
                              topicEntry.value.map((video) {
                                return ListTile(
                                  title: Text(
                                    video['subtopic'],
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    'Batch: ${video['batch']} | Size: ${video['size']} MB',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.orange,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => VideoPlayerScreen(
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
              );
            }).toList(),
      ),
    );
  }
}
