import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/page_transition.dart';
import '../utils/user_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

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

  // Tambahkan variabel untuk attachment
  File? _selectedFile;
  String? _fileName;

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

  // Fungsi untuk memilih file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        // Cek ukuran file (maksimum 2MB)
        if (result.files.single.size > 2 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Ukuran file melebihi batas maksimum (2MB)'),
                  ),
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

        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = path.basename(_selectedFile!.path);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Gagal memilih file: Format file tidak didukung'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  // Fungsi untuk menghapus file yang dipilih
  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
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
        var uri = Uri.parse('https://staff.wahanadata.co.id/api/permission/$_selectedFormType');
        var request = http.MultipartRequest('POST', uri);
        
        // Tambahkan headers
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        });

        // Tambahkan fields
        request.fields['tanggal'] = _tanggalController.text;
        request.fields['alasan'] = _alasanController.text;
        if (_selectedFormType == 'cuti') {
          request.fields['tanggal_berakhir'] = _tanggalBerakhirController.text;
        }

        // Tambahkan file jika ada
        if (_selectedFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              _selectedFile!.path,
              filename: _fileName,
            ),
          );
        }

        // Kirim request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          
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
      _selectedFile = null;
      _fileName = null;
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
        Uri.parse('https://staff.wahanadata.co.id/api/permission'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _submissionHistory = List<Map<String, dynamic>>.from(jsonResponse['permissions']);
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

 // Ganti bagian _buildSubmissionHistory() di Flutter dengan kode berikut:

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

  return ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: _submissionHistory.length,
    itemBuilder: (context, index) {
      final submission = _submissionHistory[index];
      
      // Format tanggal dari string "YYYY-MM-DD" ke "DD MMMM YYYY"
      String formattedDate = 'N/A';
      if (submission['tanggal'] != null) {
        try {
          final date = DateTime.parse(submission['tanggal']);
          formattedDate = "${date.day} ${_getMonthName(date.month)} ${date.year}";
        } catch (e) {
          print('Error parsing date: $e');
        }
      }

      // FIXED: Status mapping yang benar sesuai dengan backend PHP
      String status = submission['status']?.toString() ?? '';
      String statusIndo = '';
      Color statusColor = Colors.grey;
      IconData statusIcon = Icons.help;
      
      switch (status) {
        case 'Menunggu':
          statusIndo = 'Menunggu';
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
          break;
        case 'Disetujui':
          statusIndo = 'Disetujui';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case 'Ditolak':
          statusIndo = 'Ditolak';
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
          break;
        default:
          statusIndo = 'Menunggu';
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
      }

      return Card(
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      submission['type']?.toString().toUpperCase() ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Tanggal : $formattedDate',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              if (submission['created_at'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Dibuat pada : ${_formatDateTime(submission['created_at'])}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Status : ',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusIndo,
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (submission['alasan'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Alasan : ${submission['alasan']}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              // Tambahkan bagian attachment jika ada
              if (submission['file_path'] != null) ...[
                SizedBox(height: 12),
                InkWell(
                  onTap: () => _downloadAttachment(submission['file_path']),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 20, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Lihat Lampiran',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}


  // Helper untuk mendapatkan nama bulan
  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final day = dateTime.day.toString();
      final month = _getMonthName(dateTime.month);
      final year = dateTime.year.toString();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      
      return "$day $month $year, $hour:$minute WIB";
    } catch (e) {
      print('Error parsing datetime: $e');
      return dateTimeStr;
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
        SizedBox(height: 20),
        _buildFileInput(),
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
        SizedBox(height: 20),
        _buildFileInput(),
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
        SizedBox(height: 20),
        _buildFileInput(),
      ],
    );
  }

  // Widget untuk menampilkan input file
  Widget _buildFileInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              "Lampiran",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "(Opsional)",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Format yang didukung: JPG, JPEG, PNG, PDF, DOC, DOCX",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
                  SizedBox(width: 8),
                  Text(
                    "Maksimum ukuran file: 2MB",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        if (_selectedFile == null)
          InkWell(
            onTap: _pickFile,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.attach_file, color: Colors.blue.shade600),
                  SizedBox(width: 12),
                  Text(
                    "Pilih File",
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  _getFileIcon(_fileName ?? ''),
                  color: Colors.blue.shade700,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fileName ?? 'File terpilih',
                    style: TextStyle(color: Colors.blue.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: _removeFile,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper untuk mendapatkan icon file
  IconData _getFileIcon(String fileName) {
    String ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Fungsi untuk mendownload atau membuka attachment
  Future<void> _downloadAttachment(String url) async {
    try {
      // Hapus prefix 'izin-files/' dari url jika ada
      String cleanUrl = url.replaceAll('izin-files/', '');
      print('[Download] Original URL: $url');
      print('[Download] Cleaned URL: $cleanUrl');
      
      // Cek apakah file adalah gambar berdasarkan ekstensi
      bool isImage = cleanUrl.toLowerCase().endsWith('.jpg') || 
                    cleanUrl.toLowerCase().endsWith('.jpeg') || 
                    cleanUrl.toLowerCase().endsWith('.png');
      print('[Download] Is image file: $isImage');

      // Buat URL lengkap untuk mengakses file
      String fullUrl = 'https://staff.wahanadata.co.id/storage/izin-files/$cleanUrl';
      print('[Download] Full URL: $fullUrl');

      final Uri uri = Uri.parse(fullUrl);
      print('[Download] Parsed URI: $uri');

      if (isImage) {
        // Tampilkan gambar dalam dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      actions: [
                        // Tombol download
                        IconButton(
                          icon: Icon(Icons.download, color: Colors.black),
                          onPressed: () async {
                            try {
                              print('[Download] Attempting to launch URL: $fullUrl');
                              if (!await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              )) {
                                throw Exception('Could not launch $fullUrl');
                              }
                            } catch (e) {
                              print('[Download] Error launching URL: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal membuka file: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    Flexible(
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.network(
                          fullUrl,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('[Download] Error loading image: $error');
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                                  SizedBox(height: 8),
                                  Text('Gagal memuat gambar'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // Untuk file non-gambar, buka di browser
        try {
          print('[Download] Attempting to launch URL for non-image: $fullUrl');
          if (!await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          )) {
            throw Exception('Could not launch $fullUrl');
          }
        } catch (e) {
          print('[Download] Error launching URL: $e');
          throw 'Tidak dapat membuka file';
        }
      }
    } catch (e) {
      print('[Download] Function error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka file: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    }
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