import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rbd_app/authentication/login_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _class = '11';
  String _board = '';
  String _batch = '';
  List<String> _centres = [];
  String _dobYear = '';
  String _dobMonth = '';
  String _dobDay = '';
  File? _profileImage;

  // Dropdown options
  List<String> _classes = List.generate(12, (index) => (index + 1).toString());
  List<String> _boards = ['CBSE', 'ICSE', 'WB'];
  List<String> _batches = [];
  List<String> _availableCentres = [];
  List<String> _years = List.generate(
    100,
    (index) => (2025 - index).toString(),
  );
  List<String> _months = List.generate(12, (index) => (index + 1).toString());
  List<String> _days = List.generate(31, (index) => (index + 1).toString());

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCentresAndBatches();
  }

  Future<void> _fetchCentresAndBatches() async {
    try {
      final centresSnapshot =
          await FirebaseFirestore.instance.collection('centres').get();
      final batchesSnapshot =
          await FirebaseFirestore.instance.collection('batches').get();

      setState(() {
        _availableCentres =
            centresSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _batches =
            batchesSnapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching centres and batches: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImage == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('student-images')
        .child('$uid.jpg');
    await ref.putFile(_profileImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Combine Date of Birth
    final dob = '$_dobYear-$_dobMonth-$_dobDay';

    try {
      setState(() => _isLoading = true);

      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // Upload profile image
      final imageUrl = await _uploadProfileImage(uid);

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('students').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
        'dob': dob,
        'school': _schoolController.text.trim(),
        'class': _class,
        'board': _board,
        'batch': _batch,
        'centres': _centres, // Store as an array of strings
        'imageUrl': imageUrl ?? '',
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      // Send email verification
      await userCredential.user!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent. Check your inbox.')),
      );

      // Navigate to login page
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Full Name *'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter your name' : null,
                      ),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email *'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter your email' : null,
                      ),

                      // Mobile
                      TextFormField(
                        controller: _mobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number *',
                        ),
                        validator:
                            (value) =>
                                value!.length != 10
                                    ? 'Enter a valid 10-digit mobile number'
                                    : null,
                      ),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(labelText: 'Address'),
                      ),

                      // Date of Birth Dropdown
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(labelText: 'Year'),
                              items:
                                  _years
                                      .map(
                                        (year) => DropdownMenuItem(
                                          value: year,
                                          child: Text(year),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setState(() => _dobYear = value!),
                              validator:
                                  (value) =>
                                      value == null ? 'Select year' : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(labelText: 'Month'),
                              items:
                                  _months
                                      .map(
                                        (month) => DropdownMenuItem(
                                          value: month,
                                          child: Text(month),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setState(() => _dobMonth = value!),
                              validator:
                                  (value) =>
                                      value == null ? 'Select month' : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(labelText: 'Day'),
                              items:
                                  _days
                                      .map(
                                        (day) => DropdownMenuItem(
                                          value: day,
                                          child: Text(day),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setState(() => _dobDay = value!),
                              validator:
                                  (value) =>
                                      value == null ? 'Select day' : null,
                            ),
                          ),
                        ],
                      ),

                      // Centres (Multi-Select)
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Centre *'),
                        items:
                            _availableCentres
                                .map(
                                  (centre) => DropdownMenuItem(
                                    value: centre,
                                    child: Text(centre),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null && !_centres.contains(value)) {
                            setState(() => _centres.add(value));
                          }
                        },
                        validator:
                            (value) =>
                                _centres.isEmpty
                                    ? 'Select at least one centre'
                                    : null,
                      ),
                      Wrap(
                        children:
                            _centres
                                .map(
                                  (centre) => Chip(
                                    label: Text(centre),
                                    onDeleted: () {
                                      setState(() => _centres.remove(centre));
                                    },
                                  ),
                                )
                                .toList(),
                      ),

                      // Class
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Class *'),
                        items:
                            _classes
                                .map(
                                  (cls) => DropdownMenuItem(
                                    value: cls,
                                    child: Text('Class $cls'),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _class = value!),
                        validator:
                            (value) => value == null ? 'Select a class' : null,
                      ),

                      // Board
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Board *'),
                        items:
                            _boards
                                .map(
                                  (board) => DropdownMenuItem(
                                    value: board,
                                    child: Text(board),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _board = value!),
                        validator:
                            (value) => value == null ? 'Select a board' : null,
                      ),

                      // Batch
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Batch *'),
                        items:
                            _batches
                                .map(
                                  (batch) => DropdownMenuItem(
                                    value: batch,
                                    child: Text(batch),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _batch = value!),
                        validator:
                            (value) => value == null ? 'Select a batch' : null,
                      ),

                      // School Name
                      TextFormField(
                        controller: _schoolController,
                        decoration: InputDecoration(labelText: 'School Name *'),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Enter your school name'
                                    : null,
                      ),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Password *'),
                        obscureText: true,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter a password' : null,
                      ),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                        ),
                        obscureText: true,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Confirm your password' : null,
                      ),

                      // Profile Picture
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage:
                                _profileImage == null
                                    ? null
                                    : FileImage(_profileImage!),
                            child:
                                _profileImage == null
                                    ? Icon(Icons.person, size: 32)
                                    : null,
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _pickImage,
                            child: Text('Choose Image'),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text('Register'),
                      ),

                      // Login Link
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        child: Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
