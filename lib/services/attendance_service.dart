import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../utils/user_data.dart';

class AttendanceService {
  static const String baseUrl = 'https://staff.wahanadata.co.id/api';
  static const int timeoutDuration = 30; // seconds

  /// Mendapatkan data attendance berdasarkan bulan dan tahun
  Future<List<AttendanceModel>> getAttendanceData(
      String month, String year) async {
    try {
      // Validasi input
      if (month.isEmpty || year.isEmpty) {
        throw Exception('Bulan dan tahun tidak boleh kosong');
      }

      // Validasi format bulan (01-12)
      final monthNum = int.tryParse(month);
      if (monthNum == null || monthNum < 1 || monthNum > 12) {
        throw Exception('Format bulan tidak valid. Gunakan format 01-12');
      }

      // Validasi format tahun
      final yearNum = int.tryParse(year);
      if (yearNum == null ||
          yearNum < 2000 ||
          yearNum > DateTime.now().year + 1) {
        throw Exception('Format tahun tidak valid');
      }

      // Ambil token user
      String? userToken = await UserData.getToken();
      if (userToken == null || userToken.isEmpty) {
        throw Exception("Token user tidak ditemukan, silakan login ulang");
      }

      // Format query parameters with proper padding
      final paddedMonth = month.padLeft(2, '0');
      final queryParams = 'month=$paddedMonth&year=$year';

      // Use the correct API endpoint that matches the web dashboard
      final uri = Uri.parse('$baseUrl/recap/attendance?$queryParams');

      print('Fetching attendance data from: $uri');

      // HTTP request dengan timeout dan retry mechanism
      int retryCount = 0;
      const maxRetries = 3;
      Exception? lastError;

      while (retryCount < maxRetries) {
        try {
          final response = await http.get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userToken',
            },
          ).timeout(
            Duration(seconds: timeoutDuration),
            onTimeout: () {
              throw Exception(
                  'Koneksi timeout. Periksa koneksi internet Anda.');
            },
          );

          if (response.statusCode == 200) {
            return _handleResponse(response);
          } else if (response.statusCode == 401) {
            // Token expired - no need to retry
            throw Exception('Sesi login telah berakhir. Silakan login ulang.');
          } else {
            lastError = Exception(_getErrorMessage(response));
            throw lastError;
          }
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          retryCount++;

          if (retryCount < maxRetries) {
            // Wait before retrying with exponential backoff
            await Future.delayed(
                Duration(milliseconds: 1000 * (1 << retryCount)));
            continue;
          }
          break;
        }
      }

