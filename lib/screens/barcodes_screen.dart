import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'table_method_screen.dart';
import 'medicine_search_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BarcodesScreen extends StatefulWidget {
  final String userId;
  final int courseId;
  const BarcodesScreen({Key? key, required this.userId, required this.courseId})
      : super(key: key);

  @override
  _BarcodesScreenState createState() => _BarcodesScreenState();
}

class _BarcodesScreenState extends State<BarcodesScreen> with WidgetsBindingObserver {
  late PostgreSQLConnection _conn;
  MobileScannerController? cameraController; // Делаем nullable
  bool isScanning = false;
  bool isTorchOn = false; // Состояние фонарика
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Добавляем наблюдатель за жизненным циклом
    _initializeDatabase();
    _initializeCamera();
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

  void _initializeCamera() {
    setState(() {
      cameraController = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: isTorchOn,
      );
    });
    cameraController?.start().then((_) {
      print('Camera started successfully');
    }).catchError((error) {
      print('Error starting camera: $error');
      Fluttertoast.showToast(msg: 'Ошибка запуска камеры: $error');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null) return;

    if (state == AppLifecycleState.resumed) {
      // При возвращении в приложение
      cameraController?.start().then((_) {
        print('Camera resumed');
      }).catchError((error) {
        print('Error resuming camera: $error');
      });
    } else if (state == AppLifecycleState.paused) {
      // При уходе из приложения
      cameraController?.stop().then((_) {
        print('Camera paused');
      }).catchError((error) {
        print('Error pausing camera: $error');
      });
    }
  }

  Future<void> _processScannedCode(String scannedCode) async {
    if (isScanning) {
      return;
    }
    setState(() => isScanning = true);

    try {
      final results = await _conn.query(
        'SELECT "Name" FROM "Medicines" WHERE "Barcodes" = @barcode',
        substitutionValues: {'barcode': int.parse(scannedCode)},
      );

      if (results.isNotEmpty) {
        final medicineName = results.first[0] as String;
        await cameraController?.stop();
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
          // После возврата с другого экрана
          _initializeCamera(); // Пересоздаём контроллер камеры
          setState(() => isScanning = false);
        });
      } else {
        await Future.delayed(const Duration(seconds: 2));
        _showNoMedicineFoundDialog();
      }
    } catch (e) {
      print('Error processing scanned code: $e');
      await Future.delayed(const Duration(seconds: 2));
      _showNoMedicineFoundDialog();
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      setState(() => isScanning = false);
    }
  }

 Future<void> _pickImageFromGallery() async {
  try {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      Fluttertoast.showToast(msg: 'Фото не выбрано');
      return;
    }

    // Используем MobileScannerController.analyzeImage для сканирования штрих-кода из файла
    final barcodeFound = await cameraController?.analyzeImage(image.path);
    final bool barcodeFoundBool = barcodeFound as bool? ?? false; // Приводим к bool
    if (!barcodeFoundBool) {
      Fluttertoast.showToast(msg: 'Штрих-код не найден на изображении');
    }
    // Если штрих-код найден, он будет обработан через onDetect в MobileScanner
  } catch (e) {
    Fluttertoast.showToast(
        msg: 'Ошибка при выборе или сканировании фото: $e');
  }
}

  // Метод для переключения фонарика
  void _toggleTorch() {
    try {
      cameraController?.toggleTorch();
      setState(() {
        isTorchOn = !isTorchOn;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Ошибка при переключении фонарика: $e');
    }
  }

  void _showNoMedicineFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Лекарство не найдено'),
        content: const Text(
            'Штрих-код не соответствует ни одному лекарству. Хотите найти вручную?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToMedicineSearch();
            },
            child: const Text('Найти вручную'),
          ),
        ],
      ),
    );
  }

  void _navigateToMedicineSearch() async {
  // Останавливаем камеру перед переходом
  await cameraController?.stop().then((_) {
    print('Camera stopped before navigation');
  }).catchError((error) {
    print('Error stopping camera: $error');
  });
  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MedicineSearchScreen(
        userId: widget.userId,
        courseId: widget.courseId,
      ),
    ),
  ).then((_) {
    _initializeCamera();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (cameraController != null)
            MobileScanner(
              controller: cameraController!,
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (!isScanning) {
                    await _processScannedCode(barcode.rawValue ?? '');
                  }
                }
              },
            )
          else
            const Center(child: CircularProgressIndicator()),
          // Иконка "назад" и заголовок
          Positioned(
            top: 40.0,
            left: 16.0,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/arrow_back_white.svg',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Отсканируйте штрих код',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Иконка thunder.svg в правом верхнем углу с переключением фонарика
          Positioned(
            top: 40.0,
            right: 16.0,
            child: InkWell(
              onTap: _toggleTorch, // Переключаем фонарик при нажатии
              child: SvgPicture.asset(
                'assets/thunder.svg',
                width: 20,
                height: 20,
                color: isTorchOn ? Colors.yellow : Colors.white, // Цвет иконки
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Наведите камеру на штрих-код препарата',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        child: ElevatedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: Image.asset(
                            'assets/photo.png',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF0B102B),
                          ),
                          label: Text(
                            'Выбрать из галереи',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF0B102B),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B102B),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: _navigateToMedicineSearch,
                          icon: SvgPicture.asset(
                            'assets/search.svg',
                            width: 28,
                            height: 28,
                          ),
                          label: Text(
                            'Найти вручную',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF0B102B),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B102B),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
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
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.stop().then((_) {
      print('Camera stopped in dispose');
    }).catchError((error) {
      print('Error stopping camera in dispose: $error');
    });
    cameraController?.dispose();
    _conn.close();
    super.dispose();
  }
}