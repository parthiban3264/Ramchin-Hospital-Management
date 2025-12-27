import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/consultation_service.dart';
import '../../../Services/testing&scanning_service.dart';
import './widgets/overview_widget.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final ConsultationService _consultationService = ConsultationService();
  final TestingScanningService _testingService = TestingScanningService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  late Future<void> _dashboardFuture;

  bool showToday = true;
  bool networkError = false;

  // Consultation
  int regToday = 0;
  int regOverall = 0;
  int pendingToday = 0;
  int pendingOverall = 0;
  int ongoingToday = 0;
  int ongoingOverall = 0;
  int completedToday = 0;
  int completedOverall = 0;
  int cancelToday = 0;
  int cancelOverall = 0;

  // Testing
  int testPendingToday = 0;
  int testPendingOverall = 0;
  int testOngoingToday = 0;
  int testOngoingOverall = 0;
  int testCompletedToday = 0;
  int testCompletedOverall = 0;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _dashboardFuture = _loadDashboardData();
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();

    hospitalName = prefs.getString('hospitalName') ?? "Unknown";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";

    setState(() {});
  }

  bool isToday(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;
    try {
      final formatter = DateFormat('yyyy-MM-dd hh:mm a');
      final date = formatter.parse(dateString);
      final now = DateTime.now();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      networkError = false;

      final consultation = await _consultationService.getAllConsultations();
      final testData = await _testingService.getAllTestingAndScanningData();

      final todayConsult = consultation
          .where((c) => isToday(c['createdAt']))
          .toList();
      final todayTest = testData.where((t) => isToday(t['createdAt'])).toList();

      // Consultation Today
      regToday = todayConsult.length;
      pendingToday = todayConsult.where((c) => c['status'] == 'pending').length;
      ongoingToday = todayConsult
          .where(
            (c) => c['status'] == 'ongoing' || c['status'] == 'endprocessing',
          )
          .length;
      completedToday = todayConsult
          .where((c) => c['status'] == 'completed')
          .length;
      cancelToday = todayConsult
          .where((c) => c['status'] == 'cancelled')
          .length;

      // Consultation Overall
      regOverall = consultation.length;
      pendingOverall = consultation
          .where((c) => c['status'] == 'pending')
          .length;
      ongoingOverall = consultation
          .where(
            (c) => c['status'] == 'ongoing' || c['status'] == 'endprocessing',
          )
          .length;
      completedOverall = consultation
          .where((c) => c['status'] == 'completed')
          .length;
      cancelOverall = consultation
          .where((c) => c['status'] == 'cancelled')
          .length;

      // Testing
      testPendingToday = todayTest
          .where((t) => t['status'] == 'pending')
          .length;
      testOngoingToday = todayTest
          .where((t) => t['status'] == 'ongoing')
          .length;
      testCompletedToday = todayTest
          .where((t) => t['status'] == 'completed')
          .length;

      testPendingOverall = testData
          .where((t) => t['status'] == 'pending')
          .length;
      testOngoingOverall = testData
          .where(
            (t) => t['status'] == 'ongoing' || t['status'] == 'endprocessing',
          )
          .length;
      testCompletedOverall = testData
          .where((t) => t['status'] == 'completed')
          .length;
    } catch (_) {
      networkError = true;
    }

    setState(() {});
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardFuture = _loadDashboardData();
              });
              await _dashboardFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHospitalCard(),
                  const SizedBox(height: 22),
                  modeButtons(),
                  const SizedBox(height: 20),

                  if (networkError) networkErrorCard(context),

                  buildSectionTitle(
                    context,
                    "Consultations (${showToday ? "Today" : "Overall"})",
                  ),
                  const SizedBox(height: 12),

                  buildGrid(context, [
                    metricBox(
                      "Registered",
                      showToday ? "$regToday" : "$regOverall",
                      Icons.person_add_alt_1_rounded,
                    ),
                    metricBox(
                      "Waiting",
                      showToday ? "$pendingToday" : "$pendingOverall",
                      Icons.pending_actions_outlined,
                    ),
                    metricBox(
                      "Consulting",
                      showToday ? "$ongoingToday" : "$ongoingOverall",
                      Icons.timelapse_rounded,
                    ),
                    metricBox(
                      "Completed",
                      showToday ? "$completedToday" : "$completedOverall",
                      Icons.verified_outlined,
                    ),
                    metricBox(
                      "Cancelled",
                      showToday ? "$cancelToday" : "$cancelOverall",
                      Icons.cancel_outlined,
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------
  // UI HELPERS
  // -------------------------------------------------------------------
  Widget modeButton(bool today, String label) {
    final bool active = today == showToday;

    return GestureDetector(
      onTap: () => setState(() => showToday = today),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: active ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: customGold, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : customGold,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget modeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        modeButton(true, "Today"),
        const SizedBox(width: 10),
        modeButton(false, "Overall"),
      ],
    );
  }

  Widget _buildHospitalCard() {
    final photoUrl = hospitalPhoto;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: photoUrl == null || photoUrl.isEmpty
                ? _buildPlaceholderAvatar()
                : Image.network(
                    photoUrl,
                    height: 65,
                    width: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderAvatar(),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  hospitalPlace ?? "",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      height: 65,
      width: 65,
      decoration: const BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.local_hospital, color: Colors.white),
    );
  }
}
