import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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

  Future<void> _pickAndSaveFile(String category) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile file = result.files.first;

      // Получаем директорию приложения
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File newFile = File(
          '${appDocDir.path}/${category}_${DateTime.now().millisecondsSinceEpoch}${file.extension}');

      // Копируем файл
      await File(file.path!).copy(newFile.path);

      setState(() {
        documents[category]?.add(newFile.path);
      });
    }
  }

  void _navigateToFiles(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilesScreen(files: documents[category] ?? []),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                context, 'Справки', _pickAndSaveFile, _navigateToFiles),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            _buildDocumentItem(
                context, 'Рецепты', _pickAndSaveFile, _navigateToFiles),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            _buildDocumentItem(
                context, 'Заключения', _pickAndSaveFile, _navigateToFiles),
          ],
        ),
      ),
    );
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
}

class FilesScreen extends StatelessWidget {
  final List<String> files;

  const FilesScreen({Key? key, required this.files}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Файлы'),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(files[index].split('/').last),
            onTap: () async {
              // Открытие файла
              // Можно использовать package:open_file/open_file.dart для открытия файла
            },
          );
        },
      ),
    );
  }
}
