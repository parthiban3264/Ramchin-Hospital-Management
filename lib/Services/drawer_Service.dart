import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class DrawerService {
  DrawerService();

  Future<String> getHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception('Hospital ID not found in storage');
    }
    return hospitalId;
  }

  // Create Drawer
  Future<Map<String, dynamic>> createDrawer(
    Map<String, dynamic> drawerData,
  ) async {
    final url = Uri.parse('$baseUrl/drawers/create');

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
  Future<List<dynamic>> getDrawers() async {
    final hospitalId = await getHospitalId();
    final url = Uri.parse('$baseUrl/drawers/getAll/$hospitalId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch drawers: ${response.body}');
    }
  }
}
