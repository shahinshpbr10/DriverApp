import 'package:driver_app/common/textstyles.dart';
import 'package:driver_app/pages/history_page.dart';
import 'package:driver_app/pages/home_page.dart';
import 'package:driver_app/pages/settings_page.dart';
import 'package:flutter/material.dart';

class CustomNavbar extends StatefulWidget {
  @override
  _CustomNavbarState createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static List<Widget> _pages = <Widget>[
    HomeScreen(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _animationController.reset();
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward();
    }
  }

  double responsiveFontSize(double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    return baseSize * (screenWidth / 375); // 375 is base design width
  }

  double responsiveIconSize(double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    return baseSize * (screenWidth / 375);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Color(0xff84CB17),
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: responsiveFontSize(12),
            ),
            unselectedLabelStyle: AppTextStyles.smallBodyText.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: responsiveFontSize(11),
            ),
            items: [
              _buildNavItem(
                Icons.home_rounded,
                Icons.home_outlined,
                'Home',
                0,
              ),
              _buildNavItem(
                Icons.history_rounded,
                Icons.history_outlined,
                'History',
                1,
              ),
              _buildNavItem(
                Icons.settings_rounded,
                Icons.settings_outlined,
                'Settings',
                2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData selectedIcon,
      IconData unselectedIcon,
      String label,
      int index,
      ) {
    bool isSelected = _selectedIndex == index;
    double iconSize = responsiveIconSize(isSelected ? 26 : 24);

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(responsiveIconSize(8)),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xff84CB17).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          size: iconSize,
        ),
      ),
      label: label,
    );
  }
}
