import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Добавлен импорт для SVG
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart'; // Предполагаю, что у тебя UserProvider здесь

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  Map<String, List<String>> documents = {
    'Справки': [],
    'Рецепты': [],
    'Заключения': [],
  };

  final String serverUrl = 'http://62.113.37.96:5001';
  bool isUploading = false;
  String? userId;

  // Максимальный размер файла: 20 МБ
  final int maxFileSize = 20 * 1024 * 1024;

  // Допустимые расширения файлов
  final Set<String> allowedExtensions = {
    '.pdf',
    '.txt',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Получаем userId из UserProvider
  Future<void> _loadUser() async {
    userId = Provider.of<UserProvider>(context, listen: false).userId;
    print('DocumentsScreen: userId = $userId');
    if (mounted) setState(() {});
  }

  // Проверка формата и размера файла
  bool _isFileValid(PlatformFile file) {
    String extension = file.extension?.toLowerCase() ?? '';
    if (!allowedExtensions.contains('.$extension')) {
      print('Недопустимый формат файла: $extension');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Недопустимый формат файла. Разрешены: PDF, TXT, DOC, DOCX, XLS, XLSX, JPG, JPEG, PNG, GIF, BMP'),
        ),
      );
      return false;
    }

    if (file.size > maxFileSize) {
      print(
          'Файл слишком большой: ${file.size} байт, максимум $maxFileSize байт');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл слишком большой, максимум 20 МБ')),
      );
      return false;
    }

    return true;
  }

  Future<void> _pickAndUploadFile(String category) async {
    try {
      if (userId == null) {
        print('userId не установлен');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('userId не установлен')),
        );
        return;
      }

      setState(() => isUploading = true);
      print('Пользователь $userId начал выбор файла для $category');

      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        print('Выбор файла отменён');
        setState(() => isUploading = false);
        return;
      }

      PlatformFile file = result.files.first;
      String fileName = file.name;
      String filePath = file.path!;
      print('Выбран файл: $fileName');

      if (!_isFileValid(file)) {
        setState(() => isUploading = false);
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/upload/$userId/$category'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      print('Отправляю файл: $fileName');
      var response = await request.send();
      print('Статус ответа: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Файл $fileName загружен');
        setState(() {
          documents[category]?.add(fileName);
          isUploading = false;
        });
      } else {
        print('Ошибка загрузки: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при загрузке файла')),
        );
        setState(() => isUploading = false);
      }
    } catch (e) {
      print('Исключение при загрузке: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
      setState(() => isUploading = false);
    }
  }

  void _navigateToFiles(BuildContext context, String category) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('userId не установлен')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilesScreen(
          category: category,
          serverUrl: serverUrl,
          userId: userId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text('Пожалуйста, установите userId'));
    }
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDocumentItem(
                    context, 'Справки', _pickAndUploadFile, _navigateToFiles),
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                _buildDocumentItem(
                    context, 'Рецепты', _pickAndUploadFile, _navigateToFiles),
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                _buildDocumentItem(context, 'Заключения', _pickAndUploadFile,
                    _navigateToFiles),
              ],
            ),
          ),
        ),
        if (isUploading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildDocumentItem(
    BuildContext context,
    String title,
    Function(String) onAdd,
    Function(BuildContext, String) onView,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          SvgPicture.asset('assets/docs.svg', width: 56, height: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add,
                color: Color.fromARGB(255, 189, 188, 188)),
            onPressed: () => onAdd(title),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/arrow_forward.svg',
              width: 20,
              height: 20,
            ),
            onPressed: () => onView(context, title),
          ),
        ],
      ),
    );
  }
}

class FilesScreen extends StatefulWidget {
  final String category;
  final String serverUrl;
  final String userId;

  const FilesScreen({
    Key? key,
    required this.category,
    required this.serverUrl,
    required this.userId,
  }) : super(key: key);

  @override
  _FilesScreenState createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<String> files = [];

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    try {
      var response = await http.get(
        Uri.parse('${widget.serverUrl}/list/${widget.userId}/${widget.category}'),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          files = List<String>.from(data['files']);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при получении списка файлов')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
    }
  }

  Future<void> _downloadAndOpenFile(String fileName) async {
    try {
      String fileUrl = '${widget.serverUrl}/download/${widget.userId}/${widget.category}/$fileName';
      var response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;
        File tempFile = File('$tempPath/$fileName');
        await tempFile.writeAsBytes(response.bodyBytes);
        await OpenFile.open(tempFile.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при скачивании файла')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Файлы - ${widget.category}'),
        leading: IconButton(
          icon: SvgPicture.asset('assets/arrow_back.svg'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          String fileName = files[index];
          return Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(fileName),
              onTap: () => _downloadAndOpenFile(fileName),
            ),
          );
        },
      ),
    );
  }
}