      throw lastError ??
          Exception('Gagal memuat data setelah $maxRetries percobaan');
    } catch (e) {
      print('Error in getAttendanceData: $e');
      rethrow;
    }
  }

  /// Handle response dari API
  List<AttendanceModel> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return _parseSuccessResponse(response.body);
      case 401:
        throw Exception('Sesi login telah berakhir. Silakan login ulang.');
      case 403:
        throw Exception(
            'Akses ditolak. Anda tidak memiliki izin untuk mengakses data ini.');
      case 404:
        throw Exception('Data tidak ditemukan.');
      case 422:
        throw Exception('Data yang dikirim tidak valid.');
      case 500:
        throw Exception(
            'Terjadi kesalahan pada server. Silakan coba lagi nanti.');
      case 503:
        throw Exception(
            'Server sedang dalam pemeliharaan. Silakan coba lagi nanti.');
      default:
        throw Exception('Gagal memuat data. Status: ${response.statusCode}');
    }
  }

  String _getErrorMessage(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      return errorData['message'] ??
          'Terjadi kesalahan: ${response.statusCode}';
    } catch (e) {
      return 'Terjadi kesalahan: ${response.statusCode}';
    }
  }

  /// Parse response yang sukses
  List<AttendanceModel> _parseSuccessResponse(String responseBody) {
    try {
      final jsonData = jsonDecode(responseBody);

      // Validasi struktur response
      if (jsonData is! Map<String, dynamic>) {
        throw Exception('Format response tidak valid');
      }

      // Cek status success
      if (jsonData['success'] != true) {
        String errorMessage = jsonData['message'] ?? 'Gagal memuat data';
        throw Exception(errorMessage);
      }

      // Cek data
      if (jsonData['data'] == null) {
        return []; // Return empty list jika data null
      }

      if (jsonData['data'] is! List) {
        throw Exception('Format data tidak valid');
      }

      final dataList = jsonData['data'] as List;

      // Parse setiap item ke AttendanceModel dengan validasi
      List<AttendanceModel> attendanceList = [];
      for (var item in dataList) {
        try {
          if (item == null) continue;
          if (item is! Map<String, dynamic>) continue;

          // Ensure required fields exist
          if (!item.containsKey('date') || !item.containsKey('status')) {
            print(
                'Skipping invalid attendance record: missing required fields');
            continue;
          }

          final attendance = AttendanceModel.fromJson(item);

          // Validate the parsed model
          if (attendance.isValid) {
            attendanceList.add(attendance);
          } else {
            print('Skipping invalid attendance record: validation failed');
          }
        } catch (e) {
          print('Error parsing attendance item: $e');
          continue;
        }
      }

      print('Successfully parsed ${attendanceList.length} attendance records');
      return attendanceList;
    } catch (e) {
      print('Error parsing response: $e');
      throw Exception('Gagal memproses data: $e');
    }
  }

  /// Refresh attendance data (helper method)
  Future<List<AttendanceModel>> refreshAttendanceData(
      String month, String year) async {
    // Clear any cached data if needed
    return await getAttendanceData(month, year);
  }

  /// Get current month attendance
  Future<List<AttendanceModel>> getCurrentMonthAttendance() async {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    return await getAttendanceData(month, year);
  }

  Future<Map<String, int>> fetchPermissionSummary({int? year, int? month}) async {
  try {
    final token = await UserData.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token not found or empty');
    }

    final now = DateTime.now();
    final queryYear = year ?? now.year;
    final queryMonth = month ?? now.month;

    // Format month to ensure it's 2 digits
    final formattedMonth = queryMonth.toString().padLeft(2, '0');
    final formattedYear = queryYear.toString();

    
    final uri = Uri.parse('$baseUrl/permission/summary?month=$formattedMonth&year=$formattedYear');
    
    print('=== PERMISSION SUMMARY DEBUG ===');
    print('Fetching permission summary from: $uri');
    print('Token (first 20 chars): ${token.length > 20 ? token.substring(0, 20) + "..." : token}');
    print('Month: $formattedMonth, Year: $formattedYear');

    final response = await http.get(  // Changed from POST to GET
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ).timeout(
      Duration(seconds: timeoutDuration),
      onTimeout: () {
        throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
      },
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: ${response.body}');

    // Handle different response codes
    switch (response.statusCode) {
      case 200:
        try {
          final dynamic decodedResponse = json.decode(response.body);
          print('Decoded Response Type: ${decodedResponse.runtimeType}');
          print('Decoded Response Content: $decodedResponse');
          
          Map<String, dynamic> jsonData;
          
          if (decodedResponse is Map<String, dynamic>) {
            // Check if response is wrapped (has success, data fields)
            if (decodedResponse.containsKey('success')) {
              if (decodedResponse['success'] == false) {
                throw Exception(decodedResponse['message'] ?? 'API returned success: false');
              }
              jsonData = decodedResponse.containsKey('data') 
                  ? decodedResponse['data'] as Map<String, dynamic>
                  : decodedResponse;
            } else {
              // Direct response format
              jsonData = decodedResponse;
            }
          } else {
            throw Exception('Invalid response format: expected Map but got ${decodedResponse.runtimeType}');
          }
          
          print('Final JSON Data: $jsonData');
          
          // Extract and validate data
          final Map<String, int> result = {
            'izin': _parseIntValue(jsonData['izin'], 'izin'),
            'cuti': _parseIntValue(jsonData['cuti'], 'cuti'),
            'lembur': _parseIntValue(jsonData['lembur'], 'lembur'),
          };
          
          print('Parsed Permission Summary: $result');
          print('=== END DEBUG ===');
          
          return result;
          
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          throw Exception('Failed to parse response: $parseError');
        }
        
      case 400:
        final errorData = _tryParseErrorResponse(response.body);
        throw Exception('Bad Request: ${errorData['message'] ?? 'Invalid parameters'}');
        
      case 401:
        throw Exception('Sesi login telah berakhir. Silakan login ulang.');
        
      case 404:
        throw Exception('Endpoint permission summary tidak ditemukan. Periksa konfigurasi server.');
        
      case 405:
        throw Exception('Method tidak diizinkan. Server mengharapkan method yang berbeda.');
        
      case 500:
        final errorData = _tryParseErrorResponse(response.body);
        throw Exception('Server Error: ${errorData['message'] ?? 'Internal server error'}');
        
      default:
        final errorData = _tryParseErrorResponse(response.body);
        throw Exception('HTTP Error ${response.statusCode}: ${errorData['message'] ?? response.body}');
    }
    
  } catch (e) {
    print('Error fetching permission summary: $e');
    print('Error type: ${e.runtimeType}');
    
    if (e is Exception) {
      rethrow;
    } else {
      throw Exception('Unexpected error: $e');
    }
  }
}

// Helper methods remain the same
int _parseIntValue(dynamic value, String fieldName) {
  print('Parsing $fieldName: $value (type: ${value.runtimeType})');
  
  if (value == null) {
    print('$fieldName is null, returning 0');
    return 0;
  }
  
  if (value is int) {
    print('$fieldName is int: $value');
    return value;
  }
  
  if (value is String) {
    final parsed = int.tryParse(value);
    print('$fieldName parsed from string: $parsed');
    return parsed ?? 0;
  }
  
  if (value is double) {
    final rounded = value.round();
    print('$fieldName rounded from double: $rounded');
    return rounded;
  }
  
  print('$fieldName has unexpected type, returning 0');
  return 0;
}

Map<String, dynamic> _tryParseErrorResponse(String responseBody) {
  try {
    final errorData = json.decode(responseBody);
    return errorData is Map<String, dynamic> ? errorData : {};
  } catch (e) {
    return {'message': responseBody};
  }
}
}
