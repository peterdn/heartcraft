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

/// Dropdown widget for selecting weapons
class WeaponDropdown extends StatelessWidget {
  final List<Weapon> weapons;
  final Weapon? selectedWeapon;
  final int maxTier;
  final Function(Weapon?) onChanged;
  final bool isDisabled;
  final String? hintText;

  const WeaponDropdown({
    super.key,
    required this.weapons,
    required this.selectedWeapon,
    required this.maxTier,
    required this.onChanged,
    this.isDisabled = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    // HACK: dummy weapon to keep DropdownButton happy when no weapon is selected
    var dummyHeaderValue = Weapon(
        id: "",
        name: "",
        trait: "",
        range: "",
        damage: "",
        burden: WeaponBurden.unknown,
        feature: "",
        type: "",
        tier: 0);

    return Container(
      height: null,
      decoration: BoxDecoration(
        color: HeartcraftTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Weapon?>(
          value: weapons.contains(selectedWeapon) ? selectedWeapon : null,
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
            DropdownMenuItem<Weapon?>(
              value: null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  'None selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ),
            for (int tier = 1; tier <= maxTier; tier++) ...[
              for (String type in ["physical", "magic"]) ...[
                if (weapons.any((w) => w.tier == tier && w.type == type)) ...[
                  DropdownMenuItem<Weapon?>(
                    enabled: false,
                    value: dummyHeaderValue,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Tier $tier $type',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: HeartcraftTheme.gold,
                                ),
                      ),
                    ),
                  ),
                  ...weapons.where((w) => w.tier == tier && w.type == type).map(
                        (weapon) => DropdownMenuItem<Weapon?>(
                          value: weapon,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  weapon.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: HeartcraftTheme.primaryTextColor,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${weapon.trait} • ${weapon.range} • ${weapon.damage} • ${weapon.burden.displayName}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[400],
                                      ),
                                ),
                                if (weapon.feature.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    weapon.feature,
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
                      )
                ]
              ]
            ]
          ],
        ),
      ),
    );
  }
}
