import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';

class DocumentsScreen extends StatefulWidget {
  final String userId;
  const DocumentsScreen({super.key, required this.userId});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}
class _DocumentsScreenState extends State<DocumentsScreen> {
  Map<String, List<String>> documents = {
    'Справки': [],
    'Рецепты': [],
    'Заключения': [],
  };

  final String serverUrl = 'http://62.113.37.96:5000';
  bool isUploading = false;

  Future<void> _pickAndUploadFile(String category) async {
    setState(() {
      isUploading = true;
    });
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile file = result.files.first;
      String fileName = file.name;
      String filePath = file.path!;

      print('Начинаю загрузку файла: $fileName');
      var request = http.MultipartRequest('POST', Uri.parse('$serverUrl/upload/$category'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      print('Статус ответа сервера: ${response.statusCode}');
      setState(() {
        isUploading = false;
      });
      if (response.statusCode == 200) {
        print('Файл успешно загружен: $fileName');
        setState(() {
          documents[category]?.add(fileName);
        });
      } else {
        print('Ошибка при загрузке: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке файла')),
        );
      }
    } else {
      setState(() {
        isUploading = false;
      });
      print('Выбор файла отменён');
    }
  }

  void _navigateToFiles(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilesScreen(category: category, serverUrl: serverUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5)
              ],
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
                _buildDocumentItem(
                    context, 'Заключения', _pickAndUploadFile, _navigateToFiles),
              ],
            ),
          ),
        ),
        if (isUploading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
  Widget _buildDocumentItem(BuildContext context, String title,
      Function(String) onAdd, Function(BuildContext, String) onView) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          Image.asset('assets/doc.png', width: 56, height: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.grey),
            onPressed: () => onAdd(title),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onPressed: () => onView(context, title),
          ),
        ],
      ),
    );
  }

class FilesScreen extends StatefulWidget {
  final String category;
  final String serverUrl;

  const FilesScreen({Key? key, required this.category, required this.serverUrl})
      : super(key: key);

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
    print('Получаю список файлов для категории: ${widget.category}');
    var response = await http.get(Uri.parse('${widget.serverUrl}/list/${widget.category}'));
    print('Статус ответа: ${response.statusCode}');
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('Получен список файлов: ${data['files']}');
      setState(() {
        files = List<String>.from(data['files']);
      });
    } else {
      print('Ошибка при получении списка: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при получении списка файлов')),
      );
    }
  }

  Future<void> _downloadAndOpenFile(String fileName) async {
    String fileUrl = '${widget.serverUrl}/download/${widget.category}/$fileName';
    print('Скачиваю файл: $fileName с URL: $fileUrl');
    var response = await http.get(Uri.parse(fileUrl));
    print('Статус скачивания: ${response.statusCode}');
    if (response.statusCode == 200) {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      File tempFile = File('$tempPath/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);
      print('Файл скачан и сохранён: $fileName');
      await OpenFile.open(tempFile.path);
      print('Файл открыт: $fileName');
    } else {
      print('Ошибка при скачивании: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при скачивании файла')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Файлы - ${widget.category}'),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          String fileName = files[index];
          return ListTile(
            title: Text(fileName),
            onTap: () => _downloadAndOpenFile(fileName),
          );
        },
      ),
    );
  }
}
