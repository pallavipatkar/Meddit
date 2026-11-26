import 'package:flutter/material.dart';

enum CommunityCategory { branch, club, campus }

class Community {
  final String id;
  final String name;
  final String handle;
  final String description;
  final CommunityCategory category;
  final String? branchKey;
  final int memberCount;
  final IconData icon;
  final Color accentColor;
  final bool isJoined;
  final List<String> rules;

  const Community({
    required this.id,
    required this.name,
    required this.handle,
    required this.description,
    required this.category,
    this.branchKey,
    required this.memberCount,
    required this.icon,
    required this.accentColor,
    required this.isJoined,
    required this.rules,
  });

  String get categoryLabel {
    switch (category) {
      case CommunityCategory.branch:
        return 'Branch';
      case CommunityCategory.club:
        return 'Student Club';
      case CommunityCategory.campus:
        return 'Campus Hub';
    }
  }

  Community copyWith({
    int? memberCount,
    bool? isJoined,
  }) {
    return Community(
      id: id,
      name: name,
      handle: handle,
      description: description,
      category: category,
      branchKey: branchKey,
      memberCount: memberCount ?? this.memberCount,
      icon: icon,
      accentColor: accentColor,
      isJoined: isJoined ?? this.isJoined,
      rules: rules,
    );
  }
}
