import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/consultation_service.dart';
import '../../../Services/testing&scanning_service.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

class LabOverviewPage extends StatefulWidget {
  const LabOverviewPage({super.key});

  @override
  State<LabOverviewPage> createState() => _LabOverviewPageState();
}

class _LabOverviewPageState extends State<LabOverviewPage> {
  final ConsultationService _consultationService = ConsultationService();
  final TestingScanningService _testingService = TestingScanningService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  late Future<void> _dashboardFuture;
  bool isRetrying = false;
  String selectedMode = "today";

  int registered = 0;
  int pending = 0;
  int ongoing = 0;
  int completed = 0;

  int overallRegistered = 0;
  int overallPending = 0;
  int overallOngoing = 0;
  int overallCompleted = 0;

  int allTest = 0;
  int testPending = 0;
  int testOngoing = 0;
  int testCompleted = 0;
  int testCancelled = 0;

  int overallAllTest = 0;
  int overallTestPending = 0;
  int overallTestOngoing = 0;
  int overallTestCompleted = 0;
  int overallTestCancelled = 0;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _dashboardFuture = _loadDashboardData();
  }

  // ---------------- Responsive Helpers ----------------

  int getGridCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  double responsiveFont(
    double width,
    double mobile,
    double tablet,
    double web,
  ) {
    if (width >= 1200) return web;
    if (width >= 800) return tablet;
    return mobile;
  }

  // ---------------- Data ----------------

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
      final date = DateFormat('yyyy-MM-dd hh:mm a').parse(dateString);
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    final consultation = await _consultationService.getAllConsultations();
    final testing = await _testingService.getAllTestingAndScanningData();

    final todayConsultations = consultation
        .where((c) => isToday(c['createdAt']))
        .toList();
    final todayTesting = testing.where((t) => isToday(t['createdAt'])).toList();

    _countConsultations(todayConsultations, consultation);
    _countTesting(todayTesting, testing);
  }

  void _countConsultations(List today, List all) {
    registered = today.length;
    pending = all
        .where((c) => c['status'] == 'pending' && c['paymentStatus'] == true)
        .length;
    ongoing = all
        .where(
          (c) => c['status'] == 'ongoing' || c['status'] == 'endprocessing',
        )
        .length;
    completed = today.where((c) => c['status'] == 'completed').length;

    overallRegistered = all.length;
    overallPending = pending;
    overallOngoing = ongoing;
    overallCompleted = all.where((c) => c['status'] == 'completed').length;
  }

  void _countTesting(List today, List all) {
    allTest = today.length;
    testPending = all
        .where((t) => t['status'] == 'pending' && t['paymentStatus'] == true)
        .length;
    testOngoing = all
        .where(
          (t) => t['status'] == 'ongoing' || t['status'] == 'endprocessing',
        )
        .length;
    testCompleted = today.where((t) => t['status'] == 'completed').length;
    testCancelled = today.where((t) => t['status'] == 'cancelled').length;

    overallAllTest = all.length;
    overallTestPending = testPending;
    overallTestOngoing = testOngoing;
    overallTestCompleted = all.where((t) => t['status'] == 'completed').length;
    overallTestCancelled = all.where((t) => t['status'] == 'cancelled').length;
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
    setState(() {});
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return FutureBuilder(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: width > 800 ? 40 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildHospitalCard(),
                      const SizedBox(height: 20),
                      _modeButtons(),
                      const SizedBox(height: 20),
                      Text(
                        selectedMode == "today"
                            ? "Testing & Scanning (Today)"
                            : "Testing & Scanning (Overall)",
                        style: TextStyle(
                          fontSize: responsiveFont(width, 18, 20, 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGrid(width),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _modeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _modeButton("today", "Today"),
        const SizedBox(width: 10),
        _modeButton("overall", "Overall"),
      ],
    );
  }

  Widget _modeButton(String mode, String label) {
    final isActive = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: customGold),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : customGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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

  Widget _buildGrid(double width) {
    return GridView.count(
      crossAxisCount: getGridCount(width),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: width > 800 ? 1.4 : 1.25,
      children: [
        _metric(
          "All Test",
          selectedMode == "today" ? allTest : overallAllTest,
          Icons.all_inbox,
        ),
        _metric(
          "Waiting",
          selectedMode == "today" ? testPending : overallTestPending,
          Icons.science,
        ),
        _metric(
          "Ongoing",
          selectedMode == "today" ? testOngoing : overallTestOngoing,
          Icons.biotech,
        ),
        _metric(
          "Completed",
          selectedMode == "today" ? testCompleted : overallTestCompleted,
          Icons.check_circle,
        ),
        _metric(
          "Cancelled",
          selectedMode == "today" ? testCancelled : overallTestCancelled,
          Icons.cancel,
        ),
      ],
    );
  }

  Widget _metric(String title, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: customGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
