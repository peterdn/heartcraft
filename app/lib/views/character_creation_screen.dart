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
import '../providers/character_creation_provider.dart';
import '../providers/character_provider.dart';
import '../theme/heartcraft_theme.dart';
import '../routes.dart';
import '../utils/responsive_utils.dart';
import 'character_creation/class_selection_step.dart';
import 'character_creation/companion_selection_step.dart';
import 'character_creation/ancestry_selection_step.dart';
import 'character_creation/community_selection_step.dart';
import 'character_creation/trait_assignment_step.dart';
import 'character_creation/equipment_selection_step.dart';
import 'character_creation/background_step.dart';
import 'character_creation/experiences_step.dart';
import 'character_creation/domain_cards_step.dart';
import 'character_creation/personal_details_step.dart';
import 'character_creation/review_step.dart';

/// Character creation screen that guides the user through multiple steps:
/// - Steps include personal details, ancestry, class, companion (if applicable),
///   background, traits, equipment, experiences, domain cards, and review
/// - Progress indicator shows current step and allows navigation between steps
///   Appears at top on wide screens, as a dropdown menu on narrow screens
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  CharacterCreationScreenState createState() => CharacterCreationScreenState();
}

class CharacterCreationScreenState extends State<CharacterCreationScreen> {
  int? _hoveredStep;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Scaffold(
      appBar: AppBar(
        // Home button to exit character creation
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () async {
            final navigator = Navigator.of(context);
            final shouldExit = await _showExitConfirmation(context) ?? false;
            if (shouldExit && mounted) {
              navigator.pushNamedAndRemoveUntil(Routes.home, (route) => false);
            }
          },
        ),
        title: const Text('Create Character'),
      ),
      body: Consumer<CharacterCreationProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.only(bottom: padding.bottom),
            child: Column(
              children: [
                // Progress bar (only on wide screens)
                // Narrow screens use a floating dropdown instead
                if (ResponsiveUtils.isWideScreen(context))
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildStepProgressBar(provider),
                  ),

                // Current step content (widgets under character_creation/)
                Expanded(
                  child: _buildCurrentStepContent(provider),
                ),

                // Previous / Next navigation buttons
                _buildNavigationButtons(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build the content for the current step
  Widget _buildCurrentStepContent(CharacterCreationProvider provider) {
    Widget stepContent;

    switch (provider.currentStep) {
      case CharacterCreationStep.classAndSubclass:
        stepContent = ClassSelectionStep();
        break;
      case CharacterCreationStep.companion:
        stepContent = CompanionSelectionStep(provider: provider);
        break;
      case CharacterCreationStep.ancestry:
        stepContent = const AncestrySelectionStep();
        break;
      case CharacterCreationStep.community:
        stepContent = const CommunitySelectionStep();
        break;
      case CharacterCreationStep.traits:
        stepContent = TraitAssignmentStep(provider: provider);
        break;
      case CharacterCreationStep.equipment:
        stepContent = EquipmentSelectionStep(provider: provider);
        break;
      case CharacterCreationStep.background:
        stepContent = BackgroundStep(provider: provider);
        break;
      case CharacterCreationStep.experiences:
        stepContent = ExperiencesStep(provider: provider);
        break;
      case CharacterCreationStep.domainCards:
        stepContent = DomainCardsStep(provider: provider);
        break;
      case CharacterCreationStep.personalDetails:
        stepContent = PersonalDetailsStep(provider: provider);
        break;
      case CharacterCreationStep.review:
        stepContent = ReviewStep(provider: provider);
        break;
    }

    // On narrow screens, wrap with floating dropdown
    if (ResponsiveUtils.isNarrowScreen(context)) {
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: stepContent,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _buildStepProgressDropdown(provider),
          ),
        ],
      );
    }

