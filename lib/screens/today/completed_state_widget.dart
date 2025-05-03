import 'package:flutter/material.dart';

class CompletedStateWidget extends StatelessWidget {
  final VoidCallback onShowCompletedTasks;

  const CompletedStateWidget({super.key, required this.onShowCompletedTasks});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tablet_comp.png',
            width: 210,
            height: 210,
          ),
          const SizedBox(height: 12),
          Text(
            'Браво! Все задачи\nвыполнены',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: const Color(0xFF0B102B), 
                  fontWeight: FontWeight.w600, 
                ),
          ),
          const SizedBox(height: 12), 
          Text(
            'Здоровье под контролем, можете\nрасслабиться и насладиться моментом',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280), 
                ),
          ),
          const SizedBox(height: 24), 
          ElevatedButton(
            onPressed: onShowCompletedTasks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(25, 127, 242, 0.08),
              foregroundColor: const Color.fromRGBO(25, 127, 242, 1), 
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0), 
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ), 
              minimumSize: const Size(0, 48), 
            ),
            child: Text(
              'Показать выполненные задачи',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color.fromRGBO(25, 127, 242, 1), 
                    fontWeight: FontWeight.w600, 
                    fontSize: 16, 
                  ),
            ),
          ),
        ],
      ),
    );
  }
}