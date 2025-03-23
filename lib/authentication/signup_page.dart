import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rbd_app/pages/home_page.dart';
import 'package:rbd_app/authentication/login_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  late String _email,
      _password,
      _confirmPassword,
      _name,
      _mobile,
      _centre,
      _batch;
  File? _profileImage;
  bool _isLoading = false;
  List<String> _centres = [];
  List<String> _batches = [];

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
        _centres =
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
        .child('user_images')
        .child('$uid.jpg');
    await ref.putFile(_profileImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }
    try {
      setState(() => _isLoading = true);
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      final uid = userCredential.user!.uid;
      final imageUrl = await _uploadProfileImage(uid);

      await FirebaseFirestore.instance.collection('students').doc(uid).set({
        'uid': uid,
        'email': _email,
        'name': _name,
        'centre': _centre,
        'batch': _batch,
        'mobile': _mobile,
        'imageUrl': imageUrl ?? '',
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      await userCredential.user!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent. Check your inbox.')),
      );
      Navigator.pop(context);
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
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Full Name'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter your name' : null,
                        onSaved: (value) => _name = value!.trim(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Email'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter your email' : null,
                        onSaved: (value) => _email = value!.trim(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Mobile'),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Enter your mobile number'
                                    : null,
                        onSaved: (value) => _mobile = value!.trim(),
                      ),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Centre'),
                        items:
                            _centres.map((centre) {
                              return DropdownMenuItem<String>(
                                value: centre,
                                child: Text(centre),
                              );
                            }).toList(),
                        onChanged: (value) => _centre = value!,
                        validator:
                            (value) => value == null ? 'Select a centre' : null,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Batch'),
                        items:
                            _batches.map((batch) {
                              return DropdownMenuItem<String>(
                                value: batch,
                                child: Text(batch),
                              );
                            }).toList(),
                        onChanged: (value) => _batch = value!,
                        validator:
                            (value) => value == null ? 'Select a batch' : null,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter a password' : null,
                        onSaved: (value) => _password = value!.trim(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                        ),
                        obscureText: true,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Confirm your password' : null,
                        onSaved: (value) => _confirmPassword = value!.trim(),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                Colors.orange, // Set background color to orange
                            backgroundImage:
                                _profileImage == null
                                    ? null
                                    : FileImage(_profileImage!),
                            child:
                                _profileImage == null
                                    ? Icon(
                                      Icons.person,
                                      size: 32,
                                      color: Colors.white,
                                    ) // Optional: change icon color for better contrast
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
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text('Register'),
                      ),
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
