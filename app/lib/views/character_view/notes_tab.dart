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
import 'package:provider/provider.dart';
import '../../view_models/character_view_model.dart';
import '../../view_models/edit_mode_view_model.dart';
import '../../theme/heartcraft_theme.dart';

/// Simple note-taking tab for character view
/// TODO: significantly imrpove with multi-note support etc
class NotesTab extends StatelessWidget {
  const NotesTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final characterViewModel = context.watch<CharacterViewModel>();
    final editMode = context.watch<EditModeViewModel>().editMode;
    final character = characterViewModel.currentCharacter;
    if (character == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: HeartcraftTheme.gold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: editMode
                          ? TextFormField(
                              initialValue: character.notes,
                              maxLines: null,
                              expands: true,
                              keyboardType: TextInputType.multiline,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                hintText: 'Add your notes here...',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                characterViewModel.updateNotes(value);
                              },
                            )
                          : SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  character.notes.isEmpty
                                      ? 'No notes added yet'
                                      : character.notes,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: character.notes.isEmpty
                                          ? Colors.grey
                                          : Colors.white),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
