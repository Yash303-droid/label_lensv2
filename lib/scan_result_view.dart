import 'package:flutter/material.dart';
import 'package:label_lensv2/scan_result.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanResultView extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final ScanResult result;

  const ScanResultView({Key? key, this.onBackPressed, required this.result}) : super(key: key);

  // Color Palette (Strictly followed)
  static const Color appBg = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color dangerHeaderBg = Color(0xFFFF4B82);
  static const Color dangerText = Color(0xFFFF4B82);
  static const Color successText = Color(0xFF28C76F);
  static const Color betterOptionsCardBg = Color(0xFF064E3B);
  static const Color betterOptionsText = Color(0xFF34D399);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildVerdictsSection(),
                  if (result.alternatives.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildBetterOptionsSection(),
                  ],
                  const SizedBox(height: 40), // Bottom spacing
                ],
              ),
            ),
          ),
          _buildStickyBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final headerColor = result.safe ? successText : dangerHeaderBg;
    final icon = result.safe ? Icons.check : Icons.close;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Circular Score
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                  ],
                ),
                child: Center(
                  child: Text(
                    "${result.riskScore} / 100",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.severity.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // X Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          // Product Name
          Text(
            result.productName.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.description_outlined, color: textPrimary),
              SizedBox(width: 10),
              Text(
                "SUMMARY",
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.summary,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictsSection() {
    // Group verdicts by category
    final Map<String, List<Verdict>> grouped = {};
    for (var v in result.verdicts) {
      final category = v.category.toLowerCase();
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(v);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.fact_check_outlined, color: textPrimary),
            SizedBox(width: 10),
            Text(
              "VERDICTS",
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (grouped.isEmpty)
          _buildCheckCard(
            title: "ALL CLEAR",
            description: "No issues found.",
            isSafe: true,
          )
        else
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...entry.value.map((verdict) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildCheckCard(
                        title: verdict.name.toUpperCase(),
                        description: verdict.reason,
                        isSafe: verdict.status == 'safe',
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildCheckCard({required String title, required String description, required bool isSafe}) {
    final color = isSafe ? successText : dangerText;
    final icon = isSafe ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetterOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.arrow_forward, color: textPrimary),
            SizedBox(width: 10),
            Text(
              "BETTER OPTIONS",
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...result.alternatives.map((alt) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildOptionCard(
                name: alt.name,
                description: alt.reason,
                brand: alt.brand,
                searchLink: alt.searchLink,
              ),
            )),
      ],
    );
  }

  Widget _buildOptionCard({required String name, String? brand, required String description, required String searchLink}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: betterOptionsCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: betterOptionsText,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          if (brand != null && brand.isNotEmpty) ...[
            Text(
              "BY ${brand.toUpperCase()}",
              style: TextStyle(
                color: betterOptionsText.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              if (searchLink.isNotEmpty) {
                final Uri uri = Uri.parse(searchLink);
                if (!await launchUrl(uri)) {
                  debugPrint('Could not launch $searchLink');
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: betterOptionsText, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search, color: betterOptionsText, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "FIND THIS PRODUCT",
                    style: TextStyle(
                      color: betterOptionsText,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: appBg,
        border: Border(
          top: BorderSide(color: cardBg, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.bookmark_border,
              label: "SAVE",
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.share_outlined,
              label: "SHARE",
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}