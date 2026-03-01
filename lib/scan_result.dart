import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanResult {
  final String? id;
  final bool safe;
  final int riskScore;
  final String severity;
  final List<Verdict> verdicts;
  final String detailedExplanation;
  final List<Alternative> alternatives;
  final String summary;
  final String productName;

  ScanResult({
    this.id,
    required this.safe,
    required this.riskScore,
    required this.severity,
    required this.verdicts,
    required this.detailedExplanation,
    required this.alternatives,
    required this.summary,
    required this.productName,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json, {String productName = 'Scanned Product'}) {
    return ScanResult(
      id: json['scanId'] ?? json['_id'],
      safe: json['safe'] ?? false,
      riskScore: json['riskScore'] ?? 0,
      severity: json['severity'] ?? 'unknown',
      verdicts: (json['verdicts'] as List<dynamic>?)?.map((e) => Verdict.fromJson(e)).toList() ?? [],
      detailedExplanation: json['detailedExplanation'] ?? 'No explanation available.',
      alternatives: (json['alternatives'] as List<dynamic>?)?.map((e) => Alternative.fromJson(e)).toList() ?? [],
      summary: json['summary'] ?? 'No summary available.',
      productName: productName,
    );
  }
}

class Verdict {
  final String category;
  final String name;
  final String status;
  final String reason;

  Verdict({required this.category, required this.name, required this.status, required this.reason});

  factory Verdict.fromJson(Map<String, dynamic> json) {
    return Verdict(
      category: json['category'] ?? 'general',
      name: json['name'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      reason: json['reason'] ?? 'No reason provided.',
    );
  }
}

class Alternative {
  final String name;
  final String? brand;
  final String reason;
  final String searchLink;

  Alternative({required this.name, this.brand, required this.reason, required this.searchLink});

  factory Alternative.fromJson(Map<String, dynamic> json) {
    return Alternative(
      name: json['name'] ?? 'Unknown Alternative',
      brand: json['brand'],
      reason: json['reason'] ?? 'No reason provided.',
      searchLink: json['searchLink'] ?? '',
    );
  }
}