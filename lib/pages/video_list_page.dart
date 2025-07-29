import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rbd_app/pages/videoPlayer/video_player.dart';
import 'package:rbd_app/pages/subject_page.dart';
import 'package:rbd_app/pages/assignments_page.dart';
import 'package:rbd_app/pages/announcements_page.dart';
import 'package:rbd_app/pages/lessons_page.dart';
import 'package:rbd_app/pages/topics_page.dart';
import 'package:rbd_app/pages/academic_calendar_page.dart';
import 'package:rbd_app/pages/exams_page.dart';
import 'package:rbd_app/pages/add_result_page.dart';
import 'package:rbd_app/pages/manage_leaves_page.dart';
import 'package:rbd_app/pages/student_leaves_page.dart';
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

  IconData _getSubjectIcon(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'chemistry':
        return Icons.science;
      case 'physics':
        return Icons.speed;
      case 'biology':
        return Icons.biotech;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Zenith'),
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
          title: Text('Zenith'),
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

    // Organize videos by subject
    Map<String, List<Map<String, dynamic>>> organizedVideos = {};

    for (var video in videos) {
      String subject = video['subject'];
      if (!organizedVideos.containsKey(subject)) {
        organizedVideos[subject] = [];
      }
      organizedVideos[subject]!.add(video);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Zenith'),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subjects Module
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subjects',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: organizedVideos.length,
                    itemBuilder: (context, index) {
                      String subjectName = organizedVideos.keys.elementAt(
                        index,
                      );
                      List<Map<String, dynamic>> subjectVideos =
                          organizedVideos[subjectName]!;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.grey.shade50],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => SubjectPage(
                                        subjectName: subjectName,
                                        subjectVideos: subjectVideos,
                                      ),
                                ),
                              );
                              logger.i(
                                "Navigating to subject: $subjectName for student: ${user!.email}",
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.blue.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getSubjectIcon(subjectName),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    subjectName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.grey.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '${subjectVideos.length} videos',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Today's Timetable Module
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Timetable',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.orange.shade50, Colors.orange.shade100],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No classes scheduled for today',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your daily schedule will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Explore Academics Module
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Academics',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      List<Map<String, dynamic>> academicFeatures = [
                        {'title': 'Assignments', 'icon': Icons.book},
                        {'title': 'Announcements', 'icon': Icons.campaign},
                        {'title': 'Lessons', 'icon': Icons.person},
                        {'title': 'Topics', 'icon': Icons.present_to_all},
                        {
                          'title': 'Academic Calendar',
                          'icon': Icons.calendar_today,
                        },
                        {'title': 'Exams', 'icon': Icons.assignment},
                        {'title': 'Add Result', 'icon': Icons.note_add},
                        {
                          'title': 'Manage Leaves',
                          'icon': Icons.calendar_month,
                        },
                        {'title': 'Student Leaves', 'icon': Icons.people},
                      ];

                      return Container(
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              switch (index) {
                                case 0:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AssignmentsPage(),
                                    ),
                                  );
                                  break;
                                case 1:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AnnouncementsPage(),
                                    ),
                                  );
                                  break;
                                case 2:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => LessonsPage(),
                                    ),
                                  );
                                  break;
                                case 3:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => TopicsPage(),
                                    ),
                                  );
                                  break;
                                case 4:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AcademicCalendarPage(),
                                    ),
                                  );
                                  break;
                                case 5:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ExamsPage(),
                                    ),
                                  );
                                  break;
                                case 6:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AddResultPage(),
                                    ),
                                  );
                                  break;
                                case 7:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ManageLeavesPage(),
                                    ),
                                  );
                                  break;
                                case 8:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => StudentLeavesPage(),
                                    ),
                                  );
                                  break;
                              }
                              logger.i(
                                "Navigating to: ${academicFeatures[index]['title']}",
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.indigo.shade400,
                                          Colors.indigo.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      academicFeatures[index]['icon'],
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    academicFeatures[index]['title'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
