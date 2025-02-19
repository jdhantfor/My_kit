import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'today_screen.dart';
import 'treatment_screen.dart';
import 'medicine_cabinet_screen.dart';
import 'overview_screen.dart';
import 'database_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const TodayScreen(),
    const TreatmentScreen(),
    const MedicineCabinetScreen(),
    const OverviewScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    DatabaseService.initializeDatabase();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              _buildNavigationBarItem('assets/today.svg', 'Сегодня', 0),
              _buildNavigationBarItem('assets/health.svg', 'Лечение', 1),
              _buildNavigationBarItem('assets/aptechka.svg', 'Аптечка', 2),
              _buildNavigationBarItem('assets/hp.svg', 'Здоровье', 3),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF197FF2),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            iconSize: 24,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedLabelStyle: const TextStyle(height: 2),
            unselectedLabelStyle: const TextStyle(height: 2),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
      String assetName, String label, int index) {
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            assetName,
            width: 24,
            height: 24,
            color:
                _selectedIndex == index ? const Color(0xFF197FF2) : Colors.grey,
            colorBlendMode: BlendMode.srcIn,
          ),
        ],
      ),
      label: label,
    );
  }
}
