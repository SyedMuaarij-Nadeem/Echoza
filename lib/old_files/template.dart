







import '../pages/echoza_splash.dart';
import '../pages/audio_file_page.dart';
import '../pages/history_page.dart';
import '../pages/video_file_page.dart';
import '../pages/record_file_page.dart';
import '../widgets/echoza_sideBar.dart';
import '../widgets/side_bar_icon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import '../pages/echoza_login.dart'; // Add this import
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(EchozaApp());
}

class EchozaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7E7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: InnerShadow(
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(4, 4),
            ),
            BoxShadow(
              color:  Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: Offset(-4, -4),
            ),
          ],
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFE1E1F5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SidebarIcon(),
                  ),
                  SizedBox(width: 25),
                  Image.asset('assets/echoza_logo.png', height: 60),
                  SizedBox(width: 5),
                  Text(
                    'Echoza',
                    style: TextStyle(
                      fontSize: 48,
                      fontFamily: 'omegle',
                      foreground:
                      Paint()
                        ..shader = LinearGradient(
                          colors: [
                            Color(0xFFFE5B54),
                            Color(0xFFFF8764),
                            Color(0xFFFE5B54),
                          ],
                          stops: [0.0, 0.5, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: EchozaSidebar(),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentPageIndex = index);
            },
            children: [
              RecordFilePage(),
              AudioFilePage(),
              VideoFilePage(),
              HistoryPage(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5867E1), Color(0xFF323D95)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentPageIndex,
          onTap: (index) async {
            setState(() {
              _currentPageIndex = index;
            });
            await Future.delayed(Duration(milliseconds: 100));
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Color(0xFFFF8764),
          unselectedItemColor: Colors.white70,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.lato(fontSize: 13.5, height: 1.5),
          unselectedLabelStyle: GoogleFonts.lato(fontSize: 13, height: 1.5),
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.mic_none_rounded, 0),
              label: 'Record',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.audio_file_outlined, 1),
              label: 'Audio',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.ondemand_video, 2),
              label: 'Video',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.access_time_outlined, 3),
              label: 'Recents',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData iconData, int index) {
    final bool isActive = _currentPageIndex == index;

    return isActive
        ? Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
          bottom: Radius.circular(25),
        ),
      ),
      child: Icon(iconData, size: 28, color: Colors.white),
    )
        : Icon(iconData, size: 28, color: Colors.white70);
  }
}
