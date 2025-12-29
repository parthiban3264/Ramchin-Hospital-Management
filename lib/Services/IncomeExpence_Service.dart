import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class IncomeExpenseService {
  IncomeExpenseService();

  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();

    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  // Create Drawer
  Future<Map<String, dynamic>> createIncomeExpenseService(
    Map<String, dynamic> drawerData,
  ) async {
    final url = Uri.parse('$baseUrl/income_and_expense/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(drawerData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create drawer: ${response.body}');
    }
  }

  // Example to get all drawers
  Future<List<dynamic>> getIncomeExpenseService() async {
    final hospitalId = await getHospitalId();
    final url = Uri.parse('$baseUrl/income_and_expense/getAll/$hospitalId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch drawers: ${response.body}');
    }
  }
}
