import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/attendance_service.dart';
import '../utils/user_data.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({Key? key}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  String _username = '';
  String _email = '';
  String _fullName = '';
  String _employeeId = '';
  String _department = '';
  String _position = '';
  String _team = '';
  String _phoneNumber = '';
  String _joinDate = '';
  String _status = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserDetails();
  }

  Future<void> _loadUserData() async {
    await UserData.loadUserData();
    if (mounted) {
      setState(() {
        _username = UserData.username;
        _email = ''; // Email will be fetched from API
      });
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await UserData.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      // Fetch staff details
      final staffUri = Uri.parse('${AttendanceService.baseUrl}/staff');
      final staffResponse = await http.get(
        staffUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: AttendanceService.timeoutDuration));

      if (staffResponse.statusCode == 200) {
        final staffData = json.decode(staffResponse.body);
        _parseStaffData(staffData);
      }

      // Fetch user profile details
      final profileUri = Uri.parse('${AttendanceService.baseUrl}/profile');
      final profileResponse = await http.get(
        profileUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: AttendanceService.timeoutDuration));

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        _parseProfileData(profileData);
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _parseStaffData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final success = data['success'];
      final staffData = data.containsKey('data') ? data['data'] : data;
      
      if (success == true && staffData is List && staffData.isNotEmpty) {
        final firstStaff = staffData.first as Map<String, dynamic>;
        setState(() {
          _employeeId = firstStaff['employee_id']?.toString() ?? '-';
          _department = firstStaff['department']?.toString() ?? '-';
          _position = firstStaff['position']?.toString() ?? '-';
          _team = firstStaff['team']?.toString() ?? '-';
          _joinDate = firstStaff['join_date']?.toString() ?? '-';
          _status = firstStaff['status']?.toString() ?? 'Aktif';
        });
      }
    } else if (data is List && data.isNotEmpty) {
      final firstStaff = data.first as Map<String, dynamic>;
      setState(() {
        _employeeId = firstStaff['employee_id']?.toString() ?? '-';
        _department = firstStaff['department']?.toString() ?? '-';
        _position = firstStaff['position']?.toString() ?? '-';
        _team = firstStaff['team']?.toString() ?? '-';
        _joinDate = firstStaff['join_date']?.toString() ?? '-';
        _status = firstStaff['status']?.toString() ?? 'Aktif';
      });
    }
  }

  void _parseProfileData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final success = data['success'];
      final profileData = data.containsKey('data') ? data['data'] : data;
      
      if (success == true && profileData is Map<String, dynamic>) {
        setState(() {
          _fullName = profileData['full_name']?.toString() ?? _username;
          _phoneNumber = profileData['phone_number']?.toString() ?? '-';
          _email = profileData['email']?.toString() ?? _email;
        });
      }
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: _fullName,
                ),
                controller: TextEditingController(text: _fullName),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: _phoneNumber,
                ),
                controller: TextEditingController(text: _phoneNumber),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fitur edit profil akan segera tersedia')),
                );
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ubah Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Lama',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fitur ubah password akan segera tersedia')),
                );
              },
              child: Text('Ubah'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Informasi Pengguna',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue.shade600),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.shade50,
              Colors.white,
            ],
            stops: [0.0, 0.2, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            _buildProfileHeader(),
                            SizedBox(height: 24),
                            _buildPersonalInfoCard(),
                            SizedBox(height: 16),
                            _buildWorkInfoCard(),
                            SizedBox(height: 16),
                            _buildAccountInfoCard(),
                            SizedBox(height: 16),
                            _buildActionButtons(),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchUserDetails,
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue.shade600,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _fullName.isNotEmpty ? _fullName : _username,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _position.isNotEmpty ? _position : 'Staff',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey.shade600,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _status == 'Aktif' ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _status == 'Aktif' ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue.shade600),
                SizedBox(width: 8),
                Text(
                  'Informasi Pribadi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Nama Lengkap', _fullName.isNotEmpty ? _fullName : _username),
            _buildInfoRow('Username', _username),
            _buildInfoRow('Email', _email.isNotEmpty ? _email : '-'),
            _buildInfoRow('Nomor Telepon', _phoneNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outline, color: Colors.blue.shade600),
                SizedBox(width: 8),
                Text(
                  'Informasi Pekerjaan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('ID Karyawan', _employeeId),
            _buildInfoRow('Departemen', _department),
            _buildInfoRow('Posisi', _position),
            _buildInfoRow('Team', _team),
            _buildInfoRow('Tanggal Bergabung', _joinDate),
            _buildInfoRow('Status', _status),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle_outlined, color: Colors.blue.shade600),
                SizedBox(width: 8),
                Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Tanggal Dibuat', '2024-01-01'),
            _buildInfoRow('Terakhir Login', 'Hari ini'),
            _buildInfoRow('Tipe Akun', 'Staff'),
            _buildInfoRow('Verifikasi Email', _email.isNotEmpty ? 'Terverifikasi' : 'Belum Terverifikasi'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: Colors.blue.shade600),
                SizedBox(width: 8),
                Text(
                  'Aksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: Icon(Icons.edit),
                label: Text('Edit Profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: Icon(Icons.lock_outline),
                label: Text('Ubah Password'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  side: BorderSide(color: Colors.blue.shade600),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
