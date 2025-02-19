import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/add_lechenie/add_treatment_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tablet.png',
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 20),
          const Text(
            'На данном экране будет\nрасписание приема лекарств',
            style: TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Добавьте первое напоминание о приеме\nлекарства или процедуре',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: userId != null
                ? () => _navigateToAddTreatmentScreen(context, userId)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF197FF2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTreatmentScreen(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddTreatmentScreen(userId: userId)),
    );
  }
}
