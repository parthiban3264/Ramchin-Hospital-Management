import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color royal = Color(0xFFBF955E);

class AdmissionDetailPage extends StatefulWidget {
  final Map admission;
  const AdmissionDetailPage({super.key, required this.admission});

  @override
  State<AdmissionDetailPage> createState() => _AdmissionDetailPageState();
}

class _AdmissionDetailPageState extends State<AdmissionDetailPage> {
  int? doctorId;
  int? nurseId;
  int? bedId;

  bool changeDoctor = false;
  bool changeNurse = false;
  bool changeBed = false;

  List doctors = [];
  List nurses = [];
  List beds = [];

  @override
  void initState() {
    super.initState();
    loadStaff();
    loadBeds();
  }

  Future<void> loadStaff() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final d = await http.get(Uri.parse("$baseUrl/admissions/$hospitalId/staff/doctors"));
    final n = await http.get(Uri.parse("$baseUrl/admissions/$hospitalId/staff/nurses"));
    setState(() {
      doctors = jsonDecode(d.body);
      nurses = jsonDecode(n.body);
    });
  }

  Future<void> loadBeds() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final res = await http.get(Uri.parse("$baseUrl/wards/all/$hospitalId"));
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;

    final List<Map<String, dynamic>> allBeds = [];

    for (final ward in data) {
      final List<dynamic> wardBeds = ward['beds'] ?? [];

      for (final bed in wardBeds) {
        allBeds.add({
          ...bed,
          'ward': ward,
        });
      }
    }


    final availableBeds =
    allBeds.where((b) => b['status'] == 'AVAILABLE').toList();

    final currentBed = allBeds.firstWhere(
          (b) => b['id'] == widget.admission['bedId'],
      orElse: () => {},
    );

    if (currentBed.isNotEmpty &&
        !availableBeds.any((b) => b['id'] == currentBed['id'])) {
      availableBeds.insert(0, currentBed);
    }

    setState(() {
      beds = availableBeds;
      bedId ??= widget.admission['bedId'];
    });

  }

  Future<void> saveChanges() async {
    if (!changeDoctor && !changeNurse && !changeBed) return;
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    try {
      final response = await http.patch(
        Uri.parse(
            "$baseUrl/admissions/${widget.admission['id']}/$hospitalId/change-assignment"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (changeDoctor && doctorId != null &&
              doctorId != widget.admission['doctorId']) 'doctorId': doctorId,
          if (changeNurse && nurseId != null &&
              nurseId != widget.admission['nurseId']) 'nurseId': nurseId,
          if (changeBed && bedId != null &&
              bedId != widget.admission['bedId']) 'newBedId': bedId,
        }),
      );

      if (response.statusCode == 200) {
        // Success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assignment updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Pop back and notify parent to refresh
        Navigator.pop(context, true);
      } else {
        // Show error
        if (!mounted) return;
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: ${error['message'] ?? response.reasonPhrase}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.admission;
    final p = a['patient'];

    doctorId ??= a['doctorId'];
    nurseId ??= a['nurseId'];

    final admitTime =
    DateTime.parse(a['admitTime']).toLocal().toString().substring(0, 16);

    final doctorName =
    a['doctor'] != null ? a['doctor']['name'] : "Not Assigned";

    final nurseName = nurses.isNotEmpty
        ? (nurses.firstWhere(
          (n) => n['id'] == a['nurseId'],
      orElse: () => null,
    )?['name'] ?? "Not Assigned")
        : "Loading...";


    final bedText =
        "Bed ${a['bed']['bedNo']} • ${a['bed']['ward']['name']}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: royal,
        title: const Text("Admission Details", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🆔 ADMISSION CARD
            _infoCard(
              title: "Admission Info",
              children: [
                _row("Admission ID", a['id'].toString()),
                _row("Status", a['status']),
                _row("Admitted On", admitTime),
              ],
            ),

            const SizedBox(height: 16),

            /// 👤 PATIENT CARD
            _infoCard(
              title: "Patient",
              children: [
                _row("Name", p['name']),
                _row("Mobile", p['phone']['mobile']),
              ],
            ),

            const SizedBox(height: 16),

            /// 👨‍⚕️ DOCTOR
            _editableCard(
              title: "Doctor",
              value: doctorName,
              changing: changeDoctor,
              onTap: () => setState(() => changeDoctor = !changeDoctor),
              child: _dropdown(
                hint: "Select Doctor",
                items: doctors,
                value: doctorId,
                onChanged: (v) => setState(() => doctorId = v),
              ),
            ),

            /// 👩‍⚕️ NURSE
            _editableCard(
              title: "Nurse",
              value: nurseName,
              changing: changeNurse,
              onTap: () => setState(() => changeNurse = !changeNurse),
              child: _dropdown(
                hint: "Select Nurse",
                items: nurses,
                value: nurseId,
                onChanged: (v) => setState(() => nurseId = v),
              ),
            ),

            /// 🛏 BED
            /// 🛏 BED
            if (beds.isNotEmpty)
              _editableCard(
                title: "Bed",
                value: bedText,
                changing: changeBed,
                onTap: () => setState(() => changeBed = !changeBed),
                child: DropdownButtonFormField<int>(
                  key: ValueKey(beds.length), // 🔥 FORCE REBUILD
                  value: changeBed ? bedId : null,
                  hint: const Text("Select Bed"),
                  items: beds.map<DropdownMenuItem<int>>((b) {
                    return DropdownMenuItem(
                      value: b['id'],
                      child: Text(
                        "Bed ${b['bedNo']} • ${b['ward']['name']}",
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => bedId = v),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),


            const SizedBox(height: 30),

            /// 💾 SAVE
            SizedBox(
              width: 180,   // full width
              height: 52,               // fixed height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: royal,        // background
                  foregroundColor: Colors.white, // text/icon color
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: saveChanges,
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// ================= UI HELPERS =================

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),side: BorderSide(color: royal)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: royal)),
            const Divider(color: royal,),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _editableCard({
    required String title,
    required String value,
    required bool changing,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),side: BorderSide(color: royal)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: royal)),
                TextButton(
                  onPressed: onTap,
                  child: Text(changing ? "Cancel" : "Change",style: TextStyle(color: royal),),
                ),
              ],
            ),
            Text(value,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            if (changing) ...[
              const SizedBox(height: 12),
              child,
            ]
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required List items,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      hint: Text(hint),
      items: items
          .map<DropdownMenuItem<int>>(
            (i) => DropdownMenuItem(
          value: i['id'],
          child: Text(i['name']),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
