import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceHelper {
  static String mapStatusToIndonesian(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'hadir':
        return 'Hadir';
      case 'late':
      case 'terlambat':
        return 'Terlambat';
      case 'absent':
      case 'absen':
        return 'Tidak Hadir';
      case 'permission':
      case 'izin':
        return 'Izin';
      case 'leave':
      case 'cuti':
        return 'Cuti';
      case 'overtime':
      case 'lembur':
        return 'Lembur';
      default:
        return 'Tidak Diketahui';
    }
  }

  static Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'hadir':
        return Colors.green;
      case 'terlambat':
        return Colors.orange;
      case 'tidak hadir':
        return Colors.grey;
      case 'izin':
        return Colors.blue;
      case 'cuti':
        return Colors.yellow.shade700;
      case 'lembur':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static String getMonthName(int month) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    // Pastikan month dalam range yang valid
    if (month < 1 || month > 12) {
      return 'Tidak Valid';
    }
    
    return monthNames[month - 1];
  }

  static Future<Map<String, int>> calculateSummary(List<AttendanceModel>? attendanceData) async {
    // Initialize summary with default values
    Map<String, int> summary = {
      'hadir': 0,
      'terlambat': 0,
      'tidak_hadir': 0,
    };

    try {
      // Get current date for work days calculation
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      
      // Calculate the first day of the month
      final firstDay = DateTime(currentYear, currentMonth, 1);
      
      // Create a set of all workdays from 1st until today
      Set<String> workDays = {};
      DateTime currentDate = firstDay;
      
      while (!currentDate.isAfter(now)) {
        // Skip weekends
        if (!isWeekend(currentDate)) {
          workDays.add(dateToString(currentDate));
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      // If no attendance data, all workdays are counted as absent
      if (attendanceData == null || attendanceData.isEmpty) {
        summary['tidak_hadir'] = workDays.length;
        return summary;
      }

      // Create a map of dates with attendance
      Map<String, String> attendanceByDate = {};
      for (var attendance in attendanceData) {
        String dateKey = dateToString(attendance.date);
        // Only store the first status for each date
        if (!attendanceByDate.containsKey(dateKey)) {
          attendanceByDate[dateKey] = attendance.status.toLowerCase();
        }
      }

      // Process each workday
      for (String workDay in workDays) {
        if (attendanceByDate.containsKey(workDay)) {
          String status = attendanceByDate[workDay]!;
          
          switch (status) {
            case 'present':
            case 'hadir':
              summary['hadir'] = (summary['hadir'] ?? 0) + 1;
              break;
            case 'late':
            case 'terlambat':
              // Count late attendance as both 'terlambat' and 'hadir'
              summary['terlambat'] = (summary['terlambat'] ?? 0) + 1;
              summary['hadir'] = (summary['hadir'] ?? 0) + 1;
              break;
          }
        } else {
          // If no attendance record for a workday, count as absent
          summary['tidak_hadir'] = (summary['tidak_hadir'] ?? 0) + 1;
        }
      }

      return summary;
    } catch (e, stackTrace) {
      print('Error in calculateSummary: $e');
      print('Stack trace: $stackTrace');
      return summary;
    }
  }

  // Alternative method if you want to separate "terlambat" from "hadir"
  static Map<String, int> calculateSummaryAlternative(List<AttendanceModel>? attendanceData) {
    Map<String, int> summary = {
      'hadir': 0,
      'terlambat': 0,
      'tidak_hadir': 0,
      'izin': 0,
      'cuti': 0,
      'lembur': 0,
    };

    if (attendanceData == null || attendanceData.isEmpty) {
      return summary;
    }

    try {
      final firstAttendance = attendanceData.first;

      final firstDate = firstAttendance.date;
      final year = firstDate.year;
      final month = firstDate.month;
      
      final lastDay = DateTime(year, month + 1, 0);
      int totalWorkDays = 0;
      
      for (int day = 1; day <= lastDay.day; day++) {
        final currentDate = DateTime(year, month, day);
        if (!isWeekend(currentDate)) {
          totalWorkDays++;
        }
      }

      Set<String> countedDates = <String>{};

      for (var attendance in attendanceData) {
        if (isWeekend(attendance.date)) continue;

        String dateKey = attendance.dateString;
        if (countedDates.contains(dateKey)) continue;
        countedDates.add(dateKey);

        String status = (attendance.status).toLowerCase();
        
        switch (status) {
          case 'present':
          case 'hadir':
            summary['hadir'] = (summary['hadir'] ?? 0) + 1;
            break;
          case 'late':
          case 'terlambat':
            // Only count as late, not as present
            summary['terlambat'] = (summary['terlambat'] ?? 0) + 1;
            break;
          case 'permission':
          case 'izin':
            summary['izin'] = (summary['izin'] ?? 0) + 1;
            break;
          case 'leave':
          case 'cuti':
            summary['cuti'] = (summary['cuti'] ?? 0) + 1;
            break;
          case 'overtime':
          case 'lembur':
            summary['lembur'] = (summary['lembur'] ?? 0) + 1;
            break;
        }
      }

      // Calculate absent days
      int totalAccountedDays = (summary['hadir'] ?? 0) + 
                              (summary['terlambat'] ?? 0) +
                              (summary['izin'] ?? 0) + 
                              (summary['cuti'] ?? 0) + 
                              (summary['lembur'] ?? 0);
      
      int absentDays = totalWorkDays - totalAccountedDays;
      summary['tidak_hadir'] = absentDays < 0 ? 0 : absentDays;

      return summary;
    } catch (e, stackTrace) {
      print('Error in calculateSummaryAlternative: $e');
      print('Stack trace: $stackTrace');
      return summary;
    }
  }

  // Helper method to validate attendance data
  static bool validateAttendanceData(List<AttendanceModel>? data) {
    if (data == null || data.isEmpty) return false;
    
    for (var attendance in data) {
      
    }
    
    return true;
  }

  // Helper method to debug attendance data
  static void debugAttendanceData(List<AttendanceModel>? data) {
    if (data == null) {
      print('Attendance data is null');
      return;
    }
    
    print('Attendance data count: ${data.length}');
    
    for (int i = 0; i < data.length && i < 5; i++) {
      final attendance = data[i];
      print('[$i] Date: ${attendance.date}, Status: ${attendance.status}, DateString: ${attendance.dateString}');
    }
    
    if (data.length > 5) {
      print('... and ${data.length - 5} more entries');
    }
  }

  // Helper to format date as string (YYYY-MM-DD)
  static String dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper to check if a date is a weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}