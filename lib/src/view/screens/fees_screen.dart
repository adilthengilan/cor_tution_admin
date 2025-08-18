import 'dart:math';

import 'package:corona_lms_webapp/src/controller/fee_recorder/fee_recorder.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({Key? key}) : super(key: key);

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Paid', 'Due', 'Partial'];

  List _feeRecords = [
    // {
    //   'id': 'FEE-1001',
    //   'studentId': 'ST-1001',
    //   'studentName': 'John Smith',
    //   'course': 'Mathematics',
    //   'amount': 500.0,
    //   'dueDate': '15 May 2023',
    //   'status': 'Paid',
    //   'paymentDate': '10 May 2023',
    //   'avatar': 'https://i.pravatar.cc/150?img=1',
    // },
    // {
    //   'id': 'FEE-1002',
    //   'studentId': 'ST-1002',
    //   'studentName': 'Emily Johnson',
    //   'course': 'Physics',
    //   'amount': 600.0,
    //   'dueDate': '20 May 2023',
    //   'status': 'Due',
    //   'paymentDate': '-',
    //   'avatar': 'https://i.pravatar.cc/150?img=5',
    // },
    // {
    //   'id': 'FEE-1003',
    //   'studentId': 'ST-1003',
    //   'studentName': 'Michael Brown',
    //   'course': 'Chemistry',
    //   'amount': 550.0,
    //   'dueDate': '25 May 2023',
    //   'status': 'Partial',
    //   'paymentDate': '15 May 2023',
    //   'avatar': 'https://i.pravatar.cc/150?img=3',
    // },
    // {
    //   'id': 'FEE-1004',
    //   'studentId': 'ST-1004',
    //   'studentName': 'Sarah Davis',
    //   'course': 'Biology',
    //   'amount': 500.0,
    //   'dueDate': '10 May 2023',
    //   'status': 'Paid',
    //   'paymentDate': '05 May 2023',
    //   'avatar': 'https://i.pravatar.cc/150?img=4',
    // },
    // {
    //   'id': 'FEE-1005',
    //   'studentId': 'ST-1005',
    //   'studentName': 'David Wilson',
    //   'course': 'English',
    //   'amount': 450.0,
    //   'dueDate': '30 May 2023',
    //   'status': 'Due',
    //   'paymentDate': '-',
    //   'avatar': 'https://i.pravatar.cc/150?img=6',
    // },
    // {
    //   'id': 'FEE-1006',
    //   'studentId': 'ST-1006',
    //   'studentName': 'Jessica Taylor',
    //   'course': 'History',
    //   'amount': 500.0,
    //   'dueDate': '05 Jun 2023',
    //   'status': 'Due',
    //   'paymentDate': '-',
    //   'avatar': 'https://i.pravatar.cc/150?img=7',
    // },
  ];

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
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3B82F6),
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
          _buildAnalyticsTab(),
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
                        // Expanded(
                        //   child: Text(
                        //     'Fee ID',
                        //     style: TextStyle(
                        //       fontWeight: FontWeight.bold,
                        //       color: Colors.grey,
                        //     ),
                        //   ),
                        // ),
                        // Expanded(
                        //   child: Text(
                        //     'Course',
                        //     style: TextStyle(
                        //       fontWeight: FontWeight.bold,
                        //       color: Colors.grey,
                        //     ),
                        //   ),
                        // ),
                        Expanded(
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        // Expanded(
                        //   child: Text(
                        //     'Due Date',
                        //     style: TextStyle(
                        //       fontWeight: FontWeight.bold,
                        //       color: Colors.grey,
                        //     ),
                        //   ),
                        // ),
                        Expanded(
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 80),
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
                                                  // backgroundImage: NetworkImage(
                                                  //     record['avatar']),
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
                                                  // Text(
                                                  //   record['studentId'],
                                                  //   style: TextStyle(
                                                  //     color: Colors.grey[600],
                                                  //     fontSize: 12,
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Expanded(
                                        //   child: Text(record['id']),
                                        // ),
                                        // Expanded(
                                        //   child: Text(record['course']),
                                        // ),
                                        Expanded(
                                          child: Text(
                                              '\₹${record['totalAmountPaid']}'),
                                        ),
                                        // Expanded(
                                        //   child: Text(record['dueDate']),
                                        // ),
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
                                          width: 80,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Color(0xFF3B82F6)),
                                                onPressed: () {
                                                  _showEditFeeRecordDialog(
                                                      record);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  _showDeleteConfirmationDialog(
                                                      record);
                                                },
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
                                  // tooltipBgColor: Colors.blueGrey,
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
    String generatePassword({
      int length = 8,
      bool includeUppercase = true,
      bool includeLowercase = true,
      bool includeNumbers = true,
      bool includeSymbols = true,
    }) {
      const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const lowercase = 'abcdefghijklmnopqrstuvwxyz';
      const numbers = '0123456789';
      const symbols = '!@#\$%^&*()_-+=<>?/|';

      String chars = '';
      if (includeUppercase) chars += uppercase;
      if (includeLowercase) chars += lowercase;
      if (includeNumbers) chars += numbers;
      if (includeSymbols) chars += symbols;

      if (chars.isEmpty) return '';

      final rand = Random.secure();
      return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
          .join();
    }

    final TextEditingController namecontroller = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController date = TextEditingController();
    String selectedStatus = 'Paid';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Fee Record'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DropdownButtonFormField<String>(
                //   decoration: InputDecoration(
                //     labelText: 'Student',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   items: _feeRecords.map<DropdownMenuItem<String>>((record) {
                //     return DropdownMenuItem<String>(
                //       value: record['studentId']
                //           .toString(), // Ensure it's a String
                //       child: Text(
                //           '${record['studentName']} (${record['studentId']})'),
                //     );
                //   }).toList(),
                //   onChanged: (value) {
                //     // Your logic here
                //   },
                // ),
                TextField(
                  controller: namecontroller,
                  decoration: InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // TextField(
                //   decoration: InputDecoration(
                //     labelText: 'Course',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Due', child: Text('Due')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
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
              final id = generatePassword();
              // final data = {
              //   'id': id,
              //   'studentName': namecontroller.text,
              //   'payment': [
              //     {'amount': amountController.text, 'date': dateKey}
              //   ],
              //   'status': selectedStatus,
              // };
              // final feecontroller =
              //     Provider.of<FeeRecorder>(context, listen: false);
              int amount = int.tryParse(amountController.text.trim()) ?? 0;
              DateTime? paymentDate = DateTime.tryParse(dateKey);

              addOrUpdateStudentByName(
                  docId: 'student_fees',
                  studentId: id,
                  studentName: namecontroller.text,
                  amount: amount,
                  date: paymentDate!,
                  status: selectedStatus);
              addToTotalAmount('student_fees', amount);

              // print(data);
              // Add fee record logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fee record added successfully'),
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
            child: const Text('Add Record'),
          ),
        ],
      ),
    );
  }

  List get _filteredFeeRecordsname {
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

  void _showEditFeeRecordDialog(Map<String, dynamic> record) {
    final TextEditingController namecontroller =
        TextEditingController(text: record['studentName']);
    final TextEditingController amountcontroller =
        TextEditingController(text: record['totalAmountPaid']);
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
                // TextField(
                //   decoration: InputDecoration(
                //     labelText: 'Course',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   controller: TextEditingController(text: record['course']),
                // ),
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
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(text: record['dueDate']),
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
                    setState(() {
                      selectedstatus = value!;
                    });
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
                'studentName': record['studentName'],
                'amount': record['amount'],
                'dueDate': dateKey,
                'status': record['status'],
              };
              provider.updatefees(newFeeData, record['id']);

              Navigator.pop(context);
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
        content:
            Text('Are you sure you want to delete fee record ${record['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete fee record logic here
              Navigator.pop(context);
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
