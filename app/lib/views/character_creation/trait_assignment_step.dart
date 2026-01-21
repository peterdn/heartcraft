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
import '../../view_models/character_creation_view_model.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Trait assignment step for character creation
class TraitAssignmentStep extends StatefulWidget {
  final CharacterCreationViewModel viewModel;

  const TraitAssignmentStep({super.key, required this.viewModel});

  @override
  TraitAssignmentStepState createState() => TraitAssignmentStepState();
}

class TraitAssignmentStepState extends State<TraitAssignmentStep> {
  static const double maxTraitWidgetWidth = 300;
  static const double gridSpacingX = 20;
  static const double gridSpacingY = 8;
  static const double maxDoubleColumnWidth =
      (maxTraitWidgetWidth * 2) + gridSpacingX;
  static const double columnGap = 10;

  // Available values to assign (starts with all values available)
  late final List<int> _availableTraitValues;

  // Current assignments (null means no value assigned)
  late final Map<Trait, int?> _traitAssignments;

  @override
  void initState() {
    super.initState();
    _traitAssignments = {
      for (Trait trait in Trait.values)
        trait: widget.viewModel.inProgressTraits[trait]
    };

    _initAvailableTraitValues();
  }

  void _initAvailableTraitValues() {
    _availableTraitValues =
        List.from(CharacterCreationViewModel.availableTraitValues);
    for (int? assignedValue in _traitAssignments.values) {
      if (assignedValue != null) {
        _availableTraitValues.remove(assignedValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160),
            wide: const EdgeInsets.symmetric(horizontal: 24.0),
          ),
          child: Text(
            'Assign character traits',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HeartcraftTheme.gold,
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 20, wide: 24),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
            padding: ResponsiveUtils.responsiveValue(
              context,
              narrow: const EdgeInsets.only(left: 16, right: 160),
              wide: const EdgeInsets.symmetric(horizontal: 24.0),
            ),
            child: Text(
              'Assign these values to your six traits: ${CharacterCreationViewModel.availableTraitValues.map((v) => v >= 0 ? '+$v' : '$v').join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveUtils.responsiveValue(context,
                        narrow: 14, wide: 16),
                  ),
            )),
        const SizedBox(height: 24),

        // Traits assignment
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: maxDoubleColumnWidth +
                      columnGap), // Allow space for 2 columns + gap
              child: _buildTraitList(),
            ),
          ),
        ),
      ],
    );
  }

  // Build the list/grid of trait cards
  Widget _buildTraitList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use 2 columns if width allows, otherwise 1 column
        final columnCount =
            constraints.maxWidth >= maxDoubleColumnWidth ? 2 : 1;
        final itemCount = Trait.values.length;

        Widget gridView = GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: gridSpacingX,
            mainAxisSpacing: gridSpacingY,
            childAspectRatio: 5.5,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => _buildTraitCard(Trait.values[index]),
        );

        // If single column, constrain width
        if (columnCount == 1) {
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxTraitWidgetWidth,
              child: gridView,
            ),
          );
        }

        return gridView;
      },
    );
  }

  // Build individual trait card: displays unique available
  // values in dropdown and a none/deselection option
  Widget _buildTraitCard(Trait trait) {
    final currentValue = _traitAssignments[trait];
    final hasValue = currentValue != null;

    final dropdownItems = _getAvailableDropdownItemsForTrait(trait);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasValue
            ? HeartcraftTheme.darkPrimaryPurple.withValues(alpha: 0.2)
            : HeartcraftTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasValue
              ? HeartcraftTheme.gold
              : HeartcraftTheme.darkPrimaryPurple,
          width: hasValue ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              trait.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButton<int?>(
              value: currentValue,
              isExpanded: true,
              underline: Container(),
              dropdownColor: HeartcraftTheme.cardBackgroundColor,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 16),
              alignment: AlignmentDirectional.centerEnd,
              items: dropdownItems,
              onChanged: (int? newValue) {
                _assignValue(trait, newValue);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<int?>> _getAvailableDropdownItemsForTrait(Trait trait) {
    final currentValue = _traitAssignments[trait];
    final hasValue = currentValue != null;

    final dropdownItems = <DropdownMenuItem<int?>>[];

    // Add "None" / deselection option
    dropdownItems.add(
      const DropdownMenuItem<int?>(
        value: null,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '—',
            style: TextStyle(
              color: HeartcraftTheme.secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );

    final allValues = <int>{};
    if (hasValue) {
      allValues.add(currentValue);
    }
    allValues.addAll(_availableTraitValues);

    final sortedValues = allValues.toList()..sort((a, b) => b.compareTo(a));

    for (int value in sortedValues) {
      dropdownItems.add(
        DropdownMenuItem<int?>(
          value: value,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value >= 0 ? '+$value' : '$value',
              style: TextStyle(
                color: HeartcraftTheme.getTraitColorForValue(value),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return dropdownItems;
  }

  void _assignValue(Trait trait, int? value) {
    setState(() {
      // If trait already has a value, return it to available values
      final currentValue = _traitAssignments[trait];
      if (currentValue != null) {
        _availableTraitValues.add(currentValue);
      }

      _traitAssignments[trait] = value;
      _availableTraitValues.remove(value);
      _availableTraitValues.sort((a, b) => b.compareTo(a));

      widget.viewModel.assignTraits(_traitAssignments);
    });
  }
}
