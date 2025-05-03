import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/services/subscription_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onNotificationsUpdated; // Callback для обновления

  const NotificationsScreen({
    super.key,
    required this.userEmail,
    this.onNotificationsUpdated,
  });

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> invitations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInvitations();
  }

  Future<void> fetchInvitations() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://62.113.37.96:5002/invitations?email=${widget.userEmail}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          invitations = data['invitations'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка загрузки приглашений: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> acceptInvitation(int inviteId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID пользователя не указан')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://62.113.37.96:5002/accept_invitation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'invite_id': inviteId,
          'email': widget.userEmail,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Приглашение принято')),
        );
        fetchInvitations();
        widget.onNotificationsUpdated?.call(); // Обновляем уведомления
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Ошибка принятия приглашения: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> declineInvitation(int inviteId) async {
    try {
      final response = await http.post(
        Uri.parse('http://62.113.37.96:5002/decline_invitation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'invite_id': inviteId,
          'email': widget.userEmail,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Приглашение отклонено')),
        );
        fetchInvitations();
        widget.onNotificationsUpdated?.call(); // Обновляем уведомления
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ошибка отклонения приглашения: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

 Future<void> _activateTestSubscription() async {
  final userId = await DatabaseService.getCurrentUserId();
  if (userId == null) {
    print('Пользователь не авторизован');
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://62.113.37.96:5002/activate_promo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'promo_code': 'Аптечка',
      }),
    );

    if (response.statusCode == 200) {
      print('Подписка успешно активирована на сервере');
      // Обновляем локально
      await DatabaseService.updateUserDetails(userId, subscribe: 1);
      await DatabaseService().syncWithServer(userId);
    } else {
      print('Ошибка активации подписки: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Ошибка при активации подписки: $e');
  }
}

  Widget _buildSubscriptionNotice() {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.subscribe) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Попробуйте функции семейной подписки!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Приглашайте членов семьи и управляйте их здоровьем вместе. '
            'Введите промокод "Аптечка" или подключите подписку прямо сейчас.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    ).then((_) {
                      setState(() {}); // Обновляем UI после возвращения
                      widget.onNotificationsUpdated?.call();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('Подключить'),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextButton(
                  onPressed: _activateTestSubscription,
                  child: const Text(
                    'Принять',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Уведомления',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSubscriptionNotice(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : invitations.isEmpty
                    ? const Center(
                        child: Text(
                          'Здесь пока нет уведомлений.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: invitations.length,
                        itemBuilder: (context, index) {
                          final invitation = invitations[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                'Приглашение от ${invitation['invited_by']}',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Создано: ${invitation['created_at']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () {
                                      acceptInvitation(invitation['id']);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      declineInvitation(invitation['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}