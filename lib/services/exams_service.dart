import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class Exam {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type;
  final String? subject;
  final String? duration;
  final String? venue;
  final String? time;
  final String? totalMarks;
  final String? batch;
  final String? videoKey;
  final List<String>? questions;
  final List<String>? sections;

  Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.subject,
    this.duration,
    this.venue,
    this.time,
    this.totalMarks,
    this.batch,
    this.videoKey,
    this.questions,
    this.sections,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] ?? '',
      title: json['name'] ?? '',
      description: 'Exam for ${json['videoKey'] ?? 'Unknown Subject'}',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      type: 'Exams',
      subject:
          json['subject']?.isNotEmpty == true
              ? json['subject']
              : _extractSubjectFromVideoKey(json['videoKey']),
      duration: json['duration'] != null ? '${json['duration']} minutes' : null,
      venue: 'Online',
      time: json['time'],
      totalMarks: json['totalMarks'],
      batch: json['batch'],
      videoKey: json['videoKey'],
      questions:
          json['questions'] != null
              ? List<String>.from(json['questions'])
              : null,
      sections:
          json['sections'] != null ? List<String>.from(json['sections']) : null,
    );
  }

  static String? _extractSubjectFromVideoKey(String? videoKey) {
    if (videoKey == null) return null;

    // Extract subject from video key format: "2024-2025_Chemistry_Reaction Intermediate_Lecture 5"
    final parts = videoKey.split('_');
    if (parts.length >= 3) {
      return parts[1]; // Return the subject part
    }
    return null;
  }
}

class ExamsCache {
  static const int expiryTime = 5 * 60 * 1000; // 5 minutes in milliseconds
  List<Exam>? data;
  int? timestamp;
}

class ExamsService {
  final Logger _logger = Logger();
  final ExamsCache _examsCache = ExamsCache();

  // Your actual Lambda function URL
  final String _lambdaUrl =
      'https://z565sk4guifo7tuqkrvhcrpd4e0pbycq.lambda-url.ap-south-1.on.aws/';

  Future<List<Exam>> getExams() async {
    // Check if we have valid cached data
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (_examsCache.data != null &&
        _examsCache.timestamp != null &&
        (currentTime - _examsCache.timestamp! < ExamsCache.expiryTime)) {
      _logger.i('Returning cached exams data');
      return _examsCache.data!;
    }

    try {
      _logger.i('Fetching exams from Lambda function...');

      final response = await http
          .get(
            Uri.parse(_lambdaUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (responseData['success'] == true && responseData['exams'] != null) {
          final items = responseData['exams'] as List<dynamic>? ?? [];

          final exams =
              items.map((item) {
                return Exam.fromJson(item);
              }).toList();

          _examsCache.data = exams;
          _examsCache.timestamp = currentTime;

          _logger.i('Successfully fetched ${exams.length} exams from Lambda');
          return exams;
        } else {
          _logger.w('Lambda response format unexpected: ${response.body}');
          throw Exception('Unexpected response format');
        }
      } else {
        _logger.e('Lambda request failed with status: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');

        // Fallback to mock data if Lambda fails
        _logger.i('Falling back to mock data');
        final mockExams = _getMockExams();
        _examsCache.data = mockExams;
        _examsCache.timestamp = currentTime;
        return mockExams;
      }
    } catch (error) {
      _logger.e('Error connecting to Lambda: $error');
      _logger.i('Using mock data as fallback');

      final mockExams = _getMockExams();
      _examsCache.data = mockExams;
      _examsCache.timestamp = currentTime;
      return mockExams;
    }
  }

  List<Exam> _getMockExams() {
    return [
      Exam(
        id: 'exam_001',
        title: 'Mathematics Mid-Term',
        description:
            'Comprehensive test covering algebra, calculus, and trigonometry topics.',
        date: DateTime(2025, 7, 15),
        type: 'Exams',
        subject: 'Mathematics',
        duration: '2 hours',
        venue: 'Room 101',
        time: '10:00',
        totalMarks: '100',
        batch: '2024-2025',
        videoKey: '2024-2025_Mathematics_Algebra_Lecture 1',
      ),
      Exam(
        id: 'exam_002',
        title: 'Physics Lab Practical',
        description:
            'Hands-on laboratory session covering mechanics and thermodynamics experiments.',
        date: DateTime(2025, 7, 18),
        type: 'Exams',
        subject: 'Physics',
        duration: '3 hours',
        venue: 'Physics Lab',
        time: '14:30',
        totalMarks: '80',
        batch: '2024-2025',
        videoKey: '2024-2025_Physics_Mechanics_Lecture 2',
      ),
      Exam(
        id: 'exam_003',
        title: 'Chemistry Quiz',
        description:
            'Weekly quiz on organic chemistry and chemical bonding concepts.',
        date: DateTime(2025, 7, 22),
        type: 'Exams',
        subject: 'Chemistry',
        duration: '1 hour',
        venue: 'Room 203',
        time: '16:00',
        totalMarks: '50',
        batch: '2024-2025',
        videoKey: '2024-2025_Chemistry_Organic_Lecture 3',
      ),
      Exam(
        id: 'exam_004',
        title: 'English Literature Test',
        description: 'Analysis of Shakespearean plays and modern literature.',
        date: DateTime(2025, 7, 25),
        type: 'Exams',
        subject: 'English',
        duration: '1.5 hours',
        venue: 'Room 105',
        time: '11:30',
        totalMarks: '60',
        batch: '2024-2025',
        videoKey: '2024-2025_English_Literature_Lecture 4',
      ),
      Exam(
        id: 'exam_005',
        title: 'Computer Science Project',
        description:
            'Final project presentation for software development course.',
        date: DateTime(2025, 7, 28),
        type: 'Exams',
        subject: 'Computer Science',
        duration: '4 hours',
        venue: 'Computer Lab',
        time: '09:00',
        totalMarks: '100',
        batch: '2024-2025',
        videoKey: '2024-2025_ComputerScience_Programming_Lecture 5',
      ),
      Exam(
        id: 'event_001',
        title: 'Science Exhibition',
        description:
            'Annual science exhibition showcasing student projects and innovations.',
        date: DateTime(2025, 7, 10),
        type: 'Events',
        subject: 'Science',
        duration: 'All day',
        venue: 'Auditorium',
        time: '10:00',
        totalMarks: null,
        batch: '2024-2025',
        videoKey: null,
      ),
      Exam(
        id: 'event_002',
        title: 'Sports Day',
        description: 'Annual sports competition with various athletic events.',
        date: DateTime(2025, 7, 12),
        type: 'Events',
        subject: 'Physical Education',
        duration: 'All day',
        venue: 'Sports Ground',
        time: '08:00',
        totalMarks: null,
        batch: '2024-2025',
        videoKey: null,
      ),
    ];
  }

  // Method to clear cache (useful for testing)
  void clearCache() {
    _examsCache.data = null;
    _examsCache.timestamp = null;
  }
}
