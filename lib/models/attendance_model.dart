class AttendanceModel {
  final DateTime date;
  final String checkIn;
  final String checkOut;
  final String status;

  AttendanceModel({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) {
        print('Warning: Date value is null, using current date');
        return DateTime.now();
      }
      
      if (value is DateTime) {
        return value;
      }
      
      if (value is String) {
        // Remove any extra whitespace
        value = value.trim();
        
        if (value.isEmpty) {
          print('Warning: Date string is empty, using current date');
          return DateTime.now();
        }
        
        try {
          // Try to parse ISO format first
          return DateTime.parse(value);
        } catch (e1) {
          try {
            // Try to parse Y-m-d format
            final parts = value.split('-');
            if (parts.length >= 3) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final dayPart = parts[2].split(' ')[0]; // Remove time part if exists
              final day = int.parse(dayPart);
              
              // Validate date components
              if (year > 1900 && year < 3000 && 
                  month >= 1 && month <= 12 && 
                  day >= 1 && day <= 31) {
                return DateTime(year, month, day);
              }
            }
          } catch (e2) {
            print('Warning: Could not parse date parts from "$value"');
          }
          
          try {
            // Try d/m/Y or m/d/Y format
            final parts = value.split('/');
            if (parts.length == 3) {
              // Assume d/m/Y format (adjust as needed for your data)
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              
              if (year > 1900 && year < 3000 && 
                  month >= 1 && month <= 12 && 
                  day >= 1 && day <= 31) {
                return DateTime(year, month, day);
              }
            }
          } catch (e3) {
            print('Warning: Could not parse date from slash format "$value"');
          }
        }
      }
      
      // If all parsing attempts fail, log and return current date
      print('Error: Could not parse date "$value" (type: ${value.runtimeType}), using current date');
      return DateTime.now();
    }

    try {
      final parsedDate = parseDate(json['date']);
      final checkIn = json['check_in']?.toString() ?? '-';
      final checkOut = json['check_out']?.toString() ?? '-';
      final status = json['status']?.toString().toLowerCase() ?? 'absent';

      return AttendanceModel(
        date: parsedDate,
        checkIn: checkIn,
        checkOut: checkOut,
        status: status,
      );
    } catch (e, stackTrace) {
      print('Error creating AttendanceModel from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stackTrace');
      
      // Return a default model to prevent crashes
      return AttendanceModel(
        date: DateTime.now(),
        checkIn: '-',
        checkOut: '-',
        status: 'absent',
      );
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'date': date.toIso8601String(),
        'check_in': checkIn,
        'check_out': checkOut,
        'status': status,
      };
    } catch (e) {
      print('Error converting AttendanceModel to JSON: $e');
      return {
        'date': DateTime.now().toIso8601String(),
        'check_in': '-',
        'check_out': '-',
        'status': 'absent',
      };
    }
  }

  // Helper method untuk mendapatkan string tanggal dalam format Y-m-d
  String get dateString {
    try {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error generating dateString: $e');
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  // Helper method untuk mendapatkan string tanggal yang mudah dibaca
  String get readableDateString {
    try {
      const monthNames = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      
      final monthName = monthNames[date.month - 1];
      return '${date.day} $monthName ${date.year}';
    } catch (e) {
      print('Error generating readableDateString: $e');
      return dateString;
    }
  }

  // Helper method untuk validasi data
  bool get isValid {
    try {
      // Check if date is reasonable (not too far in past/future)
      final now = DateTime.now();
      final minDate = DateTime(now.year - 5, 1, 1);
      final maxDate = DateTime(now.year + 1, 12, 31);
      
      return date.isAfter(minDate) && date.isBefore(maxDate);
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() {
    return 'AttendanceModel(date: $dateString, checkIn: $checkIn, checkOut: $checkOut, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceModel &&
        other.dateString == dateString &&
        other.checkIn == checkIn &&
        other.checkOut == checkOut &&
        other.status == status;
  }

  @override
  int get hashCode {
    return dateString.hashCode ^
        checkIn.hashCode ^
        checkOut.hashCode ^
        status.hashCode;
  }
}