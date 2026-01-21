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
import 'package:heartcraft/services/game_data_service.dart';
import 'package:provider/provider.dart';
import '../../view_models/character_view_model.dart';
import '../../view_models/edit_mode_view_model.dart';
import '../../theme/heartcraft_theme.dart';
import '../../models/character.dart';
import '../../widgets/character_portrait.dart';

/// View and edit character details
class CharacterTab extends StatelessWidget {
  const CharacterTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final characterViewModel = context.watch<CharacterViewModel>();
    final editMode = context.watch<EditModeViewModel>().editMode;
    final character = characterViewModel.currentCharacter;
    if (character == null) {
      return const Center(
        child: Text('No character selected'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCharacterInfoCard(
              context, character, characterViewModel, editMode),
          _buildDescriptionCard(
              context, character, characterViewModel, editMode),
          _buildBackgroundCard(
              context, character, characterViewModel, editMode),
          _buildConnectionsCard(
              context, character, characterViewModel, editMode),
        ],
      ),
    );
  }

  // Portrait, basic info e.g. name, class, level
  Widget _buildCharacterInfoCard(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPortrait(context, character, characterViewModel, editMode),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCharacterDetails(
                  context, character, characterViewModel, editMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    if (editMode) {
      return EditableCharacterPortrait(
        portraitPath: character.portraitPath,
        size: 80.0,
        refreshKey: characterViewModel.portraitRefreshKey,
        onPickFromGallery: () async {
          _portraitOperation(
            context,
            () async {
              await characterViewModel.updatePortraitFromGallery(context);
            },
            'Failed to update portrait',
          );
        },
        onTakePhoto: () async {
          _portraitOperation(
            context,
            () async {
              await characterViewModel.takePortraitPhoto(context);
            },
            'Failed to take photo',
          );
        },
        onRemove: () async {
          _portraitOperation(
            context,
            () async {
              await characterViewModel.removePortrait();
            },
            'Failed to remove portrait',
          );
        },
      );
    }

    return CharacterPortrait(
      portraitPath: character.portraitPath,
      size: 80.0,
      refreshKey: characterViewModel.portraitRefreshKey,
    );
  }

  Future<void> _portraitOperation(
    BuildContext context,
    Future<void> Function() op,
    String errorMessage,
  ) async {
    try {
      await op();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: HeartcraftTheme.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildCharacterDetails(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameAndPronouns(context, character, characterViewModel, editMode),
        if (editMode) ...[
          // Pronouns are split out below name, in edit mode
          const SizedBox(height: 12),
          _buildEditablePronouns(character, characterViewModel),
        ],
        if (!editMode) ...[
          const SizedBox(height: 12),
          _buildClassLevel(context, character),
        ],
      ],
    );
  }

  Widget _buildNameAndPronouns(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    if (editMode) {
      return TextFormField(
        initialValue: character.name,
        decoration: const InputDecoration(
          labelText: 'Character Name',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          characterViewModel.updateName(value);
        },
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            character.name.isEmpty ? 'Unnamed Character' : character.name,
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (character.pronouns != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '(${character.pronouns})',
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditablePronouns(
    Character character,
    CharacterViewModel characterViewModel,
  ) {
    return TextFormField(
      initialValue: character.pronouns ?? '',
      decoration: const InputDecoration(
        labelText: 'Pronouns',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        characterViewModel.updatePronouns(value.isNotEmpty ? value : null);
      },
    );
  }

  Widget _buildClassLevel(BuildContext context, Character character) {
    return Text(
      character.classLevelString,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: HeartcraftTheme.gold,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildDescriptionCard(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HeartcraftTheme.gold,
                    ),
              ),
              const SizedBox(height: 8),
              editMode
                  ? TextFormField(
                      initialValue: character.description ?? '',
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Describe your character...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        characterViewModel
                            .updateDescription(value.isNotEmpty ? value : null);
                      },
                    )
                  : Text(character.description ?? 'No description provided'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCard(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Background',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HeartcraftTheme.gold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildBackgroundContent(
                  context, character, characterViewModel, editMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundContent(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    final hasQuestionnaireAnswers =
        character.backgroundQuestionnaireAnswers.isNotEmpty;
    final hasGeneralBackground = character.background?.isNotEmpty == true;

    if (!hasQuestionnaireAnswers && !hasGeneralBackground) {
      if (editMode) {
        return TextFormField(
          initialValue: '',
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Character background notes...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            characterViewModel
                .updateBackground(value.isNotEmpty ? value : null);
          },
        );
      }
      return const Text('No background details provided');
    }

    final backgroundWidgets = <Widget>[];

    if (hasQuestionnaireAnswers) {
      backgroundWidgets.add(
        Text(
          'Background Questions:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
      backgroundWidgets.add(const SizedBox(height: 16));

      bool first = true;
      for (final entry in character.backgroundQuestionnaireAnswers.entries) {
        // TODO: allow adding new background questions in edit mode
        // Look up the background question text from its ID
        final questionText = context
            .read<GameDataService>()
            .backgroundQuestions[character.characterClass?.id]?[entry.key]
            ?.text;

        if (questionText != null) {
          if (!first) {
            backgroundWidgets.add(const SizedBox(height: 16));
          } else {
            first = false;
          }

          backgroundWidgets.add(
            Text(
              questionText,
              style: const TextStyle(height: 1.4, fontWeight: FontWeight.bold),
            ),
          );
          backgroundWidgets.add(const SizedBox(height: 4));

          if (editMode) {
            backgroundWidgets.add(
              TextFormField(
                initialValue: entry.value,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  characterViewModel.updateBackgroundQuestionAnswer(
                    entry.key,
                    value.isNotEmpty ? value : null,
                  );
                },
              ),
            );
          } else {
            backgroundWidgets.add(
              Text(
                entry.value,
                style: const TextStyle(height: 1.4),
              ),
            );
          }
        }
      }

      if (hasGeneralBackground || editMode) {
        backgroundWidgets.add(const SizedBox(height: 16));
      }
    }

    // Add general background notes
    if (hasGeneralBackground || editMode) {
      if (hasQuestionnaireAnswers) {
        backgroundWidgets.add(
          Text(
            'Additional Background Notes:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
        backgroundWidgets.add(const SizedBox(height: 8));
      }

      if (editMode) {
        backgroundWidgets.add(
          TextFormField(
            initialValue: character.background ?? '',
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Additional notes about your character...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              characterViewModel
                  .updateBackground(value.isNotEmpty ? value : null);
            },
          ),
        );
      } else if (hasGeneralBackground) {
        backgroundWidgets.add(Text(character.background!));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: backgroundWidgets,
    );
  }

  Widget _buildConnectionsCard(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connections',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                ),
                if (editMode)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _showAddConnectionDialog(context, characterViewModel);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (character.connections.isEmpty)
              const Text('No connections added')
            else
              _buildConnectionsList(character, characterViewModel, editMode),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsList(
    Character character,
    CharacterViewModel characterViewModel,
    bool editMode,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: character.connections.length,
      itemBuilder: (context, index) {
        final connection = character.connections[index];
        return ListTile(
          leading: const Icon(Icons.people),
          title: Text(connection),
          trailing: editMode
              ? IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    characterViewModel.removeConnection(connection);
                  },
                )
              : null,
        );
      },
    );
  }

  // TODO: make consistent with character creation
  void _showAddConnectionDialog(
    BuildContext context,
    CharacterViewModel viewModel,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Connection'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Connection',
              border: OutlineInputBorder(),
              hintText: 'E.g., "Raven - friend from the village"',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  viewModel.addConnection(text);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
