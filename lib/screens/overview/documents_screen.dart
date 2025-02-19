import 'package:flutter/material.dart';

class DocumentsScreen extends StatelessWidget {
  final String userId;

  const DocumentsScreen({super.key, required this.userId});

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
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDocumentItem(context, 'Справки'),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            _buildDocumentItem(context, 'Рецепты'),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            _buildDocumentItem(context, 'Заключения'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, String title) {
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
            onPressed: () {
              // Действие при нажатии на +
            },
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
