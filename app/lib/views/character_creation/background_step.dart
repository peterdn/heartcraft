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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heartcraft/models/character.dart';
import '../../view_models/character_creation_view_model.dart';
import '../../services/game_data_service.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Background creation step widget for character creation
class BackgroundStep extends StatefulWidget {
  final CharacterCreationViewModel viewModel;

  const BackgroundStep({super.key, required this.viewModel});

  @override
  BackgroundStepState createState() => BackgroundStepState();
}

class BackgroundStepState extends State<BackgroundStep> {
  late TextEditingController backgroundController;
  List<TextEditingController> questionControllers = [];
  List<BackgroundQuestion> backgroundQuestions = [];

  // Track when class changes, so we can reload questions and reset UI state
  String? _lastClassId;

  // Debounce saves
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    backgroundController = TextEditingController(
        text: widget.viewModel.character.background ?? '');

    backgroundController.addListener(_onTextChanged);

    _lastClassId = widget.viewModel.character.characterClass?.id;

    _loadBackgroundQuestions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentClassId = widget.viewModel.character.characterClass?.id;
    if (currentClassId != _lastClassId) {
      _lastClassId = currentClassId;
      _loadBackgroundQuestions();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    backgroundController.dispose();
    for (final controller in questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadBackgroundQuestions() {
    if (!mounted) return;

    final character = widget.viewModel.character;

    if (character.characterClass != null) {
      final gameDataService = context.read<GameDataService>();
      final questions =
          gameDataService.backgroundQuestions[character.characterClass!.id] ??
              {};

      final newQuestions = questions.values.toList();
      final newControllers = <TextEditingController>[];

      // Create or reuse controllers
      for (var i = 0; i < newQuestions.length; i++) {
        final question = newQuestions[i];
        final existingAnswer =
            character.backgroundQuestionnaireAnswers[question.id] ?? '';

        if (i < questionControllers.length) {
          questionControllers[i].text = existingAnswer;
          newControllers.add(questionControllers[i]);
        } else {
          final controller = TextEditingController(text: existingAnswer);
          controller.addListener(_onTextChanged);
          newControllers.add(controller);
        }
      }

      setState(() {
        backgroundQuestions = newQuestions;
        questionControllers = newControllers;
      });
    }
  }

  void _onTextChanged() {
    // Cancel previous save timer
    _debounceTimer?.cancel();

    // Start new save timer for 1 second
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _saveBackground();
    });
  }

  void _onFocusChanged() {
    // Save immediately when focus changes
    _saveBackground();
  }

  void _saveBackground() {
    final answers = <String, String>{};
    for (var i = 0; i < backgroundQuestions.length; i++) {
      final question = backgroundQuestions[i];
      final answer = questionControllers[i].text.trim();
      if (answer.isNotEmpty) {
        answers[question.id] = answer;
      }
    }

    final hasGeneralBackground = backgroundController.text.trim().isNotEmpty;

    widget.viewModel.setBackground(
      questionnaireAnswers: answers,
      generalBackground:
          hasGeneralBackground ? backgroundController.text.trim() : null,
    );
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
                'Create Background',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HeartcraftTheme.gold,
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 20, wide: 24),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Answer class-specific background questions and add any other background notes.',
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
                narrow: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.viewModel.character.characterClass == null)
                    _buildNoClassSelectedInfo()
                  else if (backgroundQuestions.isEmpty)
                    _buildNoQuestionsAvailable()
                  else
                    _buildQuestionnaire(),
                  ...[
                    const SizedBox(height: 32),
                    _buildBackgroundNotesSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoClassSelectedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please select a class first to see class-specific background questions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQuestionsAvailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No background questions available for the ${widget.viewModel.character.characterClass!.name} class.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaire() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Background Questions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HeartcraftTheme.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "These questions help develop your ${widget.viewModel.character.characterClass!.name}'s background:",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 16),
        ...backgroundQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final controller = questionControllers[index];

          return Padding(
            padding: EdgeInsets.only(
                bottom: index < backgroundQuestions.length - 1 ? 20 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  onTapOutside: (_) => _onFocusChanged(),
                  onSubmitted: (_) => _onFocusChanged(),
                  decoration: InputDecoration(
                    hintText: 'Your answer (optional)...',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBackgroundNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Background Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HeartcraftTheme.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add any other background details, stories, or notes about your character:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: backgroundController,
          onTapOutside: (_) => _onFocusChanged(),
          onSubmitted: (_) => _onFocusChanged(),
          maxLines: ResponsiveUtils.responsiveValue(
            context,
            narrow: 4,
            wide: 8,
          ),
          decoration: InputDecoration(
            hintText: 'Additional background story (optional)...',
            hintStyle: TextStyle(color: Colors.grey[700]),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
