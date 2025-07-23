import 'package:flutter/material.dart';

class AttendanceSummaryGrid extends StatelessWidget {
  final Map<String, int> summary;

  const AttendanceSummaryGrid({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kehadiran Section
        _buildSectionTitle('Kehadiran'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildSummaryCard('Hari Masuk', summary['hadir'] ?? 0, Colors.green),
            _buildSummaryCard('Hari Telat', summary['terlambat'] ?? 0, Colors.orange),
            _buildSummaryCard('Tidak Hadir', summary['tidak_hadir'] ?? 0, Colors.grey),
          ],
        ),
        SizedBox(height: 24),
        // Perizinan Section
        _buildSectionTitle('Perizinan'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildSummaryCard('Hari Izin', summary['izin'] ?? 0, Colors.blue),
            _buildSummaryCard('Hari Cuti', summary['cuti'] ?? 0, Colors.yellow.shade700),
            _buildSummaryCard('Hari Lembur', summary['lembur'] ?? 0, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}