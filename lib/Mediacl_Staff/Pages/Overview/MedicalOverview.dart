import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/payment_service.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

class MedicalOverviewPage extends StatefulWidget {
  const MedicalOverviewPage({super.key});

  @override
  State<MedicalOverviewPage> createState() => _MedicalOverviewPageState();
}

class _MedicalOverviewPageState extends State<MedicalOverviewPage> {
  final PaymentService _paymentService = PaymentService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;

  late Future<void> _dashboardFuture;
  bool showToday = true;
  bool isRetrying = false;

  int totalPendingPayments = 0;
  int overAllPendingPayments = 0;
  int totalPaidToday = 0;
  int totalPaidOverall = 0;

  int testingFeeToday = 0;
  int testingFeeOverall = 0;

  int manualPayToday = 0;
  int manualPayOverall = 0;

  int onlinePayToday = 0;
  int onlinePayOverall = 0;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _dashboardFuture = _loadDashboardData();
  }

  // ---------------- RESPONSIVE HELPERS ----------------

  int gridCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  double font(double width, double m, double t, double w) {
    if (width >= 1200) return w;
    if (width >= 800) return t;
    return m;
  }

  // ---------------- DATA ----------------

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    hospitalName = prefs.getString('hospitalName') ?? "Unknown";
    hospitalPlace = prefs.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        prefs.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    setState(() {});
  }

  bool isToday(String? date) {
    if (date == null) return false;
    try {
      final d = DateFormat('yyyy-MM-dd hh:mm a').parse(date);
      final n = DateTime.now();
      return d.year == n.year && d.month == n.month && d.day == n.day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadDashboardData() async {
    final payments = await _paymentService.getAllPayments();

    final valid = payments.where(
      (p) => p['type'].toString().toUpperCase() == 'MEDICINETONICINJECTIONFEES',
    );

    final today = valid.where((p) => isToday(p['createdAt'])).toList();
    final paidToday = today.where((p) => p['status'] == 'PAID').toList();
    final paidOverall = valid.where((p) => p['status'] == 'PAID').toList();

    setState(() {
      totalPendingPayments = today
          .where((p) => p['status'] == 'PENDING')
          .length;
      overAllPendingPayments = valid
          .where((p) => p['status'] == 'PENDING')
          .length;

      totalPaidToday = paidToday.length;
      totalPaidOverall = paidOverall.length;

      testingFeeToday = paidToday.length;
      testingFeeOverall = paidOverall.length;

      manualPayToday = paidToday
          .where((p) => p['paymentType'] == 'MANUALPAY')
          .length;
      manualPayOverall = paidOverall
          .where((p) => p['paymentType'] == 'MANUALPAY')
          .length;

      onlinePayToday = paidToday
          .where((p) => p['paymentType'] == 'ONLINEPAY')
          .length;
      onlinePayOverall = paidOverall
          .where((p) => p['paymentType'] == 'ONLINEPAY')
          .length;
    });
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
                onRefresh: () async {
                  setState(() {
                    _dashboardFuture = _loadDashboardData();
                  });
                  await _dashboardFuture;
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: width > 800 ? 40 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildHospitalCard(),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _toggle(
                            "Today",
                            showToday,
                            () => setState(() => showToday = true),
                          ),
                          const SizedBox(width: 16),
                          _toggle(
                            "Overall",
                            !showToday,
                            () => setState(() => showToday = false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "Medical Overview (${showToday ? 'Today' : 'Overall'})",
                        style: TextStyle(
                          fontSize: font(width, 18, 20, 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: gridCount(width),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: width > 800 ? 1.4 : 1.25,
                        children: [
                          _metric(
                            "Pending",
                            showToday
                                ? totalPendingPayments
                                : overAllPendingPayments,
                            Icons.pending_actions_outlined,
                            width,
                          ),
                          _metric(
                            "Paid",
                            showToday ? totalPaidToday : totalPaidOverall,
                            Icons.verified_outlined,
                            width,
                          ),
                          _metric(
                            "Prescription Fees",
                            showToday ? testingFeeToday : testingFeeOverall,
                            Icons.biotech_rounded,
                            width,
                          ),
                          _metric(
                            "Manual Pay",
                            showToday ? manualPayToday : manualPayOverall,
                            Icons.payments,
                            width,
                          ),
                          _metric(
                            "Online Pay",
                            showToday ? onlinePayToday : onlinePayOverall,
                            Icons.phone_iphone,
                            width,
                          ),
                        ],
                      ),
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

  // ---------------- COMPONENTS ----------------

  Widget _toggle(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: active ? customGold : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: customGold),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : customGold,
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

  Widget _metric(String title, int value, IconData icon, double width) {
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
              Icon(icon, color: customGold, size: width > 800 ? 32 : 26),
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
              style: TextStyle(
                fontSize: font(width, 24, 28, 32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
