import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/page_transition.dart';
import '../utils/user_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CombinedFormPage extends StatefulWidget {
  @override
  _CombinedFormPageState createState() => _CombinedFormPageState();
}

class _CombinedFormPageState extends State<CombinedFormPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _showForm = false; // Untuk mengontrol tampilan form
  bool _showHistory = false; // Untuk mengontrol tampilan riwayat
  
  // Controller untuk semua form
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _tanggalBerakhirController = TextEditingController();
  final TextEditingController _alasanController = TextEditingController();
  
  // Variabel untuk menyimpan data form
  DateTime? _selectedDate;
  DateTime? _selectedEndDate;
  
  // Variabel untuk menentukan jenis form yang dipilih
  String _selectedFormType = 'izin'; // Default: izin

  // List untuk menyimpan riwayat pengajuan
  List<Map<String, dynamic>> _submissionHistory = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _tanggalBerakhirController.dispose();
    _alasanController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue.shade600,
            colorScheme: ColorScheme.light(primary: Colors.blue.shade600),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Fungsi untuk memilih tanggal berakhir (untuk cuti)
  Future<void> _selectEndDate(BuildContext context) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Pilih tanggal mulai terlebih dahulu'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedDate!,
      firstDate: _selectedDate!,
      lastDate: DateTime(_selectedDate!.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue.shade600,
            colorScheme: ColorScheme.light(primary: Colors.blue.shade600),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
        _tanggalBerakhirController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Fungsi untuk menghitung jumlah hari cuti
  int _hitungJumlahHari() {
    if (_selectedDate == null || _selectedEndDate == null) {
      return 0;
    }
    return _selectedEndDate!.difference(_selectedDate!).inDays + 1;
  }

  // Fungsi untuk submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Dapatkan token user untuk otorisasi
        String? userToken = await UserData.getToken();
        if (userToken == null) {
          throw Exception("Token user tidak ditemukan, silakan login ulang");
        }
        
        // Siapkan data yang akan dikirim sesuai dengan struktur PermissionController
        Map<String, dynamic> formData = {
          'tanggal': _tanggalController.text,
          'alasan': _alasanController.text,
        };
        
        // Tambahkan tanggal_berakhir jika form cuti
        if (_selectedFormType == 'cuti') {
          formData['tanggal_berakhir'] = _tanggalBerakhirController.text;
        }
        
        // Kirim data ke API dengan endpoint yang sesuai PermissionController
        final response = await http.post(
          Uri.parse('http://192.168.0.184:8000/api/permission/$_selectedFormType'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $userToken',
          },
          body: jsonEncode(formData),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse = jsonDecode(response.body);
          
          String successMessage = '';
          switch (_selectedFormType) {
            case 'izin':
              successMessage = 'Pengajuan izin berhasil dikirim!';
              break;
            case 'cuti':
              successMessage = 'Pengajuan cuti berhasil dikirim!';
              break;
            case 'lembur':
              successMessage = 'Pengajuan lembur berhasil dikirim!';
              break;
          }
          
          print('Response data: ${jsonResponse['message']}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(successMessage),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.all(10),
            ),
          );
          
          _resetForm();
        } else {
          final errorResponse = jsonDecode(response.body);
          String errorMessage = 'Gagal mengirim pengajuan';
          
          // Handle specific error untuk cuti jika melebihi jatah
          if (errorResponse['message'] != null) {
            errorMessage = errorResponse['message'];
          }
          
          throw Exception(errorMessage);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Reset form setelah submit
  void _resetForm() {
    _formKey.currentState!.reset();
    _tanggalController.clear();
    _tanggalBerakhirController.clear();
    _alasanController.clear();
    setState(() {
      _selectedDate = null;
      _selectedEndDate = null;
    });
  }

  // Fungsi untuk navigasi
  void _onNavItemTapped(int index) {
    if (index == 0) return; // Jika tab saat ini (Form) diklik, tidak perlu navigasi
    
    switch (index) {
      case 1: // Scan QR
        navigateWithAnimation(context, '/home');
        break;
      case 2: // Profil
        navigateWithAnimation(context, '/profile');
        break;
    }
  }

  // Fungsi untuk memuat riwayat pengajuan
  Future<void> _loadSubmissionHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? userToken = await UserData.getToken();
      if (userToken == null) {
        throw Exception("Token user tidak ditemukan, silakan login ulang");
      }

      final response = await http.get(
        Uri.parse('http://192.168.0.184:8000/api/permission/history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _submissionHistory = List<Map<String, dynamic>>.from(jsonResponse['data']);
        });
      } else {
        throw Exception('Gagal memuat riwayat pengajuan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Widget untuk menampilkan opsi awal
  Widget _buildInitialOptions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showForm = true;
                    _showHistory = false;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 48,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Buat Pengajuan Baru",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Ajukan izin, cuti, atau lembur",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showHistory = true;
                    _showForm = false;
                  });
                  _loadSubmissionHistory();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.green.shade600,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Lihat Riwayat Pengajuan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Cek status pengajuan Anda",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan riwayat pengajuan
  Widget _buildSubmissionHistory() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_submissionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              "Belum ada riwayat pengajuan",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _showHistory = false;
                  _showForm = false;
                });
              },
              child: Text("Kembali"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showHistory = false;
                    _showForm = false;
                  });
                },
              ),
              Text(
                "Riwayat Pengajuan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _submissionHistory.length,
            itemBuilder: (context, index) {
              final submission = _submissionHistory[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    submission['type']?.toString().toUpperCase() ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text('Tanggal: ${submission['date'] ?? 'N/A'}'),
                      Text('Status: ${submission['status'] ?? 'N/A'}'),
                      if (submission['reason'] != null)
                        Text('Alasan: ${submission['reason']}'),
                    ],
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(submission['status']),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(submission['status']),
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper untuk warna status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper untuk icon status
  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Widget untuk form izin
  Widget _buildIzinForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tanggal Izin",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _tanggalController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: "Pilih Tanggal",
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
          ),
          onTap: () => _selectDate(context),
          validator: (value) => value!.isEmpty ? 'Tanggal wajib diisi' : null,
        ),
        SizedBox(height: 20),
        Text(
          "Alasan Izin",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _alasanController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Masukkan alasan izin",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.all(16),
          ),
          validator: (value) => value!.isEmpty ? 'Alasan wajib diisi' : null,
        ),
      ],
    );
  }

  // Widget untuk form cuti
  Widget _buildCutiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tanggal Mulai Cuti",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _tanggalController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: "Pilih Tanggal Mulai",
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
          ),
          onTap: () => _selectDate(context),
          validator: (value) => value!.isEmpty ? 'Tanggal mulai wajib diisi' : null,
        ),
        SizedBox(height: 20),
        Text(
          "Tanggal Selesai Cuti",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _tanggalBerakhirController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: "Pilih Tanggal Selesai",
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
          ),
          onTap: () => _selectEndDate(context),
          validator: (value) => value!.isEmpty ? 'Tanggal selesai wajib diisi' : null,
        ),
        SizedBox(height: 16),
        if (_selectedDate != null && _selectedEndDate != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text(
                  "Jumlah hari: ${_hitungJumlahHari()} hari",
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        SizedBox(height: 20),
        Text(
          "Alasan Cuti",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _alasanController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Masukkan alasan cuti",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.all(16),
          ),
          validator: (value) => value!.isEmpty ? 'Alasan wajib diisi' : null,
        ),
      ],
    );
  }

  // Widget untuk form lembur
  Widget _buildLemburForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tanggal Lembur",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _tanggalController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: "Pilih Tanggal",
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
          ),
          onTap: () => _selectDate(context),
          validator: (value) => value!.isEmpty ? 'Tanggal wajib diisi' : null,
        ),
        SizedBox(height: 20),
        Text(
          "Alasan Lembur",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _alasanController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Masukkan alasan lembur",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.all(16),
          ),
          validator: (value) => value!.isEmpty ? 'Alasan wajib diisi' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showForm ? "Form Pengajuan" :
          _showHistory ? "Riwayat Pengajuan" : "Pengajuan",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: (_showForm || _showHistory) ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showForm = false;
              _showHistory = false;
            });
          },
        ) : null,
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
          child: _showForm
              ? SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.info_outline_rounded,
                                            color: Colors.blue.shade700,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Silahkan pilih jenis pengajuan dan isi form dengan lengkap",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    "Jenis Pengajuan",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedFormType = 'izin';
                                                _resetForm();
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: _selectedFormType == 'izin' ? Colors.blue.shade600 : Colors.transparent,
                                                borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Izin",
                                                  style: TextStyle(
                                                    color: _selectedFormType == 'izin' ? Colors.white : Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedFormType = 'cuti';
                                                _resetForm();
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: _selectedFormType == 'cuti' ? Colors.blue.shade600 : Colors.transparent,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Cuti",
                                                  style: TextStyle(
                                                    color: _selectedFormType == 'cuti' ? Colors.white : Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedFormType = 'lembur';
                                                _resetForm();
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: _selectedFormType == 'lembur' ? Colors.blue.shade600 : Colors.transparent,
                                                borderRadius: BorderRadius.horizontal(right: Radius.circular(11)),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Lembur",
                                                  style: TextStyle(
                                                    color: _selectedFormType == 'lembur' ? Colors.white : Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  // Tampilkan form sesuai jenis yang dipilih
                                  if (_selectedFormType == 'izin') _buildIzinForm(),
                                  if (_selectedFormType == 'cuti') _buildCutiForm(),
                                  if (_selectedFormType == 'lembur') _buildLemburForm(),
                                  SizedBox(height: 30),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              "Kirim Pengajuan",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : _showHistory
                  ? _buildSubmissionHistory()
                  : _buildInitialOptions(),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: _onNavItemTapped,
      ),
    );
  }
}