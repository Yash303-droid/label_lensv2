import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanResult {
  final bool safe;
  final int riskScore;
  final String severity;
  final List<Issue> issues;
  final String healthImpact;
  final List<Alternative> alternatives;
  final String summary;
  final String productName;

  ScanResult({
    required this.safe,
    required this.riskScore,
    required this.severity,
    required this.issues,
    required this.healthImpact,
    required this.alternatives,
    required this.summary,
    required this.productName,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json, {String productName = 'Scanned Product'}) {
    return ScanResult(
      safe: json['safe'] ?? false,
      riskScore: json['riskScore'] ?? 0,
      severity: json['severity'] ?? 'unknown',
      issues: (json['issues'] as List<dynamic>?)?.map((e) => Issue.fromJson(e)).toList() ?? [],
      healthImpact: json['healthImpact'] ?? 'No health impact information available.',
      alternatives: (json['alternatives'] as List<dynamic>?)?.map((e) => Alternative.fromJson(e)).toList() ?? [],
      summary: json['summary'] ?? 'No summary available.',
      productName: productName,
    );
  }
}

class Issue {
  final String type;
  final String item;
  final String reason;

  Issue({required this.type, required this.item, required this.reason});

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      type: json['type'] ?? 'General',
      item: json['item'] ?? 'Unknown',
      reason: json['reason'] ?? 'No reason provided.',
    );
  }
}

class Alternative {
  final String name;
  final String reason;
  final String searchLink;

  Alternative({required this.name, required this.reason, required this.searchLink});

  factory Alternative.fromJson(Map<String, dynamic> json) {
    return Alternative(
      name: json['name'] ?? 'Unknown Alternative',
      reason: json['reason'] ?? 'No reason provided.',
      searchLink: json['searchLink'] ?? '',
    );
  }
}