// Copyright (c) 2025 Peter Nelson & Heartcraft contributors
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Website: https://heartcraft.app
// GitHub: https://github.com/peterdn/heartcraft
//
// Heartcraft is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Heartcraft is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

import 'package:flutter/material.dart';
import 'package:heartcraft/models/domain.dart';
import '../theme/heartcraft_theme.dart';

/// Card widget to display a domain card
/// Shows level, recall cost, domain, ability name, and description
/// TODO: combine with FeatureCard
class DomainCard extends StatelessWidget {
  final DomainAbility ability;
  final List<Domain> domains;
  final bool isSelected;
  final VoidCallback onTap;

  static const double width = 350.0;

  const DomainCard({
    super.key,
    required this.ability,
    required this.domains,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final domainName = domains
        .firstWhere((d) => d.id == ability.domain, orElse: () => domains[0])
        .name;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        child: Card(
          color: isSelected
              ? HeartcraftTheme.gold.withValues(alpha: 0.25)
              : Theme.of(context).cardColor,
          elevation: isSelected ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected
                ? const BorderSide(color: HeartcraftTheme.gold, width: 2)
                : BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Top row: Domain, Level, Recall
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildDomainLabel(context, domainName),
                    const SizedBox(width: 8),
                    _buildLevelLabel(context, ability.level),
                    const SizedBox(width: 8),
                    _buildRecallLabel(context, ability.recallCost),
                  ],
                ),
                const SizedBox(height: 8),
                // Ability name
                Text(
                  ability.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HeartcraftTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  ability.description ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDomainLabel(BuildContext context, String domainName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: HeartcraftTheme.gold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        domainName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HeartcraftTheme.darkPrimaryPurple,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLevelLabel(BuildContext context, int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Level $level',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HeartcraftTheme.darkPrimaryPurple,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildRecallLabel(BuildContext context, int recallCost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            'Recall:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HeartcraftTheme.darkPrimaryPurple,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            recallCost.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HeartcraftTheme.darkPrimaryPurple,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
