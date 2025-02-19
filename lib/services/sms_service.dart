import 'package:http/http.dart' as http;
import 'dart:convert';

class SmsService {
  static const String baseUrl =
      'https://lcab.smsint.ru/json/v1.0/sms/send/text';
  static const String apiToken =
      '4roqy6uo7zu8insuswns9ep1n37opnyxxmy2jth6irkgoi1y2ssclu7cz11x0vko'; // Замените на ваш токен

  Future<bool> sendSms(String phone, String message) async {
    try {
      final url = Uri.parse(baseUrl);
      print('Attempting to send SMS to $phone');
      print('Request URL: $baseUrl');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Token': apiToken, // Используем X-Token для авторизации
            },
            body: jsonEncode({
              "messages": [
                {
                  "recipient": phone, // Номер получателя
                  "text": message, // Текст сообщения
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Full API response: $jsonResponse');

        if (jsonResponse['success'] == true) {
          print('SMS sent successfully.');
          return true;
        } else {
          print('API error: ${jsonResponse['error']['descr']}');
          return false;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error details: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }
}