    return stepContent;
  }

  /// Get the list of visible steps based on current character configuration
  List<CharacterCreationStep> _getVisibleSteps(
      CharacterCreationProvider provider) {
    const allSteps = CharacterCreationStep.values;
    final visibleSteps = <CharacterCreationStep>[];

    for (final step in allSteps) {
      switch (step) {
        case CharacterCreationStep.companion:
          // Only show companion step if current subclass has a companion
          if (provider.currentSubclassHasCompanion) {
            visibleSteps.add(step);
          }
          break;
        default:
          visibleSteps.add(step);
          break;
      }
    }

    return visibleSteps;
  }

  /// Build the progress bar showing all steps, for wide screens
  Widget _buildStepProgressBar(CharacterCreationProvider provider) {
    final currentStep = provider.currentStep;
    final visibleSteps = _getVisibleSteps(provider);
    final stepCount = visibleSteps.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clickable "steps" with circles and labels, connected by lines
        Stack(
          children: [
            // Connecting lines positioned to go through circle centers
            Positioned(
              top: 17,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: SizedBox.shrink(),
                  ),
                  // Lines between circles
                  for (int i = 0; i < stepCount - 1; i++)
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 2,
                        color: provider.isStepCompleted(visibleSteps[i])
                            ? HeartcraftTheme.gold
                            : HeartcraftTheme.surfaceColor,
                      ),
                    ),
                  const Expanded(
                    flex: 1,
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // Clickable areas with circles and labels
            Row(
              children: [
                for (int i = 0; i < stepCount; i++)
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hoveredStep = i),
                      onExit: (_) => setState(() => _hoveredStep = null),
                      child: GestureDetector(
                        onTap: () {
                          provider.goToStep(visibleSteps[i]);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _hoveredStep == i
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Circle
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: visibleSteps[i] == currentStep
                                      ? HeartcraftTheme.gold
                                      : provider
                                              .isStepCompleted(visibleSteps[i])
                                          ? HeartcraftTheme.darkPrimaryPurple
                                          : HeartcraftTheme.surfaceColor,
                                  border: Border.all(
                                    color:
                                        visibleSteps.indexOf(currentStep) >= i
                                            ? HeartcraftTheme.gold
                                            : HeartcraftTheme.darkPrimaryPurple,
                                    width: 2,
                                  ),
                                ),
                                child: provider.isStepCompleted(visibleSteps[i])
                                    ? Icon(Icons.check,
                                        size: 12,
                                        color: visibleSteps[i] == currentStep
                                            ? HeartcraftTheme.darkPrimaryPurple
                                            : Colors.white)
                                    : const SizedBox.shrink(),
                              ),
                              // Label
                              const SizedBox(height: 4),
                              Text(
                                visibleSteps[i].name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: visibleSteps[i] == currentStep
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: visibleSteps[i] == currentStep
                                      ? HeartcraftTheme.gold
                                      : Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Build a compact floating dropdown for narrow screens
  Widget _buildStepProgressDropdown(CharacterCreationProvider provider) {
    final visibleSteps = _getVisibleSteps(provider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: HeartcraftTheme.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HeartcraftTheme.gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CharacterCreationStep>(
          value: provider.currentStep,
          icon: const Icon(Icons.expand_more,
              color: HeartcraftTheme.gold, size: 18),
          dropdownColor: HeartcraftTheme.surfaceColor,
          style: const TextStyle(
              color: HeartcraftTheme.primaryTextColor, fontSize: 14),
          items: visibleSteps.map((step) {
            final isCompleted = provider.isStepCompleted(step);
            final isCurrent = step == provider.currentStep;

            return DropdownMenuItem<CharacterCreationStep>(
              value: step,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status icon
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? HeartcraftTheme.gold
                          : isCompleted
                              ? HeartcraftTheme.darkPrimaryPurple
                              : Colors.transparent,
                      border: Border.all(
                        color: isCompleted || isCurrent
                            ? HeartcraftTheme.gold
                            : Colors.white30,
                        width: 1,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 10,
                            color: isCurrent
                                ? HeartcraftTheme.darkPrimaryPurple
                                : Colors.white,
                          )
                        : isCurrent
                            ? Container()
                            : null,
                  ),
                  // Step label
                  Text(
                    step.name,
                    style: TextStyle(
                      color: isCurrent
                          ? HeartcraftTheme.gold
                          : isCompleted
                              ? Colors.white
                              : Colors.white60,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (CharacterCreationStep? newStep) {
            if (newStep != null) {
              provider.goToStep(newStep);
            }
          },
        ),
      ),
    );
  }

  /// Build navigation buttons
  Widget _buildNavigationButtons(CharacterCreationProvider provider) {
    final visibleSteps = _getVisibleSteps(provider);
    final isFirstStep = provider.currentStep == visibleSteps.first;
    final isLastStep = provider.currentStep == visibleSteps.last;
    final isStepCompleted = provider.isStepCompleted(provider.currentStep);
    final isStepOptional = provider.isStepOptional(provider.currentStep);

    final canNavigate = isStepCompleted || isStepOptional;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (!isFirstStep)
            ElevatedButton(
              onPressed: () => provider.goToPreviousStep(),
              style: TextButton.styleFrom(
                  backgroundColor: HeartcraftTheme.darkPrimaryPurple,
                  foregroundColor: HeartcraftTheme.primaryTextColor),
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),

          // Next button or Create Character button for last step
          if (!isLastStep)
            ElevatedButton(
              onPressed: canNavigate ? () => provider.goToNextStep() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: HeartcraftTheme.gold,
                foregroundColor: HeartcraftTheme.darkTextColor,
              ),
              child: const Text('Next'),
            )
          else
            // Create Character button for review step
            Tooltip(
              message: provider.isCharacterComplete()
                  ? 'Create your character'
                  : 'Complete all required sections to create your character',
              child: ElevatedButton(
                onPressed: provider.isCharacterComplete()
                    ? () => _finalizeCharacter(context, provider)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HeartcraftTheme.gold,
                  foregroundColor: HeartcraftTheme.darkTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Create Character'),
              ),
            ),
        ],
      ),
    );
  }

  /// Show exit confirmation dialog
  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Character Creation?'),
          content: const Text(
            'Your character creation progress will be lost if you exit this screen. '
            'Are you sure you want to exit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: HeartcraftTheme.primaryTextColor,
              ),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                // Clear the character creation progress when exiting
                final provider = Provider.of<CharacterCreationProvider>(context,
                    listen: false);
                await provider.exitCharacterCreation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HeartcraftTheme.errorRed,
              ),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  /// Finalize character creation
  Future<void> _finalizeCharacter(
      BuildContext context, CharacterCreationProvider provider) async {
    if (!provider.isCharacterComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please complete all required sections before creating your character'),
        ),
      );
      return;
    }

    // Copy character from CharacterCreationProvider to CharacterProvider ans save
    final character = provider.character;
    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);
    characterProvider.setCurrentCharacter(character);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await characterProvider.saveCharacter();
      if (!mounted) return;

      // Navigate to character view
      provider.exitCharacterCreation();
      // Replace the creation screen with character view (home remains underneath)
      navigator.pushReplacementNamed(Routes.viewCharacter);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save character: $e'),
          backgroundColor: HeartcraftTheme.errorRed,
        ),
      );
    }
  }
}
