import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:rbd_app/authentication/login_page.dart';
import 'package:rbd_app/services/exams_service.dart';
import 'package:rbd_app/pages/exam_interface_page.dart';

class AcademicCalendarPage extends StatefulWidget {
  @override
  _AcademicCalendarPageState createState() => _AcademicCalendarPageState();
}

class _AcademicCalendarPageState extends State<AcademicCalendarPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Logger logger = Logger();
  final ExamsService _examsService = ExamsService();

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  String _selectedFilter = 'All';
  bool _isLoading = false;
  List<Exam> _exams = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exams = await _examsService.getExams();
      setState(() {
        _exams = exams;
        _events =
            exams
                .map(
                  (exam) => {
                    'title': exam.title,
                    'description': exam.description,
                    'date': exam.date,
                    'type': exam.type,
                    'subject': exam.subject,
                    'duration': exam.duration,
                    'venue': exam.venue,
                    'time': exam.time,
                    'totalMarks': exam.totalMarks,
                    'batch': exam.batch,
                    'videoKey': exam.videoKey,
                    'questions': exam.questions,
                    'sections': exam.sections,
                  },
                )
                .toList();
        _isLoading = false;
      });
    } catch (error) {
      logger.e('Error loading exams: $error');
      setState(() {
        _isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load exams: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredEvents {
    if (_selectedFilter == 'All') {
      return _events;
    }
    return _events.where((event) => event['type'] == _selectedFilter).toList();
  }

  List<Map<String, dynamic>>? get selectedEvents {
    final eventsOnSelectedDate =
        _events
            .where(
              (event) =>
                  event['date'].day == _selectedDate.day &&
                  event['date'].month == _selectedDate.month &&
                  event['date'].year == _selectedDate.year,
            )
            .toList();
    return eventsOnSelectedDate.isNotEmpty ? eventsOnSelectedDate : null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          'Academic Calendar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadExams,
          ),
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
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading exams...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Month Navigation
                    Container(
                      margin: EdgeInsets.all(isTablet ? 24 : 16),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                        vertical: isTablet ? 16 : 12,
                      ),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _focusedDate = DateTime(
                                  _focusedDate.year,
                                  _focusedDate.month - 1,
                                );
                              });
                            },
                          ),
                          Text(
                            '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _focusedDate = DateTime(
                                  _focusedDate.year,
                                  _focusedDate.month + 1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Calendar Grid
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                      ),
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
                        children: [
                          // Days of week header
                          Row(
                            children:
                                [
                                      'Sun',
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                    ]
                                    .map(
                                      (day) => Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isTablet ? 12 : 8,
                                          ),
                                          child: Text(
                                            day,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          Divider(height: 1),
                          // Calendar days
                          ..._buildCalendarDays(isTablet),
                        ],
                      ),
                    ),

                    // Filter Tabs
                    Container(
                      margin: EdgeInsets.all(isTablet ? 24 : 16),
                      child: Row(
                        children: [
                          _buildFilterTab('All', null, isTablet),
                          SizedBox(width: isTablet ? 12 : 8),
                          _buildFilterTab('Events', Colors.green, isTablet),
                          SizedBox(width: isTablet ? 12 : 8),
                          _buildFilterTab('Exams', Colors.red, isTablet),
                        ],
                      ),
                    ),

                    // Event Details Card
                    if (selectedEvents != null)
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                        ),
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
                              'Exams on ${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            if (selectedEvents!.isNotEmpty) ...[
                              ...selectedEvents!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final event = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (index > 0) ...[
                                      Divider(
                                        height: 24,
                                        color: Colors.grey.shade300,
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ExamInterfacePage(
                                                  exam: event,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event['title'],
                                                style: TextStyle(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Colors.blue.shade600,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 8 : 6),
                                    Text(
                                      event['description'],
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : 12,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 12 : 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: isTablet ? 18 : 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${event['date'].day.toString().padLeft(2, '0')}-${event['date'].month.toString().padLeft(2, '0')}-${event['date'].year}',
                                          style: TextStyle(
                                            fontSize: isTablet ? 14 : 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (event['subject'] != null) ...[
                                      SizedBox(height: isTablet ? 8 : 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.book,
                                            size: isTablet ? 18 : 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Subject: ${event['subject']}',
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (event['duration'] != null) ...[
                                      SizedBox(height: isTablet ? 8 : 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            size: isTablet ? 18 : 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Duration: ${event['duration']}',
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (event['totalMarks'] != null) ...[
                                      SizedBox(height: isTablet ? 8 : 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.score,
                                            size: isTablet ? 18 : 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Total Marks: ${event['totalMarks']}',
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (event['batch'] != null) ...[
                                      SizedBox(height: isTablet ? 8 : 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.group,
                                            size: isTablet ? 18 : 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Batch: ${event['batch']}',
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),

                    // Bottom padding for scroll
                    SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildFilterTab(String title, Color? dotColor, bool isTablet) {
    final isSelected = _selectedFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = title;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 12 : 8,
            horizontal: isTablet ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey.shade200 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: isTablet ? 10 : 8,
                  height: isTablet ? 10 : 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? Colors.grey.shade800 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendarDays(bool isTablet) {
    final days = <Widget>[];
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to Sunday = 0

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(_buildDayCell('', isCurrentMonth: false, isTablet: isTablet));
    }

    // Add days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final eventsOnDay =
          _events
              .where(
                (event) =>
                    event['date'].day == day &&
                    event['date'].month == _focusedDate.month &&
                    event['date'].year == _focusedDate.year,
              )
              .toList();
      final hasEvent = eventsOnDay.isNotEmpty;
      final hasMultipleEvents = eventsOnDay.length > 1;
      final isSelected =
          _selectedDate.day == day &&
          _selectedDate.month == _focusedDate.month &&
          _selectedDate.year == _focusedDate.year;

      days.add(
        _buildDayCell(
          day.toString(),
          hasEvent: hasEvent,
          hasMultipleEvents: hasMultipleEvents,
          isSelected: isSelected,
          isTablet: isTablet,
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
      );
    }

    // Add empty cells to complete the grid
    final remainingCells = 42 - days.length; // 6 rows * 7 days = 42
    for (int i = 0; i < remainingCells; i++) {
      days.add(_buildDayCell('', isCurrentMonth: false, isTablet: isTablet));
    }

    // Group into rows
    final rows = <Widget>[];
    for (int i = 0; i < days.length; i += 7) {
      rows.add(Row(children: days.skip(i).take(7).toList()));
    }

    return rows;
  }

  Widget _buildDayCell(
    String day, {
    bool hasEvent = false,
    bool hasMultipleEvents = false,
    bool isSelected = false,
    bool isCurrentMonth = true,
    bool isTablet = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: isTablet ? 60 : 40,
          margin: EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isCurrentMonth
                          ? (isSelected
                              ? Colors.blue.shade800
                              : Colors.grey.shade800)
                          : Colors.grey.shade400,
                ),
              ),
              if (hasEvent)
                Container(
                  width: isTablet ? 6 : 4,
                  height: isTablet ? 6 : 4,
                  decoration: BoxDecoration(
                    color: hasMultipleEvents ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
