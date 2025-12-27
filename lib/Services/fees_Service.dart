import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class FeesService {
  //---------------- CREATE ----------------//
  Future createFee(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/fees/create'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(res.body);
  }

  //---------------- GET ALL ----------------//
  Future<List<dynamic>> getAllFees() async {
    final res = await http.get(Uri.parse('$baseUrl/all'));
    return jsonDecode(res.body);
  }

  //---------------- GET BY HOSPITAL ID ----------------//
  Future<List<dynamic>> getFeesByHospital() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    if (hospitalId == null) return [];

    final res = await http.get(Uri.parse("$baseUrl/fees/all/$hospitalId"));

    return jsonDecode(res.body);
  }

  //---------------- GET BY HOSPITAL (DEBUG SAFE) ----------------//
  Future<List<dynamic>> getFeesByHospitals() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    if (hospitalId == null) return [];

    final url = "$baseUrl/fees/all/$hospitalId";
    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch fees");
    }

    return jsonDecode(res.body);
  }

  //---------------- GET BY ID ----------------//
  Future<Map<String, dynamic>> getFeeById(int id) async {
    final res = await http.get(Uri.parse("$baseUrl/fees/getById/$id"));

    return jsonDecode(res.body);
  }

  //---------------- UPDATE ----------------//
  Future updateFee(int id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/fees/updateById/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(res.body);
  }

  //---------------- DELETE ----------------//
  Future deleteFee(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl/fees/deleteById/$id"));

    return jsonDecode(res.body);
  }
}
