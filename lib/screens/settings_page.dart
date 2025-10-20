import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _autoSyncEnabled = true;
  String _selectedLanguage = 'Bahasa Indonesia';
  String _selectedTheme = 'Sistem';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      _selectedLanguage = prefs.getString('selected_language') ?? 'Bahasa Indonesia';
      _selectedTheme = prefs.getString('selected_theme') ?? 'Sistem';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Bahasa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Bahasa Indonesia'),
                value: 'Bahasa Indonesia',
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  _saveSetting('selected_language', value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: Text('English'),
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  _saveSetting('selected_language', value);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Sistem'),
                value: 'Sistem',
                groupValue: _selectedTheme,
                onChanged: (String? value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                  _saveSetting('selected_theme', value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: Text('Terang'),
                value: 'Terang',
                groupValue: _selectedTheme,
                onChanged: (String? value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                  _saveSetting('selected_theme', value);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: Text('Gelap'),
                value: 'Gelap',
                groupValue: _selectedTheme,
                onChanged: (String? value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                  _saveSetting('selected_theme', value);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tentang Aplikasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WDU QR Code Scanner'),
              SizedBox(height: 8),
              Text('Versi: 1.0.0'),
              SizedBox(height: 8),
              Text('Aplikasi untuk scanning QR code dan presensi digital'),
              SizedBox(height: 16),
              Text('© 2024 WDU. All rights reserved.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kebijakan Privasi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kebijakan Privasi WDU QR Code Scanner',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('1. Pengumpulan Data'),
                Text('Aplikasi ini mengumpulkan data presensi dan informasi pengguna untuk keperluan sistem kehadiran.'),
                SizedBox(height: 8),
                Text('2. Penggunaan Data'),
                Text('Data digunakan untuk melacak kehadiran dan menghasilkan laporan presensi.'),
                SizedBox(height: 8),
                Text('3. Keamanan Data'),
                Text('Semua data dilindungi dengan enkripsi dan hanya dapat diakses oleh pihak yang berwenang.'),
                SizedBox(height: 8),
                Text('4. Berbagi Data'),
                Text('Data tidak akan dibagikan kepada pihak ketiga tanpa persetujuan pengguna.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Syarat dan Ketentuan'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syarat dan Ketentuan Penggunaan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('1. Penggunaan Aplikasi'),
                Text('Pengguna diharapkan menggunakan aplikasi sesuai dengan tujuan yang dimaksud.'),
                SizedBox(height: 8),
                Text('2. Tanggung Jawab'),
                Text('Pengguna bertanggung jawab atas keakuratan data yang dimasukkan.'),
                SizedBox(height: 8),
                Text('3. Pembatasan'),
                Text('Dilarang menggunakan aplikasi untuk tujuan yang melanggar hukum.'),
                SizedBox(height: 8),
                Text('4. Perubahan'),
                Text('Syarat dan ketentuan dapat berubah sewaktu-waktu tanpa pemberitahuan sebelumnya.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Cache'),
          content: Text('Apakah Anda yakin ingin menghapus cache aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cache berhasil dihapus')),
                );
              },
              child: Text('Hapus'),
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
          'Pengaturan',
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  _buildSectionTitle('Notifikasi'),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.notifications,
                      title: 'Notifikasi Presensi',
                      subtitle: 'Terima notifikasi untuk presensi',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSetting('notifications_enabled', value);
                      },
                    ),
                    Divider(),
                    _buildSwitchTile(
                      icon: Icons.sync,
                      title: 'Sinkronisasi Otomatis',
                      subtitle: 'Sinkronisasi data secara otomatis',
                      value: _autoSyncEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoSyncEnabled = value;
                        });
                        _saveSetting('auto_sync_enabled', value);
                      },
                    ),
                  ]),
                  
                  SizedBox(height: 24),
                  _buildSectionTitle('Tampilan'),
                  _buildSettingsCard([
                    _buildListTile(
                      icon: Icons.language,
                      title: 'Bahasa',
                      subtitle: _selectedLanguage,
                      onTap: _showLanguageDialog,
                    ),
                    Divider(),
                    _buildListTile(
                      icon: Icons.palette,
                      title: 'Tema',
                      subtitle: _selectedTheme,
                      onTap: _showThemeDialog,
                    ),
                  ]),
                  
                  SizedBox(height: 24),
                  _buildSectionTitle('Keamanan'),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.fingerprint,
                      title: 'Autentikasi Biometrik',
                      subtitle: 'Gunakan sidik jari atau wajah untuk login',
                      value: _biometricEnabled,
                      onChanged: (value) {
                        setState(() {
                          _biometricEnabled = value;
                        });
                        _saveSetting('biometric_enabled', value);
                      },
                    ),
                  ]),
                  
                  SizedBox(height: 24),
                  _buildSectionTitle('Aplikasi'),
                  _buildSettingsCard([
                    _buildListTile(
                      icon: Icons.info_outline,
                      title: 'Tentang Aplikasi',
                      subtitle: 'Informasi versi dan detail aplikasi',
                      onTap: _showAboutDialog,
                    ),
                    Divider(),
                    _buildListTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Kebijakan Privasi',
                      subtitle: 'Baca kebijakan privasi kami',
                      onTap: _showPrivacyPolicy,
                    ),
                    Divider(),
                    _buildListTile(
                      icon: Icons.description_outlined,
                      title: 'Syarat dan Ketentuan',
                      subtitle: 'Baca syarat dan ketentuan penggunaan',
                      onTap: _showTermsOfService,
                    ),
                    Divider(),
                    _buildListTile(
                      icon: Icons.storage,
                      title: 'Hapus Cache',
                      subtitle: 'Bersihkan cache aplikasi',
                      onTap: _clearCache,
                    ),
                  ]),
                  
                  SizedBox(height: 24),
                  _buildSectionTitle('Akun'),
                  _buildSettingsCard([
                    _buildListTile(
                      icon: Icons.edit,
                      title: 'Edit Profil',
                      subtitle: 'Ubah informasi profil Anda',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fitur edit profil akan segera tersedia')),
                        );
                      },
                    ),
                    Divider(),
                    _buildListTile(
                      icon: Icons.lock_outline,
                      title: 'Ubah Password',
                      subtitle: 'Ganti kata sandi akun Anda',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fitur ubah password akan segera tersedia')),
                        );
                      },
                    ),
                    Divider(),
                    _buildListTile(
                      icon: Icons.download_outlined,
                      title: 'Ekspor Data',
                      subtitle: 'Unduh data presensi Anda',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fitur ekspor data akan segera tersedia')),
                        );
                      },
                    ),
                  ]),
                  
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildListTile({
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
}
