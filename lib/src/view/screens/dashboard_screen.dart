import 'package:corona_lms_webapp/main.dart';
import 'package:corona_lms_webapp/src/controller/classes_controllers/fetch_classes.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/student_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDate;
  late List<DateTime> _calendarDays;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDate = DateTime.now();
    _generateCalendarDays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateCalendarDays() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Get the first day of the week for the first day of the month
    int firstWeekday = firstDayOfMonth.weekday % 7;

    // Calculate the first day to display (may be from the previous month)
    final firstDisplayDay =
        firstDayOfMonth.subtract(Duration(days: firstWeekday));

    // Generate 42 days (6 weeks)
    _calendarDays = List.generate(
        42, (index) => firstDisplayDay.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ClassDetailsProvider>(context, listen: false)
        .fetchclass('classes_@corona', context);
    final fetchcontroller =
        Provider.of<StudentDetailsProvider>(context, listen: false);
    fetchcontroller.fetchStudents('Student_list_@12', context);
    fetchcontroller.fetchCourses(context);
 
    final userEmail = fetchcontroller.teacher_name ?? '';
    final displayName = userEmail.isNotEmpty
        ? (userEmail.contains('@') ? userEmail.split('@')[0] : userEmail)
        : 'Administrator';
    final capitalizedName = displayName.isNotEmpty
        ? (displayName[0].toUpperCase() + displayName.substring(1))
        : 'Admin';
 
    return Scaffold(
      backgroundColor: MyApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: MyApp.borderColor, width: 1),
        ),
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: MyApp.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: MyApp.textSecondaryColor),
            onPressed: () {
              context.go('/notifications');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_outlined,
                color: MyApp.textSecondaryColor),
            onPressed: () {
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            _buildWelcomeBanner(capitalizedName),
            const SizedBox(height: 24),
 
            // Admin Quick Operations Toolbar
            _buildAdminQuickActions(),
            const SizedBox(height: 24),
 
            // Stats cards
            _buildStatsCards(),
            const SizedBox(height: 24),
 
            // Main content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - 2/3 width
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Courses
                      _buildSectionHeader('New Courses', onViewAll: () {
                        _showAddCourseDialog();
                      }),
                      const SizedBox(height: 16),
                      _buildCourseCards(),
                      const SizedBox(height: 24),
 
                      // My Students
                      _buildSectionHeader('My Students', onViewAll: () {
                        context.go('/students');
                      }),
                      const SizedBox(height: 16),
                      // _buildStudentsTable(),
                      const SizedBox(height: 24),
 
                      // Fee Collection
                      _buildSectionHeader('Fee Collection', onViewAll: () {}),
                      const SizedBox(height: 16),
                      _buildFeeChart(),
                    ],
                  ),
                ),
 
                const SizedBox(width: 24),
 
                // Right column - 1/3 width
                Expanded(
                  child: Column(
                    children: [
                      // Profile card
                      _buildProfileCard(),
                      const SizedBox(height: 24),
 
                      // Calendar
                      _buildCalendar(),
                      const SizedBox(height: 24),
 
                      // System Audit Activities Logs
                      _buildRecentActivityLog(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildAdminQuickActions() {
    return Row(
      children: [
        _buildQuickActionCard(
          title: 'Register Student',
          subtitle: 'Add new profile to system',
          icon: Icons.person_add_outlined,
          color: MyApp.primaryColor,
          onTap: () => context.go('/students'),
        ),
        const SizedBox(width: 16),
        _buildQuickActionCard(
          title: 'Appoint Teacher',
          subtitle: 'Configure faculty access',
          icon: Icons.supervisor_account_outlined,
          color: MyApp.warningColor,
          onTap: () => context.go('/teachers'),
        ),
        const SizedBox(width: 16),
        _buildQuickActionCard(
          title: 'Post Announcement',
          subtitle: 'Broad notification alerts',
          icon: Icons.campaign_outlined,
          color: MyApp.successColor,
          onTap: () => context.go('/notifications'),
        ),
      ],
    );
  }
 
  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MyApp.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: MyApp.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: MyApp.textSecondaryColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildRecentActivityLog() {
    final activities = [
      {
        'message': 'Esther Howard updated marks for PHYS-102',
        'time': '10 mins ago',
        'icon': Icons.edit_note_outlined,
        'color': MyApp.primaryColor,
      },
      {
        'message': 'New MCQ Exam published to all divisions',
        'time': '1 hour ago',
        'icon': Icons.quiz_outlined,
        'color': MyApp.warningColor,
      },
      {
        'message': 'S. Kumar uploaded CS-101 course material',
        'time': '3 hours ago',
        'icon': Icons.video_collection_outlined,
        'color': MyApp.successColor,
      },
      {
        'message': 'New student account created for ST-1092',
        'time': 'Yesterday',
        'icon': Icons.person_add_outlined,
        'color': MyApp.primaryColor,
      },
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyApp.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Activities & Logs',
            style: TextStyle(
              color: MyApp.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ...activities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(activity['icon'] as IconData,
                          size: 16, color: activity['color'] as Color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['message'] as String,
                            style: TextStyle(
                                color: MyApp.textPrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['time'] as String,
                            style: TextStyle(
                                color: MyApp.textSecondaryColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
 
  Widget _buildWelcomeBanner(String userName) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyApp.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MyApp.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'FALL 2026 SEMESTER',
                        style: TextStyle(
                          color: MyApp.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MyApp.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'MIDTERM PERIOD',
                        style: TextStyle(
                          color: MyApp.successColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome Back, $userName 👋',
                  style: TextStyle(
                    color: MyApp.textPrimaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your courses, view students, grade exams, and inspect tuition reports on your unified college portal.',
                  style: TextStyle(
                    color: MyApp.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Icon(Icons.school, size: 64, color: MyApp.primaryColor.withOpacity(0.15)),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final controller =
        Provider.of<StudentDetailsProvider>(context, listen: false);
    final controller1 =
        Provider.of<ClassDetailsProvider>(context, listen: false);

    return Row(
      children: [
        _buildStatCard(
          title: 'Total Students',
          value: controller.studentDetails.isEmpty
              ? '0'
              : '${controller.studentDetails.length}',
          icon: Icons.people_outline,
          color: MyApp.primaryColor,
          increase: '+0%',
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          title: 'Total Classes',
          value: controller1.classDetails.isEmpty
              ? '0'
              : '${controller1.classDetails.length}',
          icon: Icons.book_outlined,
          color: MyApp.warningColor,
          increase: '+0%',
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          title: 'Total Teachers',
          value: controller.TeacherDetails.isEmpty
              ? '0'
              : '${controller.TeacherDetails.length}',
          icon: Icons.supervisor_account_outlined,
          color: MyApp.primaryColor,
          increase: '+0',
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          title: 'Total Exams',
          value: '0',
          icon: Icons.assignment_outlined,
          color: MyApp.errorColor,
          increase: '+0%',
          isPositive: true,
        ),
      ],
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
          border: Border.all(color: MyApp.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
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
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: MyApp.textSecondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      color: MyApp.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? MyApp.successColor : MyApp.errorColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        increase,
                        style: TextStyle(
                          color: isPositive ? MyApp.successColor : MyApp.errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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

  Widget _buildSectionHeader(String title, {required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            title == 'New Courses' ? 'Add Course' : 'View all',
            style: TextStyle(
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCourseDialog() {
    final TextEditingController CourseController = TextEditingController();
    final controller = StudentService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: CourseController,
                  decoration: InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),
                // DropdownButtonFormField<String>(
                //   decoration: InputDecoration(
                //     labelText: 'Fee Status',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   value: selectedFeeStatus,
                //   items: const [
                //     DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                //     DropdownMenuItem(value: 'Due', child: Text('Due')),
                //     DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                //   ],
                //   onChanged: (value) {
                //     selectedFeeStatus = value!;
                //   },
                // ),
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
              controller.addCourse(CourseController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Course added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // index.updateindex();
              Provider.of<StudentDetailsProvider>(context, listen: false)
                  .fetchCourses(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }

  void _showupdateCourseDialog(course) {
    final TextEditingController CourseController =
        TextEditingController(text: course);
    final controller = StudentService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Course'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: CourseController,
                  decoration: InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),
                // DropdownButtonFormField<String>(
                //   decoration: InputDecoration(
                //     labelText: 'Fee Status',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   value: selectedFeeStatus,
                //   items: const [
                //     DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                //     DropdownMenuItem(value: 'Due', child: Text('Due')),
                //     DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                //   ],
                //   onChanged: (value) {
                //     selectedFeeStatus = value!;
                //   },
                // ),
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
              controller.updateCourse(course, {'title': CourseController.text});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Course updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              // index.updateindex();
              Provider.of<StudentDetailsProvider>(context, listen: false)
                  .fetchCourses(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('update Course'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCards() {
    return Consumer<StudentDetailsProvider>(builder: (context, value, child) {
      final courses = value.cources_lists;
      return value.cources_lists.isNotEmpty
          ? SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final String title = course['title'] as String;
                  
                  // Dynamically infer code & dept for college look
                  String code = 'CSE-301';
                  String dept = 'Computer Science';
                  IconData unitIcon = Icons.computer;
                  
                  if (title.toLowerCase().contains('math')) {
                    code = 'MATH-201';
                    dept = 'Mathematics & Stats';
                    unitIcon = Icons.calculate_outlined;
                  } else if (title.toLowerCase().contains('phys')) {
                    code = 'PHYS-102';
                    dept = 'Physics & Astronomy';
                    unitIcon = Icons.science_outlined;
                  } else if (title.toLowerCase().contains('chem')) {
                    code = 'CHEM-204';
                    dept = 'Chemical Engineering';
                    unitIcon = Icons.biotech_outlined;
                  } else if (title.toLowerCase().contains('biol')) {
                    code = 'BIOL-101';
                    dept = 'Biological Sciences';
                    unitIcon = Icons.bubble_chart_outlined;
                  } else if (title.toLowerCase().contains('eng')) {
                    code = 'ENGL-110';
                    dept = 'English Literature';
                    unitIcon = Icons.menu_book_outlined;
                  } else {
                    code = 'UNIV-${100 + index}';
                    dept = 'General Academics';
                    unitIcon = Icons.menu_book_outlined;
                  }
 
                  return Container(
                    width: 290,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MyApp.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: MyApp.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  unitIcon,
                                  color: MyApp.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: MyApp.backgroundColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: MyApp.borderColor),
                                ),
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    color: MyApp.textPrimaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  _showupdateCourseDialog(course['title']);
                                },
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: MyApp.textSecondaryColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  final controller = StudentService();
                                  controller.deleteCourse(course['title']);
                                },
                                child: Icon(
                                  Icons.delete_outline,
                                  color: MyApp.errorColor,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            title,
                            style: TextStyle(
                              color: MyApp.textPrimaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dept,
                            style: TextStyle(
                              color: MyApp.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: MyApp.textSecondaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '32 Enrolled',
                                style: TextStyle(color: MyApp.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                'Credits: 3.0',
                                style: TextStyle(color: MyApp.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'No Courses Found',
                  style: TextStyle(color: MyApp.textSecondaryColor),
                ),
              ),
            );
    });
  }

  Widget _buildStudentsTable() {
    final controller =
        Provider.of<StudentDetailsProvider>(context, listen: false);

    List students = [
      // {
      //   'name': 'John Smith',
      //   'id': 'ST-1001',
      //   'course': 'Mathematics',
      //   'attendance': 92,
      //   'fee': 'Paid',
      // },
      // {
      //   'name': 'Emily Johnson',
      //   'id': 'ST-1002',
      //   'course': 'Physics',
      //   'attendance': 88,
      //   'fee': 'Due',
      // },
      // {
      //   'name': 'Michael Brown',
      //   'id': 'ST-1003',
      //   'course': 'Chemistry',
      //   'attendance': 95,
      //   'fee': 'Paid',
      // },
      // {
      //   'name': 'Sarah Davis',
      //   'id': 'ST-1004',
      //   'course': 'Mathematics',
      //   'attendance': 78,
      //   'fee': 'Partial',
      // },
    ];
    List tempdata = controller.studentDetails;
    students = tempdata.take(10).toList();
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Course',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Attendance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Fee Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(),
          ...students.map((student) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(''),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            student['student_name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(student['id'] as String),
                    ),
                    // Expanded(
                    //   child: Text(student['course'] as String),
                    // ),
                    // Expanded(
                    //   child: Row(
                    //     children: [
                    //       Container(
                    //         width: 50,
                    //         height: 8,
                    //         decoration: BoxDecoration(
                    //           color: (student['attendance'] as int) > 90
                    //               ? Colors.green
                    //               : (student['attendance'] as int) > 80
                    //                   ? Colors.orange
                    //                   : Colors.red,
                    //           borderRadius: BorderRadius.circular(4),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 8),
                    //       Text('${student['attendance']}%'),
                    //     ],
                    //   ),
                    // ),
                    // Expanded(
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 12, vertical: 6),
                    //     decoration: BoxDecoration(
                    //       color: (student['fee'] as String) == 'Paid'
                    //           ? Colors.green.withOpacity(0.1)
                    //           : (student['fee'] as String) == 'Due'
                    //               ? Colors.red.withOpacity(0.1)
                    //               : Colors.orange.withOpacity(0.1),
                    //       borderRadius: BorderRadius.circular(20),
                    //     ),
                    //     child: Text(
                    //       student['fee'] as String,
                    //       style: TextStyle(
                    //         color: (student['fee'] as String) == 'Paid'
                    //             ? Colors.green
                    //             : (student['fee'] as String) == 'Due'
                    //                 ? Colors.red
                    //                 : Colors.orange,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFeeChart() {
    return Container(
      height: 300,
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
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
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
                          padding: const EdgeInsets.only(top: 8.0),
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
                          padding: const EdgeInsets.only(right: 8.0),
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
    );
  }

  Widget _buildProfileCard() {
    final controller1 =
        Provider.of<ClassDetailsProvider>(context, listen: false);
    final controller =
        Provider.of<StudentDetailsProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyApp.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
          ),
          const SizedBox(height: 16),
          Text(
            '${controller.teacher_name}',
            style: TextStyle(
              color: MyApp.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Administrator',
            style: TextStyle(
              color: MyApp.textSecondaryColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildProfileStat('Students', '${controller.studentDetails.length}'),
          const SizedBox(height: 12),
          _buildProfileStat('Courses', '${controller1.classDetails.length}'),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: MyApp.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: MyApp.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyApp.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  color: MyApp.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: MyApp.textSecondaryColor),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: MyApp.textSecondaryColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Sun', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textSecondaryColor, fontSize: 12)),
              Text('Mon', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textSecondaryColor, fontSize: 12)),
              Text('Tue', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textSecondaryColor, fontSize: 12)),
              Text('Wed', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textSecondaryColor, fontSize: 12)),
              Text('Thu', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textSecondaryColor, fontSize: 12)),
              Text('Fri', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textSecondaryColor, fontSize: 12)),
              Text('Sat', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textSecondaryColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final day = _calendarDays[index];
              final isCurrentMonth = day.month == _selectedDate.month;
              final isToday = day.year == DateTime.now().year &&
                  day.month == DateTime.now().month &&
                  day.day == DateTime.now().day;
              final hasEvent = day.day % 5 == 0; // Just for demo

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? MyApp.primaryColor
                        : day == _selectedDate
                            ? MyApp.primaryColor.withOpacity(0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: isToday
                              ? Colors.white
                              : day == _selectedDate
                                  ? MyApp.primaryColor
                                  : isCurrentMonth
                                      ? MyApp.textPrimaryColor
                                      : Colors.grey[400],
                          fontWeight: isToday || day == _selectedDate
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (hasEvent && isCurrentMonth)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Colors.white
                                  : day == _selectedDate
                                      ? MyApp.primaryColor
                                      : MyApp.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkProgress() {
    final homeworks = [
      {
        'title': 'Mathematics Assignment',
        'progress': 75,
        'color': MyApp.primaryColor,
      },
      {
        'title': 'Physics Lab Report',
        'progress': 45,
        'color': MyApp.warningColor,
      },
      {
        'title': 'Chemistry Quiz Prep',
        'progress': 90,
        'color': MyApp.successColor,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyApp.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Homework Progress',
            style: TextStyle(
              color: MyApp.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ...homeworks.map((homework) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          homework['title'] as String,
                          style: TextStyle(
                            color: MyApp.textPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${homework['progress']}%',
                          style: TextStyle(
                            color: homework['color'] as Color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (homework['progress'] as int) / 100,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        homework['color'] as Color,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
