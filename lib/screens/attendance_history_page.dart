import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/attendance_helper.dart';
import '../widgets/attendance_summary_grid.dart';
import '../widgets/attendance_detail_table.dart';

class AttendanceHistoryPage extends StatefulWidget {
  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> with WidgetsBindingObserver {
  final AttendanceService _attendanceService = AttendanceService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  List<AttendanceModel> _attendanceData = [];
  Map<String, int> _attendanceSummary = {};
  
  late String _selectedMonth;
  late String _selectedYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFilters();
    _fetchAttendanceData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAttendanceData();
    }
  }

  void _initializeFilters() {
    final now = DateTime.now();
    _selectedMonth = now.month.toString().padLeft(2, '0');
    _selectedYear = now.year.toString();
  }

  Future<void> _fetchAttendanceData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch both attendance and permission data in parallel
      final attendanceFuture = _attendanceService.refreshAttendanceData(_selectedMonth, _selectedYear);
      final permissionFuture = _attendanceService.fetchPermissionSummary(
        month: int.parse(_selectedMonth),
        year: int.parse(_selectedYear)
      );

      // Wait for both futures to complete
      final results = await Future.wait([attendanceFuture, permissionFuture]);
      if (!mounted) return;
      
      final attendanceData = results[0] as List<AttendanceModel>;
      final permissionSummary = results[1] as Map<String, int>;
      
      // Calculate attendance summary
      final attendanceSummary = await AttendanceHelper.calculateSummary(attendanceData);
      
      // Merge both summaries
      final combinedSummary = {
        ...attendanceSummary,
        ...permissionSummary,
      };

      setState(() {
        _attendanceData = attendanceData;
        _attendanceSummary = combinedSummary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error fetching attendance data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Riwayat Presensi',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.5,
           color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade600,
          Colors.blue.shade400,
          Colors.blue.shade100,
        ],
        stops: [0.0, 0.3, 1.0],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    return Column(
      children: [
        _buildFilterSection(),
        _buildSummarySection(),
        SizedBox(height: 16),
        _buildDetailSection(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.white),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage,
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchAttendanceData,
            child: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Bulan dan Tahun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMonthDropdown()),
              SizedBox(width: 16),
              Expanded(child: _buildYearDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return _buildDropdown(
      value: _selectedMonth,
      items: [
        for (int i = 1; i <= 12; i++)
          DropdownMenuItem(
            value: i.toString().padLeft(2, '0'),
            child: Text(AttendanceHelper.getMonthName(i)),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedMonth = value);
          _fetchAttendanceData();
        }
      },
    );
  }

  Widget _buildYearDropdown() {
    return _buildDropdown(
      value: _selectedYear,
      items: [
        for (int i = DateTime.now().year - 2; i <= DateTime.now().year; i++)
          DropdownMenuItem(
            value: i.toString(),
            child: Text(i.toString()),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedYear = value);
          _fetchAttendanceData();
        }
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Presensi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          SizedBox(height: 16),
          AttendanceSummaryGrid(summary: _attendanceSummary),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.all(16),
        decoration: _buildCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Presensi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: AttendanceDetailTable(attendanceDetails: _attendanceData),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
} 