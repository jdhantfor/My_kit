import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'table_method_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'medicine_search_screen.dart';

class BarcodesScreen extends StatefulWidget {
  final String userId;
  final int courseId;
  const BarcodesScreen({Key? key, required this.userId, required this.courseId})
      : super(key: key);

  @override
  _BarcodesScreenState createState() => _BarcodesScreenState();
}

class _BarcodesScreenState extends State<BarcodesScreen> {
  late PostgreSQLConnection _conn;
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Разрешение на использование камеры отклонено')),
      );
    }
  }

  Future<void> _initializeDatabase() async {
    _conn = PostgreSQLConnection(
      '62.113.37.96',
      5432,
      'gorzdrav',
      username: 'postgres',
      password: 'Lissec123',
    );
    try {
      await _conn.open();
      Fluttertoast.showToast(msg: 'Connected to PostgreSQL database!');
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error connecting to PostgreSQL database: $e');
    }
  }

  Future<void> _processScannedCode(String scannedCode) async {
    if (isScanning) {
      return; // Если уже идет процесс сканирования, игнорируем новый код
    }
    setState(() => isScanning = true);

    try {
      final results = await _conn.query(
        'SELECT "Name" FROM "Medicines" WHERE "Barcodes" = @barcode',
        substitutionValues: {'barcode': int.parse(scannedCode)},
      );

      if (results.isNotEmpty) {
        final medicineName = results.first[0] as String;

        // Останавливаем камеру
        cameraController.stop();

        // Переходим на TableMethodScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableMethodScreen(
              name: medicineName,
              userId: widget.userId,
              courseId: widget.courseId,
            ),
          ),
        ).then((_) {
          // После возвращения с другого экрана возобновляем сканирование
          cameraController.start();
          setState(() => isScanning = false);
        });
      } else {
        // Если код не найден, добавляем задержку перед новым сканированием
        await Future.delayed(const Duration(seconds: 2));
        _showNoMedicineFoundDialog(); // Показываем диалог вместо перехода на MedicineSearchScreen
      }
    } catch (e) {
      print('Error processing scanned code: $e');
      await Future.delayed(const Duration(seconds: 2));
      _showNoMedicineFoundDialog(); // Показываем диалог вместо перехода на MedicineSearchScreen
    } finally {
      // Сбрасываем флаг через некоторое время
      await Future.delayed(const Duration(seconds: 2));
      setState(() => isScanning = false);
    }
  }

  // Новый метод для отображения диалога, если лекарство не найдено
  void _showNoMedicineFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Лекарство не найдено'),
        content: const Text('Штрих-код не соответствует ни одному лекарству. Хотите найти вручную?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              _navigateToMedicineSearch(); // Переходим на поиск вручную
            },
            child: const Text('Найти вручную'),
          ),
        ],
      ),
    );
  }

  void _navigateToMedicineSearch() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineSearchScreen(
          userId: widget.userId,
          courseId: widget.courseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (!isScanning) {
                  await _processScannedCode(barcode.rawValue ?? '');
                }
              }
            },
          ),
          Positioned(
            top: 40.0,
            left: 16.0,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  SizedBox(width: 8.0),
                  Text(
                    'Отсканируйте штрих код',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Наведите камеру на штрих-код препарата',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Логика для выбора из галереи
                          },
                          icon: const Icon(Icons.photo_library,
                              color: Color(0xFF0B102B)),
                          label: const Text('Выбрать из галереи',
                              style: TextStyle(color: Color(0xFF0B102B))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton.icon(
                          onPressed: _navigateToMedicineSearch,
                          icon: const Icon(Icons.search,
                              color: Color(0xFF0B102B)),
                          label: const Text('Найти вручную',
                              style: TextStyle(color: Color(0xFF0B102B))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _conn.close();
    super.dispose();
  }
}