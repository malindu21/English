import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final CollectionReference _studentsCollection = FirebaseFirestore.instance
      .collection('students');
  final CollectionReference _schoolsCollection = FirebaseFirestore.instance
      .collection('schools');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _contact1Controller = TextEditingController();
  final TextEditingController _contact2Controller = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _customSourceController = TextEditingController();

  String? _selectedDay;
  TimeOfDay? _selectedTime;
  DateTime? _joinedDate;

  // Image related variables
  File? _selectedImage;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  // Source related variables
  String? _selectedSource;
  final List<String> _sources = [
    'Facebook',
    'Banner/Flex',
    'Word of Mouth',
    'Website',
    'Referral',
    'Other',
  ];

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Academy brand colors inspired by the building
  static const Color primaryGold = Color(0xFFFFB700);
  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color lightGold = Color(0xFFFFE082);
  static const Color darkGold = Color(0xFFFF8F00);

  // Add loading state
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isSchoolLoading = false;

  String? _contact1ValidationMessage;
  String? _contact2ValidationMessage;
  bool _isContact1Valid = true;
  bool _isContact2Valid = true;

  List<String> _schoolOptions = [];
  static const String _addNewSchoolValue = '__add_new_school__';

  @override
  void initState() {
    super.initState();
    _initializeScreen();

    // Add listeners for real-time validation
    _contact1Controller.addListener(_validateContact1);
    _contact2Controller.addListener(_validateContact2);
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isSchoolLoading = true;
    });

    try {
      final snapshot =
          await _schoolsCollection.orderBy('name', descending: false).get();
      final Map<String, String> normalized = {};
      for (final doc in snapshot.docs) {
        final rawName =
            (doc.data() as Map<String, dynamic>)['name']
                ?.toString()
                .trim();
        if (rawName == null || rawName.isEmpty) continue;
        normalized[rawName.toLowerCase()] = rawName;
      }
      final names = normalized.values.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (mounted) {
        setState(() {
          _schoolOptions = names;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error loading schools: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSchoolLoading = false;
        });
      }
    }
  }

  Future<void> _addNewSchool(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('School name cannot be empty')),
            ],
          ),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    final exists = _schoolOptions.any(
      (s) => s.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      setState(() => _schoolController.text = trimmed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('School already exists, selected it')),
            ],
          ),
          backgroundColor: Colors.blue[700],
        ),
      );
      return;
    }

    try {
      await _schoolsCollection.add({
        'name': trimmed,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        _schoolOptions = [..._schoolOptions, trimmed]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _schoolController.text = trimmed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('School added')),
            ],
          ),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error adding school: $e')),
            ],
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _promptAddSchool() async {
    final controller = TextEditingController(text: _schoolController.text);
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add School'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'School name',
                hintText: 'Enter school name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      await _addNewSchool(result);
    }
  }

  // Contact 1 validation method
  void _validateContact1() {
    String value = _contact1Controller.text.trim();
    setState(() {
      if (value.isEmpty) {
        _contact1ValidationMessage = null;
        _isContact1Valid = true;
      } else if (value.length < 10) {
        _contact1ValidationMessage =
            'Contact number must be at least 10 digits';
        _isContact1Valid = false;
      } else if (value.length > 15) {
        _contact1ValidationMessage = 'Contact number cannot exceed 15 digits';
        _isContact1Valid = false;
      } else if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
        _contact1ValidationMessage =
            'Please enter a valid phone number (only digits and optional +)';
        _isContact1Valid = false;
      } else {
        _contact1ValidationMessage = 'Valid contact number ✓';
        _isContact1Valid = true;
      }
    });
  }

  void _validateContact2() {
    String value = _contact2Controller.text.trim();
    setState(() {
      if (value.isEmpty) {
        _contact2ValidationMessage = null;
        _isContact2Valid = true;
      } else if (value.length < 10) {
        _contact2ValidationMessage =
            'Contact number must be at least 10 digits';
        _isContact2Valid = false;
      } else if (value.length > 15) {
        _contact2ValidationMessage = 'Contact number cannot exceed 15 digits';
        _isContact2Valid = false;
      } else if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
        _contact2ValidationMessage =
            'Please enter a valid phone number (only digits and optional +)';
        _isContact2Valid = false;
      } else {
        _contact2ValidationMessage = 'Valid contact number ✓';
        _isContact2Valid = true;
      }
    });
  }

  Future<void> _initializeScreen() async {
    // Simulate loading delay (remove this in production or replace with actual initialization)
    await Future.wait([
      _loadSchools(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    // Add any actual initialization code here
    // For example: loading user preferences, checking permissions, etc.

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Initial compression
      );

      if (pickedFile != null) {
        Uint8List originalBytes = await pickedFile.readAsBytes();
        img.Image? decodedImage = img.decodeImage(originalBytes);

        if (decodedImage == null) {
          throw Exception("Failed to decode image.");
        }

        // Resize to max 800px width (keep aspect ratio)
        img.Image resizedImage = img.copyResize(decodedImage, width: 800);

        // Compress further by lowering JPEG quality
        int quality = 50;
        Uint8List compressedBytes;
        String base64Image;

        do {
          compressedBytes = Uint8List.fromList(
            img.encodeJpg(resizedImage, quality: quality),
          );
          base64Image = base64Encode(compressedBytes);

          // Decode Base64 back to bytes to check size
          Uint8List decodedBytes = base64Decode(base64Image);

          if (decodedBytes.lengthInBytes < 1048487) {
            break; // Image is small enough
          }

          quality -= 10; // Reduce quality further
        } while (quality > 20); // Avoid going too low

        // Final size check
        if (base64Decode(base64Image).lengthInBytes >= 1048487) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected image is too large even after compression. Please choose a smaller image.',
              ),
              backgroundColor: Colors.red[600],
            ),
          );
          return;
        }

        if (!kIsWeb) {
          setState(() {
            _selectedImage = File(pickedFile.path); // Convert XFile to File
            _imageBase64 = base64Image;
          });
        } else {
          setState(() {
            _selectedImage = null; // Web doesn’t support dart:io.File
            _imageBase64 = base64Image;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _saveStudent() async {
    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Force validation and check if form is valid
      if (!_formKey.currentState!.validate()) {
        // Show validation error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Please fill in all required fields correctly'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return; // Stop execution if validation fails
      }

      // Additional custom validation
      String? validationError = _performCustomValidation();
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(validationError)),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Prepare source data
      String? sourceData;
      if (_selectedSource != null) {
        if (_selectedSource == 'Other' &&
            _customSourceController.text.trim().isNotEmpty) {
          sourceData = 'Other: ${_customSourceController.text.trim()}';
        } else if (_selectedSource != 'Other') {
          sourceData = _selectedSource;
        }
      }

      // Save to Firestore
      await _studentsCollection.add({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'school':
            _schoolController.text.trim().isNotEmpty
                ? _schoolController.text.trim()
                : null,
        'grade': _gradeController.text.trim(),
        'contact1': _contact1Controller.text.trim(),
        'contact2': _contact2Controller.text.trim(),
        'address': _addressController.text.trim(),
        'classDay': _selectedDay,
        'classTime':
            _selectedTime != null
                ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                : null,
        'joinedDate':
            _joinedDate != null ? Timestamp.fromDate(_joinedDate!) : null,
        'studentImage': _imageBase64,
        'source': sourceData,
        'isVerified': false,
        'createdAt': Timestamp.now(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Student registered successfully!')),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to success page using GoRouter
      context.go('/register-success');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error saving student: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Custom validation method
  String? _performCustomValidation() {
    // Check if name is empty
    if (_nameController.text.trim().isEmpty) {
      return 'Student name is required';
    }

    // Check if age is valid
    if (_ageController.text.trim().isEmpty) {
      return 'Age is required';
    }

    int? age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 1 || age > 150) {
      return 'Please enter a valid age between 1 and 150';
    }

    // Check if grade is empty
    if (_gradeController.text.trim().isEmpty) {
      return 'Grade/Class is required';
    }

    // Check if primary contact is empty
    if (_contact1Controller.text.trim().isEmpty) {
      return 'Primary contact is required';
    }

    // Validate primary contact format
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(_contact1Controller.text.trim())) {
      return 'Please enter a valid primary contact number';
    }

    // Check if address is empty
    if (_addressController.text.trim().isEmpty) {
      return 'Address is required';
    }

    // Validate secondary contact if provided
    if (_contact2Controller.text.trim().isNotEmpty &&
        !RegExp(r'^\+?\d{10,15}$').hasMatch(_contact2Controller.text.trim())) {
      return 'Please enter a valid secondary contact number';
    }

    // Validate custom source if "Other" is selected
    if (_selectedSource == 'Other' &&
        _customSourceController.text.trim().isEmpty) {
      return 'Please specify the source when "Other" is selected';
    }

    return null; // No validation errors
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _joinedDate = pickedDate;
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isClassDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGold,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGold,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isClassDate) {
        _joinedDate = selectedDateTime;
      }
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGold,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _contact1Controller.removeListener(_validateContact1);
    _contact2Controller.removeListener(_validateContact2);

    // Dispose controllers
    _nameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _contact1Controller.dispose();
    _contact2Controller.dispose();
    _addressController.dispose();
    _customSourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isInitialLoading
              ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF3E0),
                      Color(0xFFFFE082),
                      Color(0xFFFFB700),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Academy Logo/Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              15,
                            ), // same radius for clipping image
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 60, // your desired size
                              height: 60,
                              fit:
                                  BoxFit
                                      .contain, // fill the container and crop if needed
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Academy Name
                      Text(
                        'BRIGHTSPEAK',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: deepBlue,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'ENGLISH ACADEMY',
                        style: TextStyle(
                          fontSize: 16,
                          color: deepBlue.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Loading Progress Circle
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),

                      // Loading Text
                      Text(
                        'Loading Registration Form...',
                        style: TextStyle(
                          fontSize: 16,
                          color: deepBlue.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Please wait a moment',
                        style: TextStyle(
                          fontSize: 12,
                          color: deepBlue.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF3E0),
                      Color(0xFFFFE082),
                      Color(0xFFFFB700),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Custom App Bar with Academy Branding
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BRIGHTSPEAK',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: deepBlue,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'ENGLISH ACADEMY',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: deepBlue.withOpacity(0.8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Form Content
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: ListView(
                              children: [
                                // Welcome Header
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [lightGold, primaryGold],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1,
                                        size: 48,
                                        color: deepBlue,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Student Registration',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: deepBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Join the Brightspeak family today',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: deepBlue.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Student Photo Section
                                _buildSectionHeader(
                                  'Student Photo',
                                  Icons.photo_camera,
                                ),
                                _buildImagePicker(),

                                const SizedBox(height: 24),

                                // Personal Information Section
                                _buildSectionHeader(
                                  'Personal Information',
                                  Icons.person,
                                ),
                                _buildTextField(
                                  _nameController,
                                  'Full Name',
                                  Icons.person_outline,
                                  isRequired: true,
                                ),
                                _buildTextField(
                                  _ageController,
                                  'Age',
                                  Icons.cake_outlined,
                                  isNumber: true,
                                  isRequired: true,
                                ),
                                _buildSchoolDropdown(),
                                _buildTextField(
                                  _gradeController,
                                  'Grade/Class',
                                  Icons.class_outlined,
                                  isRequired: true,
                                ),

                                const SizedBox(height: 24),

                                // Contact Information Section
                                _buildSectionHeader(
                                  'Contact Information',
                                  Icons.phone,
                                ),
                                _buildContactField(
                                  _contact1Controller,
                                  'Primary Contact',
                                  Icons.phone_outlined,
                                  _contact1ValidationMessage,
                                  _isContact1Valid,
                                  isRequired: true,
                                ),
                                _buildContactField(
                                  _contact2Controller,
                                  'Secondary Contact (Optional)',
                                  Icons.phone_android_outlined,
                                  _contact2ValidationMessage,
                                  _isContact2Valid,
                                  isRequired: false,
                                ),
                                _buildTextField(
                                  _addressController,
                                  'Address',
                                  Icons.location_on_outlined,
                                  isRequired: true,
                                ),

                                const SizedBox(height: 24),

                                // Source Section
                                _buildSectionHeader(
                                  'How did you hear about us?',
                                  Icons.info_outline,
                                ),
                                _buildSourceSelector(),

                                const SizedBox(height: 24),

                                // Schedule Section
                                _buildSectionHeader(
                                  'Class Schedule',
                                  Icons.schedule,
                                ),
                                _buildDaySelector(),
                                const SizedBox(height: 12),
                                _buildTimeSelector(),
                                const SizedBox(height: 12),
                                _buildDateSelector(
                                  context,
                                  'Joined Date (Optional)',
                                  _joinedDate,
                                  Icons.event,
                                  Colors.green,
                                ),

                                const SizedBox(height: 24),

                                // Copyright Footer
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.copyright,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'All rights reserved by BrightSpeak IT Team',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Save Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryGold, darkGold],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGold.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _saveStudent,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child:
                                        _isLoading
                                            ? const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            )
                                            : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.how_to_reg,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Register Student',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: _pickImage, // <-- Call your image picker
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade50,
              ),
              child:
                  _imageBase64 != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(
                          base64Decode(_imageBase64!), // decode base64 to bytes
                          fit: BoxFit.fitHeight,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Student Photo (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to select from gallery',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_library, size: 18),
                  label: Text(
                    _imageBase64 != null ? 'Change Photo' : 'Select Photo',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightGold,
                    foregroundColor: deepBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _imageBase64 = null;
                    });
                  },
                  icon: Icon(Icons.delete, size: 18),
                  label: Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey.shade50,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.campaign,
                          color: Colors.purple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Source (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                color: deepBlue.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedSource ?? 'How did you hear about us?',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _selectedSource == null
                                        ? Colors.grey.shade600
                                        : deepBlue,
                                fontWeight:
                                    _selectedSource == null
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _sources.map((source) {
                          final isSelected = _selectedSource == source;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSource = isSelected ? null : source;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryGold : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? primaryGold
                                          : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                source,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : deepBlue,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedSource == 'Other') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customSourceController,
              decoration: InputDecoration(
                labelText: 'Please specify',
                prefixIcon: Icon(Icons.edit, color: primaryGold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: primaryGold, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                labelStyle: TextStyle(color: deepBlue.withOpacity(0.8)),
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (_selectedSource == 'Other' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please specify the source';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    final currentValue =
        _schoolOptions.contains(_schoolController.text)
            ? _schoolController.text
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Current School (Optional)',
          prefixIcon: Icon(Icons.school_outlined, color: primaryGold),
          suffixIcon:
              _isSchoolLoading
                  ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryGold,
                      ),
                    ),
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: primaryGold, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(color: deepBlue.withOpacity(0.8)),
        ),
        hint: Text(
          _isSchoolLoading
              ? 'Loading schools...'
              : 'Select a school or add a new one',
        ),
        items: [
          ..._schoolOptions.map(
            (school) => DropdownMenuItem<String>(
              value: school,
              child: Text(school),
            ),
          ),
          DropdownMenuItem<String>(
            value: _addNewSchoolValue,
            child: Row(
              children: const [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Add new school'),
              ],
            ),
          ),
        ],
        onChanged:
            _isSchoolLoading
                ? null
                : (value) async {
                  if (value == null) {
                    setState(() => _schoolController.clear());
                  } else if (value == _addNewSchoolValue) {
                    await _promptAddSchool();
                  } else {
                    setState(() => _schoolController.text = value);
                  }
                },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: deepBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: deepBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryGold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: primaryGold, width: 2),
          ),
          // Add error border styling
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(color: deepBlue.withOpacity(0.8)),
          // Ensure error text is visible
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          // Add some padding for error text
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            if (!label.contains('Optional')) {
              return 'Please enter $label';
            }
            return null;
          }
          if (isNumber && label.contains('Contact')) {
            if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value.trim())) {
              return 'Please enter a valid phone number';
            }
          }
          if (isNumber && label == 'Age') {
            int? age = int.tryParse(value.trim());
            if (age == null || age < 1 || age > 150) {
              return 'Please enter a valid age';
            }
          }
          if (label == 'Full Name') {
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
              return 'Name should contain only letters and spaces';
            }
          }
          if (label == 'Address' && value.trim().length < 5) {
            return 'Address must be at least 5 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildContactField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? validationMessage,
    bool isValid, {
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: primaryGold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      validationMessage != null && !isValid
                          ? Colors.red
                          : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      validationMessage != null && !isValid
                          ? Colors.red
                          : primaryGold,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              labelStyle: TextStyle(color: deepBlue.withOpacity(0.8)),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'Please enter $label';
              }
              if (value != null && value.trim().isNotEmpty) {
                if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value.trim())) {
                  return 'Please enter a valid phone number';
                }
              }
              return null;
            },
          ),
          // Live validation message
          if (validationMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValid ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color:
                        isValid ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      validationMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isValid
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade50,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Day (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: deepBlue.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDay ?? 'Select day of the week',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _selectedDay == null
                                  ? Colors.grey.shade600
                                  : deepBlue,
                          fontWeight:
                              _selectedDay == null
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _daysOfWeek.map((day) {
                    final isSelected = _selectedDay == day;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = isSelected ? null : day;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryGold : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? primaryGold : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: isSelected ? Colors.white : deepBlue,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade50,
      ),
      child: InkWell(
        onTap: () => _selectTime(context),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.access_time, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class Time (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: deepBlue.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTime == null
                          ? 'Tap to select time'
                          : _selectedTime!.format(context),
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _selectedTime == null
                                ? Colors.grey.shade600
                                : deepBlue,
                        fontWeight:
                            _selectedTime == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector(
    BuildContext context,
    String label,
    DateTime? selectedDateTime,
    bool isClassDate,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade50,
      ),
      child: InkWell(
        onTap: () => _selectDateTime(context, isClassDate),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: deepBlue.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDateTime == null
                          ? 'Tap to select'
                          : '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} at ${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            selectedDateTime == null
                                ? Colors.grey.shade600
                                : deepBlue,
                        fontWeight:
                            selectedDateTime == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade50,
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: deepBlue.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDate == null
                          ? 'Tap to select'
                          : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            selectedDate == null
                                ? Colors.grey.shade600
                                : deepBlue,
                        fontWeight:
                            selectedDate == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
