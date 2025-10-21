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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade800,
            Colors.indigo.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 15,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 55,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Name
            Text(
              _fullName.isNotEmpty ? _fullName : _username,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            
            // Position
            Text(
              _position.isNotEmpty ? _position : 'Staff',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            
            // Department/Team info
            if (_department.isNotEmpty || _team.isNotEmpty)
              Text(
                '${_department.isNotEmpty ? _department : ''}${_department.isNotEmpty && _team.isNotEmpty ? ' • ' : ''}${_team.isNotEmpty ? _team : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 12),
            
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _status == 'Aktif' 
                    ? Colors.green.shade400.withOpacity(0.9)
                    : Colors.orange.shade400.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _status == 'Aktif' ? Icons.check_circle : Icons.schedule,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
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
            _buildInteractiveInfoRow('Email', _email, 'Tambahkan email', Icons.email_outlined),
            _buildInteractiveInfoRow('Nomor Telepon', _phoneNumber, 'Tambahkan nomor telepon', Icons.phone_outlined),
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
            _buildInteractiveInfoRow('ID Karyawan', _employeeId, 'ID karyawan belum tersedia', Icons.badge_outlined),
            _buildInteractiveInfoRow('Departemen', _department, 'Departemen belum diisi', Icons.business_outlined),
            _buildInteractiveInfoRow('Posisi', _position, 'Posisi belum diisi', Icons.work_outlined),
            _buildInteractiveInfoRow('Team', _team, 'Team belum diisi', Icons.group_outlined),
            _buildInteractiveInfoRow('Tanggal Bergabung', _joinDate, 'Tanggal bergabung belum tersedia', Icons.calendar_today_outlined),
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
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
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

  Widget _buildInteractiveInfoRow(String label, String value, String emptyLabel, IconData icon) {
    final isEmpty = value.isEmpty || value == '-';
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
            child: isEmpty
                ? GestureDetector(
                    onTap: () => _showAddDataDialog(label, icon),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              emptyLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.add_circle_outline,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
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

  void _showAddDataDialog(String fieldName, IconData icon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text('Tambah $fieldName'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: fieldName,
                  hintText: 'Masukkan $fieldName',
                ),
                controller: TextEditingController(),
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
                  SnackBar(content: Text('Fitur tambah $fieldName akan segera tersedia')),
                );
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
