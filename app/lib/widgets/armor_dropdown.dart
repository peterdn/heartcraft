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
import '../models/equipment.dart';
import '../theme/heartcraft_theme.dart';

/// Dropdown widget for selecting armor
class ArmorDropdown extends StatelessWidget {
  final List<Armor> armor;
  final Armor? selectedArmor;
  final int maxTier;
  final Function(Armor?) onChanged;
  final bool isDisabled;
  final String? hintText;

  const ArmorDropdown({
    super.key,
    required this.armor,
    required this.selectedArmor,
    required this.maxTier,
    required this.onChanged,
    this.isDisabled = false,
    this.hintText = 'Select armor',
  });

  @override
  Widget build(BuildContext context) {
    // HACK: dummy armor to keep DropdownButton happy when no armor is selected
    var dummyHeaderValue = Armor(
        id: "",
        name: "",
        tier: 0,
        majorDamageThreshold: 0,
        severeDamageThreshold: 0,
        baseScore: 0,
        feature: "");

    return Container(
      height: null,
      decoration: BoxDecoration(
        color: HeartcraftTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Armor?>(
          value: armor.contains(selectedArmor) ? selectedArmor : null,
          isExpanded: true,
          dropdownColor: HeartcraftTheme.surfaceColor,
          itemHeight: null,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDisabled ? Colors.grey : HeartcraftTheme.gold,
          ),
          hint: hintText != null
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    hintText!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                )
              : null,
          onChanged: isDisabled ? null : onChanged,
          items: [
            DropdownMenuItem<Armor?>(
              value: null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'None selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ),
            // Group armor by tier
            for (int tier = 1; tier <= maxTier; tier++) ...[
              if (armor.any((a) => a.tier == tier)) ...[
                // Tier header
                DropdownMenuItem<Armor?>(
                  enabled: false,
                  value: dummyHeaderValue,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Tier $tier',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: HeartcraftTheme.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                // Armor items for this tier
                ...armor.where((a) => a.tier == tier).map(
                      (armorItem) => DropdownMenuItem<Armor?>(
                        value: armorItem,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                armorItem.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: armorItem.custom
                                          ? HeartcraftTheme.lightPurple
                                          : Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Score: ${armorItem.baseScore} • Thresholds: ${armorItem.baseThresholds}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[400],
                                    ),
                              ),
                              if (armorItem.feature.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  armorItem.feature,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[300],
                                        fontStyle: FontStyle.italic,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ]
          ],
        ),
      ),
    );
  }
}
