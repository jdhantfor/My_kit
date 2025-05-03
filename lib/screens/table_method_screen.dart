import 'package:flutter/material.dart';
import 'table_time_screen.dart';
import '/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TableMethodScreen extends StatefulWidget {
  final String name;
  final String userId;
  final int courseId;

  const TableMethodScreen({
    super.key,
    required this.name,
    required this.userId,
    required this.courseId,
  });

  @override
  _TableMethodScreenState createState() => _TableMethodScreenState();
}

class _TableMethodScreenState extends State<TableMethodScreen> {
  String? _selectedUnit;

  // Настраиваемые отступы
  final double horizontalPadding = 16.0;
  final double verticalPadding = 12.0;
  final double containerLeftPadding = 4.0;
  final double dividerHorizontalPadding = 16.0;
  final double listTileVerticalPadding = 0.0;
  final double iconSize = 20.0;
  final double appBarTopPadding = 40.0;
  final double appBarTitleSpacing = 8.0;

  static const _measurementUnits = [
    'Таблетки',
    'Капсулы',
    'Миллилитры (мл)',
    'Миллиграммы (мг)',
    'Граммы (г)',
    'Капли',
    'Дозы',
    'Ампулы',
    'Международные единицы (МЕ)',
    'Чайные ложки (ч.л.)',
    'Столовые ложки (ст.л.)',
    'Флаконы',
    'Применения',
  ];

  @override
  Widget build(BuildContext context) {
    print('TableMethodScreen: build started');
    print('TableMethodScreen: widget.name: ${widget.name}');
    print('TableMethodScreen: widget.userId: ${widget.userId}');
    print('TableMethodScreen: widget.courseId: ${widget.courseId}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: appBarTopPadding,
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      print('TableMethodScreen: Back button pressed');
                      Navigator.pop(context);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/arrow_back.svg',
                          width: iconSize + 4,
                          height: iconSize + 4,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        SizedBox(width: appBarTitleSpacing),
                        Text(
                          'Единица измерения препарата',
                          style: Theme.of(context).textTheme.bodyLarge ??
                              const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: verticalPadding),
            // Список единиц измерения
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 4, right: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8), // Добавляем вертикальный отступ 8
                  child: ListView.separated(
                    itemCount: _measurementUnits.length,
                    itemBuilder: (context, index) {
                      final unit = _measurementUnits[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                        title: Text(
                          unit,
                          style: Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle(fontSize: 16),
                        ),
                        trailing: _selectedUnit == unit
                            ? const Icon(Icons.arrow_forward_ios_outlined,
                                color: AppColors.primaryBlue,
                              )
                            : SvgPicture.asset(
                                'assets/arrow_forward.svg',
                                width: iconSize,
                                height: iconSize,
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color ??
                                    Colors.black,
                              ),
                        onTap: () {
                          print('TableMethodScreen: Unit selected: $unit');
                          setState(() {
                            _selectedUnit = unit;
                          });
                          if (_selectedUnit != null) {
                            print(
                                'TableMethodScreen: Navigating to TableTimeScreen with unit: $_selectedUnit');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TableTimeScreen(
                                  name: widget.name,
                                  unit: _selectedUnit!,
                                  userId: widget.userId,
                                  courseId: widget.courseId,
                                ),
                              ),
                            );
                          } else {
                            print(
                                'TableMethodScreen: _selectedUnit is null, navigation aborted');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Пожалуйста, выберите единицу измерения')),
                            );
                          }
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: AppColors.fieldBackground,
                          thickness: 1,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
