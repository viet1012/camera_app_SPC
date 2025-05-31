import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://192.168.122.15:1012";

  Future<dynamic> fetchPathData(String id) async {
    final url = Uri.parse('$baseUrl/api/req/path/$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = response.body;
        return data; // hoặc bạn có thể map vào model nếu đã có
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}
