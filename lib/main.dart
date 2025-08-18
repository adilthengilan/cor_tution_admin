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
import 'package:corona_lms_webapp/src/view/screens/messages_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/notifications_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/students_screen.dart';
import 'package:corona_lms_webapp/src/view/screens/teachers_screen.dart';
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

  // Define app colors
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep blue
  static const Color accentColor = Color(0xFFFFC107); // Yellow
  static const Color darkColor = Color(0xFF121212); // Almost black
  static const Color lightColor = Color(0xFFF8F9FA); // Light background
  static const Color secondaryBlue = Color(0xFF3B82F6); // Secondary blue

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
          // GoRoute(
          //   path: '/messages',
          //   builder: (context, state) => const MessagesScreen(),
          // ),
          GoRoute(
            path: '/classes',
            builder: (context, state) => const ClassesScreen(),
          ),
          GoRoute(
            path: '/exam',
            builder: (context, state) => const ExamsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
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
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: lightColor,
          background: lightColor,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: darkColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // cardTheme: CardTheme(
        //   elevation: 2,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(16),
        //   ),
        // ),
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
      // case 4:
      //   context.go('/messages');
      //   break;
      case 5:
        context.go('/classes');
        break;
      case 6:
        context.go('/exam');
        break;
      case 7:
        context.go('/notifications');
        break;
      // case 8:
      //   context.go('/settings');
      //   break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1100;

    return Scaffold(
      body: Row(
        children: [
          // Animated sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isExpanded ? (isTablet ? 70 : 250) : 70,
            color: MyApp.primaryColor,
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
                          color: MyApp.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school, color: MyApp.darkColor),
                      ),
                      if (_isExpanded && !isTablet) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'Academy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                      _buildNavItem(1, Icons.people, 'Students'),
                      _buildNavItem(2, Icons.people, 'Teachers'),

                      _buildNavItem(3, Icons.people, 'Attendance'),
                      _buildNavItem(4, Icons.payments, 'Fees'),
                      // _buildNavItem(4, Icons.message, 'Messages'),
                      _buildNavItem(5, Icons.youtube_searched_for, 'Classes'),
                      _buildNavItem(6, Icons.edit_document, 'Exam'),
                      _buildNavItem(7, Icons.notifications, 'Notifications'),
                      // _buildNavItem(8, Icons.settings, 'Settings'),
                    ],
                  ),
                ),
                // Toggle sidebar button
                if (!isTablet)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      onPressed: () {},
                      // onPressed: _toggleSidebar,
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _animationController,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: Colors.grey[100],
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
        color: isSelected ? MyApp.accentColor : Colors.transparent,
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
                  color: isSelected ? MyApp.darkColor : Colors.white,
                ),
                if (_isExpanded && !isTablet) ...[
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? MyApp.darkColor : Colors.white,
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
