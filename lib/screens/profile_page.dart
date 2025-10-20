import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/attendance_service.dart';
import '../utils/user_data.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/page_transition.dart';
import 'attendance_history_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = '';
  String _staffLabel = '';
  bool _isLoadingStaff = false;
  String? _staffError;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchStaffLabel();
  }
  
  Future<void> _loadUserData() async {
    await UserData.loadUserData();
    if (mounted) {
    setState(() {
        _username = UserData.username;
    });
    }
  }
  
  Future<void> _fetchStaffLabel() async {
    try {
      setState(() {
        _isLoadingStaff = true;
        _staffError = null;
      });

      final token = await UserData.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final uri = Uri.parse('${AttendanceService.baseUrl}/staff');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: AttendanceService.timeoutDuration));

      if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _staffLabel = 'Data staff tidak ditemukan';
          });
        }
        return;
      } else if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final dynamic decoded = json.decode(response.body);

      String label;
      if (decoded is Map<String, dynamic>) {
        // If wrapped response
        final success = decoded['success'];
        final data = decoded.containsKey('data') ? decoded['data'] : decoded;
        if (success == false) {
          label = decoded['message']?.toString() ?? 'Gagal memuat data';
        } else {
          if (data is List) {
            if (data.isNotEmpty && data.first is Map<String, dynamic>) {
              final first = data.first as Map<String, dynamic>;
              final team = (first['team'] ?? '-').toString();
              final position = (first['position'] ?? '-').toString();
              label = 'Team: $team • Posisi: $position';
            } else {
              label = 'Jumlah staff: ${data.length}';
            }
          } else if (data is Map<String, dynamic>) {
            if (data.containsKey('label')) {
              label = data['label'].toString();
            } else if (data.containsKey('message')) {
              label = data['message'].toString();
            } else {
              final team = (data['team'] ?? '-').toString();
              final position = (data['position'] ?? '-').toString();
              if (team != '-' || position != '-') {
                label = 'Team: $team • Posisi: $position';
              } else {
                label = 'Data staff tersedia';
              }
            }
          } else {
            label = 'Data staff tersedia';
          }
        }
      } else if (decoded is List) {
        if (decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          final first = decoded.first as Map<String, dynamic>;
          final team = (first['team'] ?? '-').toString();
          final position = (first['position'] ?? '-').toString();
          label = 'Team: $team • Posisi: $position';
        } else {
          label = 'Jumlah staff: ${decoded.length}';
        }
      } else {
        label = decoded.toString();
      }

      if (mounted) {
        setState(() {
          _staffLabel = label;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _staffError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStaff = false;
        });
      }
    }
  }
  
  void _onNavItemTapped(int index) {
    if (index == 2) return;
    
    final routes = {
      0: '/form',
      1: '/home',
    };
    
    if (routes.containsKey(index)) {
      navigateWithAnimation(context, routes[index]!);
    }
  }
  
  Future<void> _logout() async {
    await UserData.clearUserData();
    if (mounted) {
    Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceHistoryPage(),
      ),
    );
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: _onNavItemTapped,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        title: Text(
          'Profil Pengguna',
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
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight - 
                          kBottomNavigationBarHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                  _buildProfileHeader(),
                  SizedBox(height: 24),
                  _buildInfoCard(),
                  SizedBox(height: 32),
                  _buildLogoutButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
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
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
          _username,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_isLoadingStaff)
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_staffError != null)
                      Text(
                        _staffError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      )
                    else if (_staffLabel.isNotEmpty)
                      Text(
                        _staffLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                        ),
                      ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
            _buildInfoTile(
              icon: Icons.person_outline,
              title: 'Informasi Pengguna',
              subtitle: 'Detail akun dan profil',
                              onTap: () {
                // TODO: Implementasi untuk melihat detail profil
                              },
                            ),
                            Divider(),
            _buildInfoTile(
              icon: Icons.history,
              title: 'Riwayat Presensi',
              subtitle: 'Lihat riwayat kehadiran Anda',
                              onTap: _showAttendanceHistory,
                            ),
                            Divider(),
            _buildInfoTile(
              icon: Icons.settings,
              title: 'Pengaturan',
              subtitle: 'Ubah pengaturan aplikasi',
              onTap: _showSettings,
            ),
                          ],
                        ),
                      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout),
                      label: Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
      ),
    );
  }
}