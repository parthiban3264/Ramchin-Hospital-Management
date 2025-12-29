import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// COLORS
/// ---------------------------------------------------------------------------
const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

/// ---------------------------------------------------------------------------
/// TEXT STYLES
/// ---------------------------------------------------------------------------
const TextStyle sectionTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle cardTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

const TextStyle cardValueStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

/// ---------------------------------------------------------------------------
/// NETWORK ERROR CARD
/// ---------------------------------------------------------------------------
Widget networkErrorCard(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  return Container(
    padding: EdgeInsets.all(width > 600 ? 18 : 14),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade300),
    ),
    child: Row(
      children: const [
        Icon(Icons.wifi_off_rounded, color: Colors.red),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Network error! Unable to load data.",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

/// ---------------------------------------------------------------------------
/// SECTION TITLE
/// ---------------------------------------------------------------------------
Widget buildSectionTitle(BuildContext context, String title) {
  final width = MediaQuery.of(context).size.width;

  return Center(
    child: Text(
      title,
      style: sectionTitleStyle.copyWith(fontSize: width > 800 ? 20 : 18),
    ),
  );
}

/// ---------------------------------------------------------------------------
/// RESPONSIVE GRID
/// ---------------------------------------------------------------------------
Widget buildGrid(BuildContext context, List<Widget> cards) {
  final width = MediaQuery.of(context).size.width;

  int crossAxisCount;
  double childAspectRatio;

  if (width >= 1200) {
    crossAxisCount = 4; // Web / Desktop
    childAspectRatio = 1.4;
  } else if (width >= 800) {
    crossAxisCount = 3; // Tablets
    childAspectRatio = 1.3;
  } else {
    crossAxisCount = 2; // Phones
    childAspectRatio = 1.25;
  }

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: cards.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
    ),
    itemBuilder: (context, index) => cards[index],
  );
}

/// ---------------------------------------------------------------------------
/// METRIC CARD
/// ---------------------------------------------------------------------------
Widget metricBox(String title, String value, IconData icon) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final bool isSmall = constraints.maxWidth < 160;

      return Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, 5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: customGold, size: isSmall ? 22 : 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cardTitleStyle.copyWith(fontSize: isSmall ? 13 : 15),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Text(
                value,
                style: cardValueStyle.copyWith(fontSize: isSmall ? 22 : 26),
              ),
            ),
          ],
        ),
      );
    },
  );
}
