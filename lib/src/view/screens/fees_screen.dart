import 'dart:math';

import 'package:corona_lms_webapp/src/controller/fee_recorder/fee_recorder.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({Key? key}) : super(key: key);

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

String _selectedDivision = 'All Division';
String _selectedClass = 'All Classes';

final List<String> classes = [
  'All Classes',
  '12th',
  '11th',
  '10th',
  '9th',
  '8th',
  '7th',
  '6th'
];
final List<String> Division = [
  'All Division',
  'M1',
  'M2',
  'M3',
  'M4',
  'M5',
  'M6',
  'M7',
  'E1',
  'E2',
  'E3',
  'E4',
  'E5',
  'S1',
  'S2',
  'S3'
];

class _FeesScreenState extends State<FeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Paid', 'Due', 'Partial'];
  List<dynamic> _students = [];
  List _feeRecords = [];

  List get _filteredFeeRecords {
    if (_selectedFilter == 'All') {
      return _feeRecords.where((record) {
        final name = record['studentName'].toString().toLowerCase();
        final id = record['id'].toString().toLowerCase();
        final studentId = record['studentId'].toString().toLowerCase();
        final query = _searchController.text.toLowerCase();

        return name.contains(query) ||
            id.contains(query) ||
            studentId.contains(query);
      }).toList();
    } else {
      return _feeRecords.where((record) {
        final name = record['studentName'].toString().toLowerCase();
        final id = record['id'].toString().toLowerCase();
        final studentId = record['studentId'].toString().toLowerCase();
        final query = _searchController.text.toLowerCase();

        return (name.contains(query) ||
                id.contains(query) ||
                studentId.contains(query)) &&
            record['status'] == _selectedFilter;
      }).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feepro = Provider.of<FeeRecorder>(context, listen: false);
    feepro.fetchStudents('', context);
    _feeRecords = feepro.feedetails;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[400]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Fees Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromARGB(255, 255, 255, 255),
          unselectedLabelColor: const Color.fromARGB(255, 0, 0, 0),
          indicatorColor: const Color.fromARGB(255, 255, 255, 255),
          tabs: const [
            Tab(text: 'Fee Records'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeeRecordsTab(),
          // _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildFeeRecordsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search and add button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search fee records...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddFeeRecordDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Fee Record'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(filter),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF3B82F6).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(
                      color:
                          isSelected ? const Color(0xFF3B82F6) : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Fee records table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: const [
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Student',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 120),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Table body
                  Expanded(
                    child: _filteredFeeRecords.isEmpty
                        ? const Center(
                            child: Text(
                              'No fee records found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredFeeRecords.length,
                            itemBuilder: (context, index) {
                              final record = _filteredFeeRecords[index];
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                child: Text(
                                                  record['name'][0]
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    const Color(0xFF3B82F6),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    record['name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                              '\₹${record['totalAmountPaid']}'),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: record['status'] == 'Paid'
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : record['status'] == 'Due'
                                                      ? Colors.red
                                                          .withOpacity(0.1)
                                                      : Colors.orange
                                                          .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              record['status'],
                                              style: TextStyle(
                                                color: record['status'] ==
                                                        'Paid'
                                                    ? Colors.green
                                                    : record['status'] == 'Due'
                                                        ? Colors.red
                                                        : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.print,
                                                    color: Colors.green),
                                                onPressed: () {
                                                  // _showReceiptDialog(record);
                                                },
                                                tooltip: 'Print Receipt',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Color(0xFF3B82F6)),
                                                onPressed: () {
                                                  _showEditFeeRecordDialog(
                                                      record);
                                                },
                                                tooltip: 'Edit',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  _showDeleteConfirmationDialog(
                                                      record);
                                                },
                                                tooltip: 'Delete',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index < _filteredFeeRecords.length - 1)
                                    const Divider(),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          Row(
            children: [
              _buildStatCard(
                title: 'Total Fees Collected',
                value: '\$24,500',
                icon: Icons.attach_money,
                color: const Color(0xFF10B981),
                increase: '+18%',
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Due Fees',
                value: '\$8,245',
                icon: Icons.payment,
                color: const Color(0xFFEF4444),
                increase: '-3%',
                isPositive: false,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Partial Payments',
                value: '\$3,120',
                icon: Icons.sync_alt,
                color: const Color(0xFFFFC107),
                increase: '+5%',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Charts
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fee collection chart
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fee Collection (Last 6 Months)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100000,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    const months = [
                                      'Jan',
                                      'Feb',
                                      'Mar',
                                      'Apr',
                                      'May',
                                      'Jun'
                                    ];
                                    return BarTooltipItem(
                                      '${months[groupIndex]}\n\$${rod.toY.round()}',
                                      const TextStyle(color: Colors.white),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const titles = [
                                        'Jan',
                                        'Feb',
                                        'Mar',
                                        'Apr',
                                        'May',
                                        'Jun'
                                      ];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          titles[value.toInt()],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      String text;
                                      if (value == 0) {
                                        text = '\$0';
                                      } else if (value == 25000) {
                                        text = '\$25K';
                                      } else if (value == 50000) {
                                        text = '\$50K';
                                      } else if (value == 75000) {
                                        text = '\$75K';
                                      } else if (value == 100000) {
                                        text = '\$100K';
                                      } else {
                                        return Container();
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          text,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                    reservedSize: 40,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 45000,
                                      color: const Color(0xFF3B82F6),
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 60000,
                                      color: const Color(0xFF3B82F6),
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 2,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 75000,
                                      color: const Color(0xFF3B82F6),
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 3,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 55000,
                                      color: const Color(0xFF3B82F6),
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 4,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 85000,
                                      color: const Color(0xFF3B82F6),
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 5,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 95000,
                                      color: const Color(0xFFFFC107),
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Fee status pie chart
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fee Status Distribution',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: 60,
                                  title: '60%',
                                  color: Colors.green,
                                  radius: 100,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 30,
                                  title: '30%',
                                  color: Colors.red,
                                  radius: 100,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: 10,
                                  title: '10%',
                                  color: Colors.orange,
                                  radius: 100,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Paid', Colors.green),
                            const SizedBox(width: 16),
                            _buildLegendItem('Due', Colors.red),
                            const SizedBox(width: 16),
                            _buildLegendItem('Partial', Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String increase,
    bool isPositive = true,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        increase,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  void _showAddFeeRecordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AddFeeRecordDialog(
          onSubmit: _handleAddFeeRecord,
        );
      },
    );
  }

  void _showReceiptDialog(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) {
        return ReceiptDialog(record: record);
      },
    );
  }

  void _handleAddFeeRecord(
    String? selectedStudentId,
    String studentName,
    String phoneNumber,
    int amount,
    String selectedStatus,
    DateTime selectedDate,
  ) {
    try {
      // Add the fee record
      addOrUpdateStudentByName(
        docId: 'student_fees',
        studentId: selectedStudentId!,
        studentName: studentName,
        phoneNumber: phoneNumber,
        amount: amount,
        date: selectedDate,
        status: selectedStatus,
      );

      // Update total amount
      addToTotalAmount('student_fees', amount);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Fee record added successfully for $studentName'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      setState(() {}); // Refresh the UI
    } catch (e) {
      _showErrorSnackBar('Failed to add fee record. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showEditFeeRecordDialog(Map<String, dynamic> record) {
    final TextEditingController namecontroller =
        TextEditingController(text: record['name']);
    final TextEditingController amountcontroller =
        TextEditingController(text: record['totalAmountPaid'].toString());
    String selectedstatus = record['status'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fee Record'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Student',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: namecontroller,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\₹',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: amountcontroller,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedstatus,
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Due', child: Text('Due')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    selectedstatus = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              DateTime _selectedDate = DateTime.now();
              final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
              final provider = Provider.of<FeeRecorder>(context, listen: false);
              final newFeeData = {
                'id': record['id'],
                'studentName': record['name'],
                'amount': int.parse(amountcontroller.text),
                'dueDate': dateKey,
                'status': selectedstatus,
              };
              provider.updatefees(newFeeData, record['id']);

              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fee record updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Update Record'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee Record'),
        content: Text(
            'Are you sure you want to delete fee record for ${record['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete fee record logic here
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fee record deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Separate StatefulWidget for Add Fee Record Dialog
class AddFeeRecordDialog extends StatefulWidget {
  final Function(String?, String, String, int, String, DateTime) onSubmit;

  const AddFeeRecordDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddFeeRecordDialog> createState() => _AddFeeRecordDialogState();
}

class _AddFeeRecordDialogState extends State<AddFeeRecordDialog> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // State variables
  String _selectedStatus = 'Paid';
  DateTime _selectedDate = DateTime.now();
  String _selectedClass = 'All Classes';
  String _selectedDivision = 'All Division';
  String? _selectedStudentId;
  String _searchQuery = '';
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredStudents {
    if (_students.isEmpty) return [];

    return _students.where((student) {
      // Class and Division filtering
      bool matchesClass =
          _selectedClass == 'All Classes' || student['class'] == _selectedClass;
      bool matchesDivision = _selectedDivision == 'All Division' ||
          student['division'] == _selectedDivision;

      // Search filtering
      bool matchesSearch = _searchQuery.isEmpty ||
          student['student_name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          student['id'].toString().contains(_searchQuery);

      return matchesClass && matchesDivision && matchesSearch;
    }).toList()
      ..sort((a, b) =>
          a['student_name'].toString().compareTo(b['student_name'].toString()));
  }

  @override
  Widget build(BuildContext context) {
    // Get students from provider
    final studentsProvider =
        Provider.of<StudentDetailsProvider>(context, listen: false);
    _students = studentsProvider.studentDetails;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_card, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Fee Record',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.filter_list,
                                  size: 20, color: Color(0xFF3B82F6)),
                              SizedBox(width: 8),
                              Text(
                                'Filter Students',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Class & Division Filters
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Class',
                                  value: _selectedClass,
                                  items: classes,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedClass = newValue!;
                                      _selectedStudentId = null;
                                      _nameController.clear();
                                      _phoneController.clear();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Division',
                                  value: _selectedDivision,
                                  items: Division,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedDivision = newValue!;
                                      _selectedStudentId = null;
                                      _nameController.clear();
                                      _phoneController.clear();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Search Field
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search by name or ID',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _selectedStudentId = null;
                                _nameController.clear();
                                _phoneController.clear();
                              });
                            },
                          ),

                          // Results count
                          const SizedBox(height: 8),
                          Text(
                            '${_filteredStudents.length} students found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Student Selection
                    _buildDropdownField(
                      label: 'Select Student *',
                      value: _selectedStudentId,
                      items: _filteredStudents
                          .map((student) => student['id'].toString())
                          .toList(),
                      itemBuilder: (studentId) {
                        final studentData = _filteredStudents
                            .firstWhere((s) => s['id'].toString() == studentId);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentData['student_name'].toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'ID: ${studentData['id']} • Class: ${studentData['class']}-${studentData['division']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        );
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedStudentId = value;
                          if (value != null) {
                            final studentData = _filteredStudents
                                .firstWhere((s) => s['id'].toString() == value);
                            _nameController.text =
                                studentData['student_name'].toString();
                            _phoneController.text =
                                studentData['phone']?.toString() ?? '';
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Form Fields
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Student Name',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount *',
                              prefixText: '\₹ ',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Status',
                            value: _selectedStatus,
                            items: const ['Paid', 'Due', 'Partial'],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Date Field
                    TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Payment Date',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                _dateController.text =
                                    DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Add Record'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Widget Function(String)? itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: items.map<DropdownMenuItem<String>>((String item) {
                if (itemBuilder != null) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: itemBuilder!(item),
                  );
                } else {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }
              }).toList(),
              onChanged: onChanged,
              hint: Text('Select $label'),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    // Validation
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      _showErrorSnackBar('Please select a student');
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter an amount');
      return;
    }

    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    // Submit the form
    widget.onSubmit(
      _selectedStudentId,
      _nameController.text,
      _phoneController.text,
      amount,
      _selectedStatus,
      _selectedDate,
    );

    Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Receipt Dialog Widget
class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> record;

  const ReceiptDialog({
    Key? key,
    required this.record,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final receiptId = 'RCP-${DateTime.now().millisecondsSinceEpoch}';
    final currentDate = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fee Receipt',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const Divider(thickness: 2),

            // Receipt Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School/Institution Header
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'CORONA LEARNING MANAGEMENT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fee Payment Receipt',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Receipt Details
                  _buildReceiptRow('Receipt ID:', receiptId),
                  _buildReceiptRow('Date & Time:', currentDate),
                  const SizedBox(height: 16),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Student Details
                  const Text(
                    'Student Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Name:', record['name']),
                  _buildReceiptRow(
                      'Student ID:', record['id']?.toString() ?? 'N/A'),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Payment Details
                  const Text(
                    'Payment Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                      'Amount Paid:', '₹${record['totalAmountPaid']}'),
                  _buildReceiptRow('Payment Status:', record['status']),
                  _buildReceiptRow('Payment Method:',
                      'Cash/Online'), // You can make this dynamic

                  const SizedBox(height: 20),

                  // Total Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '₹${record['totalAmountPaid']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Thank you for your payment!',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is a computer-generated receipt.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Print functionality - you can implement actual printing here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt printed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Download functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt downloaded successfully!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
