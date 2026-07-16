import 'package:corona_lms_webapp/firebase_options.dart';
import 'package:corona_lms_webapp/src/controller/attendance_controller/attendance_controller.dart';
import 'package:corona_lms_webapp/src/controller/classes_controllers/fetch_classes.dart';
import 'package:corona_lms_webapp/src/controller/fee_recorder/fee_recorder.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';
import 'package:corona_lms_webapp/src/view/screens/attendance_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/classes_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/dashboard_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/exam_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/fees_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/login_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/mark-adding-screen.dart';
import 'package:corona_lms_webapp/src/view/screens/mark-history.dart';
import 'package:corona_lms_webapp/src/view/screens/notifications_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/students_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/teachers_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/messages_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/settings_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setUrlStrategy(PathUrlStrategy());
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<StudentDetailsProvider>(
        create: (context) => StudentDetailsProvider(),
      ),
      ChangeNotifierProvider<ClassDetailsProvider>(
        create: (context) => ClassDetailsProvider(),
      ),
      ChangeNotifierProvider<AttendanceController>(
        create: (context) => AttendanceController(),
      ),
      ChangeNotifierProvider<FeeRecorder>(
        create: (context) => FeeRecorder(),
      )
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // Define app colors (Modern SaaS Palette)
  static const Color primaryColor = Color(0xFF3B82F6); // Primary Blue
  static const Color primaryDark = Color(0xFF2563EB); // Primary Dark Blue
  static const Color accentColor = Color(0xFF60A5FA); // Accent Light Blue
  static const Color backgroundColor = Color(0xFFF8FAFC); // Clean Background
  static const Color surfaceColor = Color(0xFFFFFFFF); // Surface Card White
  static const Color borderColor = Color(0xFFE5E7EB); // Soft Border Gray
  static const Color dividerColor = Color(0xFFF1F5F9); // Light Divider
  static const Color textPrimaryColor = Color(0xFF111827); // Dark Text
  static const Color textSecondaryColor = Color(0xFF6B7280); // Gray Text
  static const Color successColor = Color(0xFF22C55E); // Green Success
  static const Color warningColor = Color(0xFFF59E0B); // Amber Warning
  static const Color errorColor = Color(0xFFEF4444); // Red Error

  // Maintain old constants mapping for screen compatibility
  static const Color darkColor = textPrimaryColor;
  static const Color lightColor = backgroundColor;
  static const Color secondaryBlue = primaryColor;

  // Set up routing
  final _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/teachers',
            builder: (context, state) => const TeachersScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/fees',
            builder: (context, state) => const FeesScreen(),
          ),
          GoRoute(
            path: '/classes',
            builder: (context, state) => const ClassesScreen(),
          ),
          GoRoute(
            path: '/exam',
            builder: (context, state) => const ExamsScreen(),
          ),
          GoRoute(
            path: '/markAdding',
            builder: (context, state) => const MarkAddingPage(),
          ),
          GoRoute(
            path: '/updateMarks',
            builder: (context, state) => WebMarkHistoryScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(
              classId: 'notifications',
              userId: 'notifications',
              userName: 'notifications',
              userRole: 'notifications',
            ),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tuition Center LMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        dividerColor: dividerColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: surfaceColor,
          background: backgroundColor,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: textPrimaryColor,
          displayColor: textPrimaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondaryColor),
          hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
        ),
      ),
      routerConfig: _router,
    );
  }
}

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/students');
        break;
      case 2:
        context.go('/teachers');
        break;
      case 3:
        context.go('/attendance');
        break;
      case 4:
        context.go('/fees');
        break;
      case 5:
        context.go('/classes');
        break;
      case 6:
        context.go('/exam');
        break;
      case 7:
        context.go('/markAdding');
        break;
      case 8:
        context.go('/updateMarks');
        break;
      case 9:
        context.go('/notifications');
        break;
      case 10:
        context.go('/messages');
        break;
      case 11:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1100;
    final studentProvider = Provider.of<StudentDetailsProvider>(context);
    final userEmail = studentProvider.teacher_name ?? '';
    final displayName = userEmail.isNotEmpty
        ? (userEmail.contains('@') ? userEmail.split('@')[0] : userEmail)
        : 'Administrator';
    final capitalizedName = displayName.isNotEmpty
        ? (displayName[0].toUpperCase() + displayName.substring(1))
        : 'Admin';

    return Scaffold(
      backgroundColor: MyApp.backgroundColor,
      body: Row(
        children: [
          // Animated sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isExpanded ? (isTablet ? 70 : 260) : 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: MyApp.borderColor, width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: _isExpanded && !isTablet
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MyApp.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school, color: MyApp.primaryColor, size: 24),
                      ),
                      if (_isExpanded && !isTablet) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'Academy LMS',
                          style: TextStyle(
                            color: MyApp.textPrimaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
                      _buildNavItem(1, Icons.people_outline, 'Students'),
                      _buildNavItem(2, Icons.supervisor_account_outlined, 'Teachers'),
                      _buildNavItem(3, Icons.how_to_reg_outlined, 'Attendance'),
                      _buildNavItem(4, Icons.payment_outlined, 'Fees'),
                      _buildNavItem(5, Icons.video_library_outlined, 'Classes'),
                      _buildNavItem(6, Icons.assignment_outlined, 'Exam'),
                      _buildNavItem(7, Icons.grade_outlined, 'Mark Listing'),
                      _buildNavItem(8, Icons.edit_note_outlined, 'Update Mark'),
                      _buildNavItem(9, Icons.notifications_none_outlined, 'Notifications'),
                      _buildNavItem(10, Icons.chat_bubble_outline, 'Messages'),
                      _buildNavItem(11, Icons.settings_outlined, 'Settings'),
                    ],
                  ),
                ),
                // Profile Section at bottom
                if (_isExpanded && !isTablet)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MyApp.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MyApp.borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: MyApp.primaryColor.withOpacity(0.1),
                          child: Text(
                            capitalizedName[0].toUpperCase(),
                            style: const TextStyle(
                              color: MyApp.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                capitalizedName,
                                style: const TextStyle(
                                  color: MyApp.textPrimaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Admin Account',
                                style: TextStyle(
                                  color: MyApp.textSecondaryColor,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: MyApp.primaryColor.withOpacity(0.1),
                      child: Text(
                        capitalizedName[0].toUpperCase(),
                        style: const TextStyle(
                          color: MyApp.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Toggle sidebar button
                if (!isTablet)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      onPressed: _toggleSidebar,
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _animationController,
                        color: MyApp.textSecondaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: MyApp.backgroundColor,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1100;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? MyApp.primaryColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateTo(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? MyApp.primaryColor : MyApp.textSecondaryColor,
                ),
                if (_isExpanded && !isTablet) ...[
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? MyApp.primaryColor : MyApp.textSecondaryColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
