import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/user_data.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/page_transition.dart';
import '../services/attendance_service.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  final AttendanceService _attendanceService = AttendanceService();
  bool isScanned = false;
  String scanResult = '';
  bool isTorchOn = false;
  bool isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == 1) return; // Jika tab saat ini (Scan QR) diklik, tidak perlu navigasi
    
    switch (index) {
      case 0: // Form Gabungan
        navigateWithAnimation(context, '/form');
        break;
      case 2: // Profil
        navigateWithAnimation(context, '/profile');
        break;
    }
  }

  Future<void> _processQRData(String data) async {
    if (isScanned || isProcessing) return;

    setState(() {
      isScanned = true;
      isProcessing = true;
      scanResult = data;
    });

    try {
      // Parse QR code URL
      Uri uri = Uri.parse(data);
      String? minute = uri.queryParameters['minute'];
      String? token = uri.queryParameters['token'];

      if (minute == null || token == null) {
        _showErrorToast("QR Code tidak valid - parameter tidak lengkap");
        return;
      }

      // Get user token
      String? userToken = await UserData.getToken();
      if (userToken == null) {
        _showErrorToast("Token user tidak ditemukan, silakan login ulang");
        return;
      }

      // Send request to API
      final response = await http.post(
        Uri.parse('https://staff.wahanadata.co.id/api/attendance/scan-qr'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'minute': minute,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success']) {
          String message = jsonData['message'];
          String type = jsonData['type'];
          String time = jsonData['time'];
          
          _showSuccessToast(message);
          
          // Update scan result display
          setState(() {
            scanResult = "$message pada $time";
          });
          
          // Refresh attendance data
          final now = DateTime.now();
          final month = now.month.toString().padLeft(2, '0');
          final year = now.year.toString();
          await _attendanceService.refreshAttendanceData(month, year);
        
        } else {
          _showErrorToast(jsonData['message']);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorToast(errorData['message'] ?? 'Gagal melakukan absensi');
      }
    } catch (e) {
      print('Error processing QR: $e');
      _showErrorToast("Gagal memproses QR Code: $e");
    } finally {
      setState(() {
        isProcessing = false;
      });
      
      // Reset scanner setelah 3 detik
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            isScanned = false;
            scanResult = '';
          });
        }
      });
    }
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan QR Absensi',
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
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  key: ValueKey<bool>(isTorchOn),
                ),
              ),
              onPressed: () {
                controller.toggleTorch();
                setState(() {
                  isTorchOn = !isTorchOn;
                });
              },
            ),
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
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!isScanned)
                          MobileScanner(
                            controller: controller,
                            onDetect: (BarcodeCapture capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _processQRData(barcode.rawValue!);
                                  break;
                                }
                              }
                            },
                          ),
                        
                        if (isScanned)
                          Container(
                            color: Colors.black.withOpacity(0.7),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isProcessing)
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  if (isProcessing)
                                    SizedBox(height: 16),
                                  Text(
                                    isProcessing ? 'Memproses...' : 'Berhasil!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                        if (!isScanned)
                          Positioned.fill(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: CustomPaint(
                                painter: ScannerCornersPainter(
                                  borderColor: Colors.blue.shade400,
                                  cornerSize: 40,
                                ),
                              ),
                            ),
                          ),
                        
                        // Scanning animation line
                        if (!isScanned)
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final boxSize = MediaQuery.of(context).size.width * 0.7;
                              return Positioned(
                                top: boxSize * 0.1 + (boxSize * 0.8 * _animation.value),
                                child: Container(
                                  width: boxSize,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.blue.shade400.withOpacity(0.8),
                                        Colors.blue.shade400,
                                        Colors.blue.shade400.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade400.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.5),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner,
                                  size: 32,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Arahkan kamera ke QR Code',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'QR Code akan otomatis terdeteksi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (isScanned && scanResult.isNotEmpty)
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.only(top: 16),
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    scanResult,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
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
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

// Custom painter for scanner corners
class ScannerCornersPainter extends CustomPainter {
  final Color borderColor;
  final double cornerSize;
  
  ScannerCornersPainter({
    required this.borderColor,
    required this.cornerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      // Top-left corner
      [
        Offset(0, cornerSize),
        Offset(0, 0),
        Offset(cornerSize, 0),
      ],
      // Top-right corner
      [
        Offset(size.width - cornerSize, 0),
        Offset(size.width, 0),
        Offset(size.width, cornerSize),
      ],
      // Bottom-right corner
      [
        Offset(size.width, size.height - cornerSize),
        Offset(size.width, size.height),
        Offset(size.width - cornerSize, size.height),
      ],
      // Bottom-left corner
      [
        Offset(cornerSize, size.height),
        Offset(0, size.height),
        Offset(0, size.height - cornerSize),
      ],
    ];

    for (final corner in corners) {
      final path = Path();
      path.moveTo(corner[0].dx, corner[0].dy);
      path.lineTo(corner[1].dx, corner[1].dy);
      path.lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}