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
import '../../view_models/character_creation_view_model.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Personal details step for character creation
class PersonalDetailsStep extends StatefulWidget {
  final CharacterCreationViewModel viewModel;

  const PersonalDetailsStep({super.key, required this.viewModel});

  @override
  PersonalDetailsStepState createState() => PersonalDetailsStepState();
}

class PersonalDetailsStepState extends State<PersonalDetailsStep> {
  late TextEditingController nameController;
  late TextEditingController pronounsController;
  late TextEditingController descriptionController;
  final connectionController = TextEditingController();
  late List<String> connections;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.viewModel.character.name);
    pronounsController =
        TextEditingController(text: widget.viewModel.character.pronouns ?? '');
    descriptionController = TextEditingController(
        text: widget.viewModel.character.description ?? '');
    connections = List<String>.from(widget.viewModel.character.connections);

    // Add listeners for auto-save
    nameController.addListener(_onTextChanged);
    pronounsController.addListener(_onTextChanged);
    descriptionController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // TODO: debounce saves like we do in background setp
    widget.viewModel.setPersonalDetails(
      name: nameController.text.trim(),
      pronouns:
          pronounsController.text.isNotEmpty ? pronounsController.text : null,
      description: descriptionController.text.isNotEmpty
          ? descriptionController.text
          : null,
      connections: connections,
    );
  }

  @override
  void dispose() {
    nameController.removeListener(_onTextChanged);
    pronounsController.removeListener(_onTextChanged);
    descriptionController.removeListener(_onTextChanged);

    nameController.dispose();
    pronounsController.dispose();
    descriptionController.dispose();
    connectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160, bottom: 16),
            wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HeartcraftTheme.gold,
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 20, wide: 24),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add the final touches to your character.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 14, wide: 16),
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: ResponsiveUtils.responsiveValue(
                context,
                narrow: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 16, top: 8),
                wide: const EdgeInsets.only(
                    left: 24, right: 24, bottom: 24, top: 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Character Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pronouns
                  TextField(
                    controller: pronounsController,
                    decoration: const InputDecoration(
                      labelText: 'Pronouns (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Appearance, notable features, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Connections
                  Text(
                    'Connections',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HeartcraftTheme.gold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add people or organizations your character has connections with.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Add connection form
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: connectionController,
                          decoration: const InputDecoration(
                            labelText: 'Connection',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = connectionController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              connections.add(text);
                              connectionController.clear();
                            });
                            _onTextChanged();
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Connections list
                  if (connections.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: connections.length,
                      itemBuilder: (context, index) {
                        final connection = connections[index];
                        return ListTile(
                          leading: const Icon(Icons.people),
                          title: Text(connection),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                connections.removeAt(index);
                              });
                              _onTextChanged();
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
