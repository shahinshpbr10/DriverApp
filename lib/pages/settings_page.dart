import 'package:driver_app/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double padding = size.width * 0.05;
    final double iconSize = size.width * 0.07;
    final double titleFont = size.width * 0.05;
    final double subtitleFont = size.width * 0.035;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: titleFont,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff84CB17),
                Color(0xff6BA513),
                Color(0xff5A8F0F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xff84CB17).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: ListView(
            padding: EdgeInsets.all(padding),
            children: [
              /// Profile Section
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff84CB17).withOpacity(0.1),
                      Color(0xff84CB17).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(size.width * 0.04),
                      decoration: BoxDecoration(
                        color: Color(0xff84CB17),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: iconSize + 8,
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Profile',
                            style: TextStyle(
                              fontSize: titleFont * 0.9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your account settings',
                            style: TextStyle(
                              fontSize: subtitleFont,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: size.width * 0.035,
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.03),

              /// Sections
              _buildSettingsSection('General', context, [
                _buildSettingsItem(Icons.notifications_outlined, 'Notifications', 'Manage push notifications', context, size),
                _buildSettingsItem(Icons.language_outlined, 'Language', 'Change app language', context, size),
                _buildSettingsItem(Icons.dark_mode_outlined, 'Theme', 'Light or dark mode', context, size),
              ]),

              SizedBox(height: size.height * 0.03),

              _buildSettingsSection('Support', context, [
                _buildSettingsItem(Icons.help_outline, 'Help & Support', 'Get help and contact support', context, size),
                _buildSettingsItem(Icons.info_outline, 'About', 'App version and information', context, size),
              ]),

              SizedBox(height: size.height * 0.03),

              _buildSettingsSection('Account', context, [
                _buildSettingsItem(Icons.logout, 'Logout', 'Sign out of your account', context, size, isDestructive: true),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, BuildContext context, List<Widget> items) {
    final double titleFont = MediaQuery.of(context).size.width * 0.045;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: titleFont,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
      IconData icon,
      String title,
      String subtitle,
      BuildContext context,
      Size size, {
        bool isDestructive = false,
      }) {
    final double iconBoxSize = size.width * 0.11;
    final double titleFont = size.width * 0.045;
    final double subtitleFont = size.width * 0.035;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[100]!,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: iconBoxSize,
          height: iconBoxSize,
          padding: EdgeInsets.all(iconBoxSize * 0.2),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : Color(0xff84CB17).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Color(0xff84CB17),
            size: iconBoxSize * 0.6,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: titleFont,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: subtitleFont,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: size.width * 0.03,
        ),
        onTap: () {
          if (isDestructive) {
            _logout(context);
          } else {
            _showUnavailableAlert(context);
          }
        },
      ),
    );
  }

  void _showUnavailableAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feature Unavailable'),
        content: Text('This feature is not available now.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }
}
