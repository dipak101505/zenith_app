import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:rbd_app/authentication/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExamInterfacePage extends StatefulWidget {
  final Map<String, dynamic> exam;

  const ExamInterfacePage({Key? key, required this.exam}) : super(key: key);

  @override
  _ExamInterfacePageState createState() => _ExamInterfacePageState();
}

class _ExamInterfacePageState extends State<ExamInterfacePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Logger logger = Logger();

  bool _isExamStarted = false;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _timeRemaining = 0;
  List<String> _selectedAnswers = [];

  // API data
  List<Map<String, dynamic>> _questions = [];
  String _examId = '';
  int _totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    _initializeExam();
  }

  void _initializeExam() {
    // Parse duration from exam data - handle different data types
    int duration = 0;
    final durationData = widget.exam['duration'];

    if (durationData != null) {
      if (durationData is int) {
        duration = durationData;
      } else if (durationData is String) {
        // Extract numeric part from strings like "60 minutes", "45", etc.
        final numericMatch = RegExp(r'(\d+)').firstMatch(durationData);
        if (numericMatch != null) {
          duration = int.tryParse(numericMatch.group(1)!) ?? 0;
        } else {
          duration = int.tryParse(durationData) ?? 0;
        }
      } else if (durationData is double) {
        duration = durationData.toInt();
      }
    }

    // Set a minimum duration of 1 minute if duration is 0 or invalid
    if (duration <= 0) {
      duration = 2;
    }

    _timeRemaining = duration * 60; // Convert minutes to seconds

    // Debug logging
    logger.i(
      'Raw duration data: $durationData (type: ${durationData.runtimeType})',
    );
    logger.i(
      'Parsed duration: $duration minutes, Time remaining: $_timeRemaining seconds',
    );

    // Fetch exam data from API
    _fetchExamData();
  }

  Future<void> _fetchExamData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Log the exam data being passed to the page
      Map<String, dynamic> examDataForLogging = Map<String, dynamic>.from(
        widget.exam,
      );

      // Convert DateTime to string for logging
      if (examDataForLogging['date'] is DateTime) {
        examDataForLogging['date'] =
            (examDataForLogging['date'] as DateTime).toIso8601String();
      }

      logger.i(
        'Exam data passed to ExamInterfacePage: ${json.encode(examDataForLogging)}',
      );

      // Extract video key from the exam data
      String videoKey =
          widget.exam['videoKey']?.toString() ??
          widget.exam['video_key']?.toString() ??
          '2024-2025_Chemistry_Reaction Intermediate_Lecture 5'; // fallback

      logger.i('Extracted video key: $videoKey');

      final url =
          'https://y4ts2p2ahze5lr66u6qfwjk74u0eruel.lambda-url.ap-south-1.on.aws/?videoKey=${Uri.encodeComponent(videoKey)}';

      logger.i('Fetching exam data from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Log the complete API response
        logger.i('API Response: ${json.encode(data)}');

        if (data['success'] == true && data['data'] != null) {
          final examData = data['data'];

          // Log the exam data structure
          logger.i('Exam Data: ${json.encode(examData)}');
          logger.i('Questions count: ${examData['questions']?.length ?? 0}');
          logger.i('Exam ID: ${examData['exam_id']}');
          logger.i('Video Key: ${examData['video_key']}');
          logger.i('Total Questions: ${examData['total_questions']}');

          setState(() {
            _questions = List<Map<String, dynamic>>.from(
              examData['questions'] ?? [],
            );
            _examId = examData['exam_id']?.toString() ?? '';
            _totalQuestions = examData['total_questions'] ?? 0;
            _selectedAnswers = List.filled(_questions.length, '');
            _isLoading = false;
          });

          logger.i('Successfully loaded ${_questions.length} questions');

          // Log each question structure
          for (int i = 0; i < _questions.length; i++) {
            final question = _questions[i];
            logger.i('Question ${i + 1}: ${json.encode(question)}');
          }
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load exam data: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error fetching exam data: $e');
      setState(() {
        _isLoading = false;
        // Fallback to sample questions if API fails
        _questions = _getSampleQuestions();
        _selectedAnswers = List.filled(_questions.length, '');
      });
    }
  }

  // Generate sample questions with LaTeX content for fallback
  List<Map<String, dynamic>> _getSampleQuestions() {
    return [
      {
        'contents': [
          {
            'type': 'latex',
            'value': 'Solve the quadratic equation: \$x^2 - 4x + 4 = 0\$',
          },
        ],
        'options': [
          {
            'contents': [
              {'type': 'latex', 'value': 'A) x = 2'},
            ],
          },
          {
            'contents': [
              {'type': 'latex', 'value': 'B) x = -2'},
            ],
          },
          {
            'contents': [
              {'type': 'latex', 'value': 'C) x = 0'},
            ],
          },
          {
            'contents': [
              {'type': 'latex', 'value': 'D) x = 1'},
            ],
          },
        ],
        'correctAnswer': 'a',
      },
      {
        'contents': [
          {
            'type': 'latex',
            'value': 'What is the value of \$\int_0^1 x^2 dx\$?',
          },
        ],
        'options': [
          {
            'contents': [
              {'type': 'latex', 'value': 'A) \$\frac{1}{3}\$'},
            ],
          },
          {
            'contents': [
              {'type': 'latex', 'value': 'B) \$\frac{1}{2}\$'},
            ],
          },
          {
            'contents': [
              {'type': 'latex', 'value': 'C) \$\frac{2}{3}\$'},
            ],
          },
          {
            'contents': [
              {'type': 'latex', 'value': 'D) \$\frac{3}{4}\$'},
            ],
          },
        ],
        'correctAnswer': 'a',
      },
    ];
  }

  // Helper function to render content (simplified for now)
  Widget _renderLaTeXContent(String content) {
    // Check if content is null or empty
    if (content.isEmpty) {
      return Text(
        'No content available',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade800,
          height: 1.4,
        ),
      );
    }

    // For now, just return regular text to avoid LaTeX issues
    return Text(
      content,
      style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.4),
    );
  }

  // Helper function to extract text from content array
  String _extractTextFromContents(List<dynamic> contents) {
    if (contents.isEmpty) return '';

    String result = '';
    for (var content in contents) {
      if (content is Map<String, dynamic>) {
        String type = content['type']?.toString() ?? '';
        String value = content['value']?.toString() ?? '';

        if (type == 'latex' || type == 'text') {
          result += value;
        }
      }
    }
    return result;
  }

  // Helper function to get question text
  String _getQuestionText(Map<String, dynamic> question) {
    List<dynamic> contents = question['contents'] ?? [];
    return _extractTextFromContents(contents);
  }

  // Helper function to get options
  List<String> _getOptions(Map<String, dynamic> question) {
    List<dynamic> options = question['options'] ?? [];
    List<String> result = [];

    for (int i = 0; i < options.length; i++) {
      var option = options[i];
      if (option is Map<String, dynamic>) {
        List<dynamic> contents = option['contents'] ?? [];
        String optionText = _extractTextFromContents(contents);
        result.add(optionText);
      }
    }

    return result;
  }

  void _startExam() {
    logger.i('Starting exam with $_timeRemaining seconds remaining');
    setState(() {
      _isExamStarted = true;
    });
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _timeRemaining > 0 && _isExamStarted) {
        setState(() {
          _timeRemaining--;
        });
        logger.i('Timer: $_timeRemaining seconds remaining');
        _startTimer();
      } else if (_timeRemaining <= 0) {
        logger.i('Timer expired, submitting exam');
        _submitExam();
      }
    });
  }

  void _submitExam() {
    setState(() {
      _isExamStarted = false;
    });

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Exam Completed'),
          content: Text('Your exam has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to calendar
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          'Exam Interface',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isExamStarted) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _timeRemaining < 300 ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatTime(_timeRemaining),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
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
              ? _buildLoadingScreen()
              : (_isExamStarted ? _buildExamInterface() : _buildExamStart()),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          SizedBox(height: 16),
          Text(
            'Loading exam data...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildExamStart() {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam['title'] ?? 'Exam',
                  style: TextStyle(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  widget.exam['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Exam Details
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exam Details',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),

                _buildDetailRow(
                  'Subject',
                  widget.exam['subject'] ?? 'Not specified',
                ),
                _buildDetailRow('Duration', '${_getParsedDuration()} minutes'),
                _buildDetailRow(
                  'Total Marks',
                  widget.exam['totalMarks']?.toString() ?? 'Not specified',
                ),
                _buildDetailRow('Questions', '$_totalQuestions questions'),
                if (_examId.isNotEmpty) _buildDetailRow('Exam ID', _examId),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Start Exam Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _questions.isNotEmpty ? _startExam : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _questions.isNotEmpty ? 'Start Exam' : 'No Questions Available',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 120 : 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamInterface() {
    // Ensure _selectedAnswers is properly initialized
    if (_selectedAnswers.length != _questions.length) {
      _selectedAnswers = List.filled(_questions.length, '');
    }

    final currentQuestion =
        _questions.isNotEmpty && _currentQuestionIndex < _questions.length
            ? _questions[_currentQuestionIndex]
            : null;

    final isTablet = MediaQuery.of(context).size.width > 600;

    return Column(
      children: [
        // Progress Bar
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value:
                      _questions.isNotEmpty
                          ? (_currentQuestionIndex + 1) / _questions.length
                          : 0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Text(
                '${_currentQuestionIndex + 1} / ${_questions.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        // Question Area
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1}',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 12),
                      _renderLaTeXContent(
                        currentQuestion != null
                            ? _getQuestionText(currentQuestion)
                            : 'Question not available',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Answer Options
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select your answer:',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Answer options with LaTeX support
                      ...(currentQuestion != null
                              ? _getOptions(currentQuestion)
                              : ['A', 'B', 'C', 'D'])
                          .asMap()
                          .entries
                          .map((entry) {
                            int index = entry.key;
                            String optionContent = entry.value;
                            String optionLabel = String.fromCharCode(
                              65 + index,
                            ); // A, B, C, D...

                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: RadioListTile<String>(
                                title: _renderLaTeXContent(
                                  '$optionLabel) $optionContent',
                                ),
                                value: optionLabel,
                                groupValue:
                                    _currentQuestionIndex <
                                            _selectedAnswers.length
                                        ? _selectedAnswers[_currentQuestionIndex]
                                        : null,
                                onChanged: (value) {
                                  setState(() {
                                    if (_currentQuestionIndex <
                                        _selectedAnswers.length) {
                                      _selectedAnswers[_currentQuestionIndex] =
                                          value ?? '';
                                    }
                                  });
                                },
                                activeColor: Colors.blue.shade600,
                              ),
                            );
                          })
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Navigation Buttons
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _currentQuestionIndex < _questions.length - 1
                          ? _nextQuestion
                          : _submitExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentQuestionIndex < _questions.length - 1
                            ? Colors.blue.shade600
                            : Colors.green.shade600,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1
                        ? 'Next'
                        : 'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  int _getParsedDuration() {
    int duration = 0;
    final durationData = widget.exam['duration'];

    if (durationData != null) {
      if (durationData is int) {
        duration = durationData;
      } else if (durationData is String) {
        // Extract numeric part from strings like "60 minutes", "45", etc.
        final numericMatch = RegExp(r'(\d+)').firstMatch(durationData);
        if (numericMatch != null) {
          duration = int.tryParse(numericMatch.group(1)!) ?? 0;
        } else {
          duration = int.tryParse(durationData) ?? 0;
        }
      } else if (durationData is double) {
        duration = durationData.toInt();
      }
    }

    // Set a minimum duration of 1 minute if duration is 0 or invalid
    if (duration <= 0) {
      duration = 2;
    }

    return duration;
  }
}
