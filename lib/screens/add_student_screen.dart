import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final CollectionReference _studentsCollection = FirebaseFirestore.instance
      .collection('students');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _contact1Controller = TextEditingController();
  final TextEditingController _contact2Controller = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedDay;
  TimeOfDay? _selectedTime;
  DateTime? _joinedDate;

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

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _studentsCollection.add({
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'school': _schoolController.text.trim(),
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
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Student enrolled successfully!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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
        // This is now only for joined date
        _joinedDate = selectedDateTime;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _contact1Controller.dispose();
    _contact2Controller.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE082), Color(0xFFFFB700)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Academy Branding
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Row(
                  children: [
                    // IconButton(
                    //   onPressed: () => Navigator.pop(context),
                    //   icon: const Icon(Icons.arrow_back_ios),
                    //   color: deepBlue,
                    // ),
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
                      child: Icon(Icons.school, color: deepBlue, size: 28),
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
                                'Student Enrollment',
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

                        // Personal Information Section
                        _buildSectionHeader(
                          'Personal Information',
                          Icons.person,
                        ),
                        _buildTextField(
                          _nameController,
                          'Full Name',
                          Icons.person_outline,
                        ),
                        _buildTextField(
                          _ageController,
                          'Age',
                          Icons.cake_outlined,
                          isNumber: true,
                        ),
                        _buildTextField(
                          _schoolController,
                          'Current School',
                          Icons.school_outlined,
                        ),
                        _buildTextField(
                          _gradeController,
                          'Grade/Class',
                          Icons.class_outlined,
                        ),

                        const SizedBox(height: 24),

                        // Copyright Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade200),
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
                                'All rights reserved by BrightSpeak IT Team 2025',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Contact Information Section
                        _buildSectionHeader('Contact Information', Icons.phone),
                        _buildTextField(
                          _contact1Controller,
                          'Primary Contact',
                          Icons.phone_outlined,
                          isNumber: true,
                        ),
                        _buildTextField(
                          _contact2Controller,
                          'Secondary Contact (Optional)',
                          Icons.phone_android_outlined,
                          isNumber: true,
                        ),
                        _buildTextField(
                          _addressController,
                          'Address',
                          Icons.location_on_outlined,
                        ),

                        const SizedBox(height: 24),

                        // Schedule Section
                        _buildSectionHeader('Class Schedule', Icons.schedule),
                        _buildDaySelector(),
                        const SizedBox(height: 12),
                        _buildTimeSelector(),
                        const SizedBox(height: 12),
                        _buildDateTimeSelector(
                          context,
                          'Joined Date (Optional)',
                          _joinedDate,
                          false,
                          Icons.event,
                          Colors.green,
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
                            onPressed: _saveStudent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.how_to_reg,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Enroll Student',
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
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(color: deepBlue.withOpacity(0.8)),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            if (!label.contains('Optional')) {
              return 'Please enter $label';
            }
          }
          return null;
        },
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
                          : '${_selectedTime!.format(context)}',
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
}
