import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/overview/pulse_widget.dart';
import 'package:my_aptechka/screens/overview/blood_pressure_widget.dart';
import 'package:my_aptechka/screens/overview/steps_widget.dart';
import 'package:my_aptechka/screens/overview/pulse_detail_screen.dart';
import 'package:my_aptechka/screens/overview/blood_pressure_detail_screen.dart';
import 'package:my_aptechka/screens/overview/steps_detail_screen.dart';
import 'package:my_aptechka/screens/overview/add_pulse.dart';
import 'package:my_aptechka/screens/overview/add_blood_pressure.dart';
import 'package:my_aptechka/screens/overview/add_steps.dart';
import 'package:my_aptechka/screens/overview/documents_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  int _selectedTab = 0; // 0 для показателей, 1 для документов

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Пожалуйста, войдите в систему')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: CustomDropdown(
          items: const ['Мое здоровье', 'Бабушка', 'Дедушка'],
          onSelected: (item) {
            // Обработка выбора
          },
        ),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 8,
              ),
            ),
            child: PopupMenuButton<String>(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.more_horiz, color: Colors.black),
              ),
              offset: const Offset(0, 50),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'bracelet',
                  child: Text('Настройка браслета'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'privacy',
                  child: Text('Настройка приватности семьи'),
                ),
              ],
              onSelected: (String value) {
                switch (value) {
                  case 'bracelet':
                    // Действие для настройки браслета
                    break;
                  case 'privacy':
                    // Действие для настройки приватности семьи
                    break;
                }
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabButton('Показатели', 0),
                  _buildTabButton('Документы', 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildIndicatorsContent(userId)
                : DocumentsScreen(userId: userId),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedTab == index ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTab == index ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorsContent(String userId) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            _buildHealthItem('Пульс', PulseWidget(userId: userId)),
            const SizedBox(height: 4),
            _buildHealthItem(
                'Кровяное давление', BloodPressureWidget(userId: userId)),
            const SizedBox(height: 4),
            _buildHealthItem('Шаги', StepsWidget(userId: userId)),
            const SizedBox(height: 16),
            _buildBracerStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String title, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _showAddMeasurementBottomSheet(context, title);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _getDetailScreen(title),
                          ),
                        );
                      },
                      child: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          content, // Всегда показываем контент
        ],
      ),
    );
  }

  void _showAddMeasurementBottomSheet(BuildContext context, String title) {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _getAddMeasurementWidget(title, userId),
        );
      },
    );
  }

  Widget _getAddMeasurementWidget(String title, String userId) {
    switch (title) {
      case 'Пульс':
        return AddPulse(title: title, userId: userId);
      case 'Кровяное давление':
        return AddBloodPressure(title: title, userId: userId);
      case 'Шаги':
        return AddSteps(title: title, userId: userId);
      default:
        return Container();
    }
  }

  Widget _getDetailScreen(String title) {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return Container();

    switch (title) {
      case 'Пульс':
        return PulseDetailScreen(userId: userId);
      case 'Кровяное давление':
        return BloodPressureDetailScreen(userId: userId);
      case 'Шаги':
        return StepsDetailScreen(userId: userId);
      default:
        return Container();
    }
  }

  Widget _buildBracerStatus() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset(
            'assets/bracer_on.png',
            width: MediaQuery.of(context).size.width - 16,
            fit: BoxFit.fitWidth,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final Function(String) onSelected;

  const CustomDropdown(
      {super.key, required this.items, required this.onSelected});

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _selectedItem = 'Мое здоровье';
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)?.insert(_overlayEntry!);
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height),
          child: Material(
            elevation: 4.0,
            child: Container(
              padding: EdgeInsets.zero,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.items
                    .map((item) => InkWell(
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                            });
                            widget.onSelected(item);
                            _toggleDropdown();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_selectedItem == item)
                                  const Icon(
                                    Icons.check,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Row(
          children: [
            Text(
              _selectedItem,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Image.asset(
                'assets/arrow_down.png',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
