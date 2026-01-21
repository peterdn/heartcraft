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
import 'package:heartcraft/models/trait.dart';
import 'package:provider/provider.dart';
import '../../theme/heartcraft_theme.dart';
import '../../view_models/character_view_model.dart';
import '../../view_models/edit_mode_view_model.dart';

/// Displaying and editing character traits
class TraitsCard extends StatelessWidget {
  const TraitsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final characterViewModel = context.watch<CharacterViewModel>();
    final character = characterViewModel.currentCharacter;
    final editMode = context.watch<EditModeViewModel>().editMode;

    if (character == null) {
      return const Center(
        child: Text('No character selected'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: character.traits.entries.map((entry) {
                final trait = entry.key;
                final traitValue = entry.value;

                return _buildTraitTile(
                  context,
                  trait,
                  traitValue,
                  editMode,
                  (newValue) {
                    characterViewModel.updateTrait(trait, newValue);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitTile(
    BuildContext context,
    Trait trait,
    int value,
    bool editMode,
    Function(int) onValueChanged,
  ) {
    return SizedBox(
      width: 100,
      height: 104,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Trait name at the top
              Text(
                trait.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              Flexible(
                child: Center(
                  child: editMode
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value >= 0 ? '+$value' : '$value',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color:
                                        HeartcraftTheme.getTraitColorForValue(
                                            value),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: value > -5
                                      ? () => onValueChanged(value - 1)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                      color: value > -5
                                          ? Theme.of(context).iconTheme.color
                                          : Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: value < 5
                                      ? () => onValueChanged(value + 1)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: value < 5
                                          ? Theme.of(context).iconTheme.color
                                          : Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: HeartcraftTheme.getTraitColorForValue(value)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            value >= 0 ? '+$value' : '$value',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: HeartcraftTheme.getTraitColorForValue(
                                      value),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
