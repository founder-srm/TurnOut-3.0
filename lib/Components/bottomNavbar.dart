import 'package:flutter/material.dart';

class BottomNavbar extends StatefulWidget {
  final Function(int) onTabChanged;

  const BottomNavbar({
    Key? key,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'QR Scanner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info),
          label: 'About',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFFF8BB0F),
      unselectedItemColor: Colors.grey,
      elevation: 8,
      backgroundColor: Colors.white,
      onTap: _onItemTapped,
    );
  }
}
