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
import 'package:heartcraft/models/equipment.dart';
import 'package:heartcraft/utils/dialogs.dart';
import 'package:uuid/uuid.dart';
import '../theme/heartcraft_theme.dart';

class AddArmorScreen extends StatefulWidget {
  const AddArmorScreen({super.key, this.existingArmor});

  final Armor? existingArmor;

  @override
  AddArmorScreenState createState() => AddArmorScreenState();
}

class AddArmorScreenState extends State<AddArmorScreen> {
  String name = '';
  String feature = '';
  String majorDamageThreshold = '';
  String severeDamageThreshold = '';
  int? selectedBaseScore;
  int? selectedTier;
  bool isFormValid = false;
  bool editMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingArmor != null) {
      editMode = true;
      final armor = widget.existingArmor!;
      name = armor.name;
      feature = armor.feature;
      majorDamageThreshold = armor.majorDamageThreshold.toString();
      severeDamageThreshold = armor.severeDamageThreshold.toString();
      selectedBaseScore = armor.baseScore;
      selectedTier = armor.tier;

      isFormValid = true;
    }
  }

  void _checkFormValidity() {
    setState(() {
      final major = int.tryParse(majorDamageThreshold);
      final severe = int.tryParse(severeDamageThreshold);

      isFormValid = name.trim().isNotEmpty &&
          selectedTier != null &&
          major != null &&
          major > 0 &&
          severe != null &&
          severe > 0 &&
          severe > major &&
          selectedBaseScore != null;
    });
  }

  void _createAndReturnArmor() {
    if (isFormValid) {
      final armor = Armor(
        id: editMode
            ? widget.existingArmor!.id
            : 'custom_${Uuid().v4().substring(0, 8)}',
        name: name.trim(),
        majorDamageThreshold: int.parse(majorDamageThreshold),
        severeDamageThreshold: int.parse(severeDamageThreshold),
        baseScore: selectedBaseScore!,
        feature: feature.trim(),
        tier: selectedTier!,
        custom: true,
      );

      Navigator.of(context).pop(armor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showExitConfirmation(context, 'armor');
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Armor'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: isFormValid ? _createAndReturnArmor : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFormValid ? HeartcraftTheme.gold : Colors.grey,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                ),
                icon: Icon(isFormValid ? Icons.save : Icons.pending_actions),
                label: Text(
                  'Save Armor',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Armor Name',
                          border: OutlineInputBorder(),
                          hintText: 'Enter armor name',
                        ),
                        onChanged: (value) {
                          name = value;
                          _checkFormValidity();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<int>(
                        label: 'Tier',
                        value: selectedTier,
                        hint: 'Select Tier',
                        items: [1, 2, 3, 4],
                        itemLabel: (tier) => 'Tier $tier',
                        onChanged: (value) {
                          setState(() {
                            selectedTier = value;
                            _checkFormValidity();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Major Threshold',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: HeartcraftTheme.gold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Severe Threshold',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: HeartcraftTheme.gold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Base Score',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: HeartcraftTheme.gold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: majorDamageThreshold,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                majorDamageThreshold = value;
                                _checkFormValidity();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: severeDamageThreshold,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                severeDamageThreshold = value;
                                _checkFormValidity();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: HeartcraftTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedBaseScore,
                                  hint: const Text('Select'),
                                  isExpanded: true,
                                  dropdownColor: HeartcraftTheme.surfaceColor,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedBaseScore = value;
                                      _checkFormValidity();
                                    });
                                  },
                                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                                      .map((score) => DropdownMenuItem<int>(
                                            value: score,
                                            child: Text(score.toString()),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: feature,
                        decoration: const InputDecoration(
                          labelText: 'Feature (optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Special abilities or effects',
                        ),
                        onChanged: (value) {
                          feature = value;
                        },
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HeartcraftTheme.gold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: HeartcraftTheme.surfaceColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(hint),
              isExpanded: true,
              dropdownColor: HeartcraftTheme.surfaceColor,
              onChanged: onChanged,
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
