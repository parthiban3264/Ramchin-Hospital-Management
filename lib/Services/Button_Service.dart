import 'dart:convert';

import 'package:http/http.dart' as http;

// import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class ButtonPermissionService {
  /// Fetch all button permissions by hospital_Id
  Future<List<dynamic>> getAllByHospital() async {
    // final prefs = await SharedPreferences.getInstance();
    //
    // final hospitalId = prefs.getString( 'hospitalId');
    final url = Uri.parse("$baseUrl/button-permissions/getAll");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Failed to load button permissions. Status: ${response.statusCode}",
      );
    }
  }
}
