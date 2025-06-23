import 'package:flutter/material.dart';

class SidebarIcon extends StatelessWidget {
  const SidebarIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Scaffold.of(context).openDrawer();
      },
      child: Image.asset(
        'assets/sideBarIcon.png',
        width: 30,
        height: 30,
        color: Color(0xFF4754C5),
      ),
    );
  }
}