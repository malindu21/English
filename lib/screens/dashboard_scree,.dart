import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:typed_data';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CollectionReference _studentsCollection = FirebaseFirestore.instance
      .collection('students');
  final CollectionReference _schoolsCollection = FirebaseFirestore.instance
      .collection('schools');
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  String _searchQuery = '';
  String? _selectedSchool;
  String? _selectedAge;
  String? _selectedGrade;
  bool _isLoading = false;

  List<String> _schools = ['All'];
  List<String> _ages = ['All'];
  List<String> _grades = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchDropdownOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownOptions() async {
    try {
      setState(() => _isLoading = true);
      final snapshot = await _studentsCollection.get();
      final Set<String> schools = {'All'};
      final Set<String> ages = {'All'};
      final Set<String> grades = {'All'};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['school'] != null) schools.add(data['school'].toString());
        if (data['age'] != null) ages.add(data['age'].toString());
        if (data['grade'] != null) grades.add(data['grade'].toString());
      }

      setState(() {
        _schools = schools.toList()..sort();
        _ages =
            ages.toList()..sort(
              (a, b) => int.parse(
                a == 'All' ? '0' : a,
              ).compareTo(int.parse(b == 'All' ? '0' : b)),
            );
        _grades = grades.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar(
        'Error fetching filter options: $e',
        Colors.red,
        Icons.error,
      );
    }
  }

  Future<void> _showEditSchoolDialog() async {
    if (_selectedSchool == null || _selectedSchool == 'All') {
      _showSnackBar(
        'Please select a school to edit',
        Colors.orange,
        Icons.info,
      );
      return;
    }

    final controller = TextEditingController(text: _selectedSchool);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit School Name'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New school name',
                hintText: 'Enter new name',
              ),
              autofocus: true,
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

    if (newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == _selectedSchool) {
      if (trimmed.isEmpty) {
        _showSnackBar(
          'School name cannot be empty',
          Colors.red,
          Icons.error,
        );
      }
      return;
    }

    await _updateSchoolName(trimmed);
  }

  Future<void> _updateSchoolName(String newName) async {
    final previousName = _selectedSchool;
    if (previousName == null || previousName == 'All') return;

    try {
      setState(() => _isLoading = true);
      final query =
          await _studentsCollection.where('school', isEqualTo: previousName)
              .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'school': newName});
      }
      await batch.commit();
      setState(() => _selectedSchool = newName);

      await _fetchDropdownOptions();

      _showSnackBar(
        'School name updated',
        Colors.green,
        Icons.check_circle,
      );
    } catch (e) {
      _showSnackBar('Error updating school name: $e', Colors.red, Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncSchoolsFromStudents() async {
    try {
      setState(() => _isLoading = true);

      final studentsSnapshot = await _studentsCollection.get();
      final schoolNames =
          studentsSnapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['school']
                        ?.toString()
                        .trim(),
              )
              .whereType<String>()
              .where((name) => name.isNotEmpty && name != 'All')
              .toSet();

      final existingSnapshot =
          await _schoolsCollection.orderBy('name', descending: false).get();
      final existingLower =
          existingSnapshot.docs
              .map(
                (doc) =>
                    ((doc.data() as Map<String, dynamic>)['name']
                        ?.toString()
                        .trim() ??
                    '')
                        .toLowerCase(),
              )
              .toSet();

      final newSchools =
          schoolNames
              .where((name) => !existingLower.contains(name.toLowerCase()))
              .toList();

      for (final name in newSchools) {
        await _schoolsCollection.add({
          'name': name,
          'createdAt': Timestamp.now(),
        });
      }

      await _fetchDropdownOptions();
      _showSnackBar(
        newSchools.isEmpty
            ? 'Schools are already synced'
            : 'Added ${newSchools.length} new school(s)',
        Colors.green,
        Icons.sync,
      );
    } catch (e) {
      _showSnackBar('Error syncing schools: $e', Colors.red, Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Stream<int> _getVerifiedStudentsCount() {
    return _studentsCollection
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getUnverifiedStudentsCount() {
    return _studentsCollection
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<QuerySnapshot> _getAllStudents() {
    return _studentsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterStudents(
    List<QueryDocumentSnapshot> docs,
  ) {
    List<QueryDocumentSnapshot> filteredDocs = docs;

    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filteredDocs =
          filteredDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['name']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['school']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['grade']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['contact1']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['contact2']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['address']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['classDay']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['source']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false);
          }).toList();
    }

    if (_selectedSchool != null && _selectedSchool != 'All') {
      filteredDocs =
          filteredDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['school']
                        ?.toString() ==
                    _selectedSchool,
              )
              .toList();
    }

    if (_selectedAge != null && _selectedAge != 'All') {
      filteredDocs =
          filteredDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['age']?.toString() ==
                    _selectedAge,
              )
              .toList();
    }

    if (_selectedGrade != null && _selectedGrade != 'All') {
      filteredDocs =
          filteredDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['grade']?.toString() ==
                    _selectedGrade,
              )
              .toList();
    }

    return filteredDocs;
  }

  Future<void> _verifyStudent(String studentId) async {
    try {
      setState(() => _isLoading = true);
      await _studentsCollection.doc(studentId).update({
        'isVerified': true,
        'verifiedAt': Timestamp.now(),
      });
      _showSnackBar(
        'Student verified successfully!',
        Colors.green,
        Icons.check_circle,
      );
    } catch (e) {
      _showSnackBar('Error verifying student: $e', Colors.red, Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStudent(String studentId, String studentName) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete "$studentName"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmDelete == true) {
      try {
        setState(() => _isLoading = true);
        await _studentsCollection.doc(studentId).delete();
        _showSnackBar(
          'Student deleted successfully!',
          Colors.red,
          Icons.delete,
        );
      } catch (e) {
        _showSnackBar('Error deleting student: $e', Colors.red, Icons.error);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(color: Colors.blue[800]!, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(57),
                        child:
                            data['studentImage'] != null
                                ? Image.memory(
                                  base64Decode(data['studentImage']),
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  color: Colors.blue[100],
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.blue[800],
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Age', '${data['age'] ?? 'N/A'}'),
                        _buildDetailRow('School', data['school'] ?? 'N/A'),
                        _buildDetailRow('Grade', data['grade'] ?? 'N/A'),
                        _buildDetailRow('Contact 1', data['contact1'] ?? 'N/A'),
                        if (data['contact2'] != null &&
                            data['contact2'].toString().isNotEmpty)
                          _buildDetailRow('Contact 2', data['contact2']),
                        _buildDetailRow('Address', data['address'] ?? 'N/A'),
                        if (data['classDay'] != null)
                          _buildDetailRow('Class Day', data['classDay']),
                        if (data['classTime'] != null)
                          _buildDetailRow('Class Time', data['classTime']),
                        if (data['source'] != null)
                          _buildDetailRow('Source', data['source']),
                        if (data['joinedDate'] != null)
                          _buildDetailRow(
                            'Joined Date',
                            (data['joinedDate'] as Timestamp)
                                .toDate()
                                .toString()
                                .split(' ')[0],
                          ),
                        _buildDetailRow(
                          'Status',
                          (data['isVerified'] ?? false)
                              ? 'Verified'
                              : 'Pending',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  Widget _buildStudentList(List<QueryDocumentSnapshot> docs, bool isVerified) {
    final filteredDocs =
        docs
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['isVerified'] ==
                  isVerified,
            )
            .toList();

    if (filteredDocs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          isVerified ? 'No verified students' : 'No unverified students',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;

        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isVerified ? Colors.blue[800]! : Colors.orange[600]!,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => _showStudentDetails(context, data),
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            isVerified ? Colors.blue[800] : Colors.orange[600],
                        backgroundImage:
                            data['studentImage'] != null
                                ? MemoryImage(
                                  base64Decode(data['studentImage']),
                                )
                                : null,
                        child:
                            data['studentImage'] == null
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                )
                                : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isVerified ? Icons.verified : Icons.pending,
                            color:
                                isVerified
                                    ? Colors.blue[800]
                                    : Colors.orange[600],
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    data['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'School: ${data['school'] ?? 'N/A'}, Grade: ${data['grade'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isVerified)
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: Colors.blue[800],
                          ),
                          onPressed: () => _verifyStudent(doc.id),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[600]),
                        onPressed:
                            () => _deleteStudent(
                              doc.id,
                              data['name'] ?? 'Unknown',
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainScreen(List<QueryDocumentSnapshot> filteredDocs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.blue[800],
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<int>(
                        stream: _getVerifiedStudentsCount(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              '${snapshot.data} Verified Students',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            );
                          }
                          return const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students by name, school, grade, contact...',
                prefixIcon: Icon(Icons.search, color: Colors.blue[800]),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter Dropdowns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSchool,
                            decoration: InputDecoration(
                              labelText: 'School',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue[800]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue[200]!),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                _schools
                                    .map(
                                      (school) => DropdownMenuItem<String>(
                                        value: school,
                                        child: Text(school),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) => setState(() => _selectedSchool = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Edit selected school name',
                          icon: Icon(Icons.edit, color: Colors.blue[800]),
                          onPressed:
                              _isLoading ? null : () => _showEditSchoolDialog(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Schools'),
                        onPressed:
                            _isLoading ? null : () => _syncSchoolsFromStudents(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedAge,
                            decoration: InputDecoration(
                              labelText: 'Age',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue[800]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue[200]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                _ages
                                    .map(
                                      (age) => DropdownMenuItem<String>(
                                        value: age,
                                        child: Text(age),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) => setState(() => _selectedAge = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGrade,
                            decoration: InputDecoration(
                              labelText: 'Grade',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue[800]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue[200]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                _grades
                                    .map(
                                      (grade) => DropdownMenuItem<String>(
                                        value: grade,
                                        child: Text(grade),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) =>
                                    setState(() => _selectedGrade = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedSchool = null;
                            _selectedAge = null;
                            _selectedGrade = null;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        child: Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Verified Students List
          StreamBuilder<QuerySnapshot>(
            stream: _getAllStudents(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data!.docs;
              final filteredDocs = _filterStudents(allDocs);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Verified Students',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  _buildStudentList(filteredDocs, true),
                  const SizedBox(height: 80), // Space for FAB
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SafeArea(
            child:
                _selectedIndex == 0
                    ? _buildMainScreen([])
                    : UnverifiedStudentsScreen(
                      studentsCollection: _studentsCollection,
                      searchQuery: _searchQuery,
                      selectedSchool: _selectedSchool,
                      selectedAge: _selectedAge,
                      selectedGrade: _selectedGrade,
                      onVerify: _verifyStudent,
                      onDelete: _deleteStudent,
                      onShowDetails: _showStudentDetails,
                      onSnackBar: _showSnackBar,
                    ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Verified',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.pending),
                StreamBuilder<int>(
                  stream: _getUnverifiedStudentsCount(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data! > 0) {
                      return Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${snapshot.data}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            label: 'Unverified',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/register'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: 'Add New Student',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

Widget _buildLoadingOverlay() {
  return AbsorbPointer(
    absorbing: true,
    child: Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please wait...',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class UnverifiedStudentsScreen extends StatelessWidget {
  final CollectionReference studentsCollection;
  final String searchQuery;
  final String? selectedSchool;
  final String? selectedAge;
  final String? selectedGrade;
  final Function(String) onVerify;
  final Function(String, String) onDelete;
  final Function(BuildContext, Map<String, dynamic>) onShowDetails;
  final Function(String, Color, IconData) onSnackBar;

  const UnverifiedStudentsScreen({
    super.key,
    required this.studentsCollection,
    required this.searchQuery,
    this.selectedSchool,
    this.selectedAge,
    this.selectedGrade,
    required this.onVerify,
    required this.onDelete,
    required this.onShowDetails,
    required this.onSnackBar,
  });

  List<QueryDocumentSnapshot> _filterStudents(
    List<QueryDocumentSnapshot> docs,
  ) {
    List<QueryDocumentSnapshot> filteredDocs = docs;

    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      filteredDocs =
          filteredDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['name']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['school']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['grade']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['contact1']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['contact2']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['address']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['classDay']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false) ||
                (data['source']?.toString().toLowerCase().contains(
                      searchLower,
                    ) ??
                    false);
          }).toList();
    }

    if (selectedSchool != null && selectedSchool != 'All') {
      filteredDocs =
          filteredDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['school']
                        ?.toString() ==
                    selectedSchool,
              )
              .toList();
    }

    if (selectedAge != null && selectedAge != 'All') {
      filteredDocs =
          filteredDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['age']?.toString() ==
                    selectedAge,
              )
              .toList();
    }

    if (selectedGrade != null && selectedGrade != 'All') {
      filteredDocs =
          filteredDocs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['grade']?.toString() ==
                    selectedGrade,
              )
              .toList();
    }

    return filteredDocs;
  }

  Widget _buildStudentList(List<QueryDocumentSnapshot> docs) {
    final filteredDocs =
        _filterStudents(docs)
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['isVerified'] == false,
            )
            .toList();

    if (filteredDocs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No unverified students',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;

        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[600]!, width: 2),
              ),
              child: InkWell(
                onTap: () => onShowDetails(context, data),
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.orange[600],
                        backgroundImage:
                            data['studentImage'] != null
                                ? MemoryImage(
                                  base64Decode(data['studentImage']),
                                )
                                : null,
                        child:
                            data['studentImage'] == null
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                )
                                : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.pending,
                            color: Colors.orange[600],
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    data['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'School: ${data['school'] ?? 'N/A'}, Grade: ${data['grade'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.blue[800]),
                        onPressed: () => onVerify(doc.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[600]),
                        onPressed:
                            () => onDelete(doc.id, data['name'] ?? 'Unknown'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Unverified Students',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                studentsCollection
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data!.docs;
              return _buildStudentList(allDocs);
            },
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
}
