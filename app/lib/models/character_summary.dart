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

/// Structure to hold basic character info for home screen tiles etc.
class CharacterSummary {
  final String id;
  final String name;
  final String className;
  final int level;
  final String? portraitPath;

  CharacterSummary({
    required this.id,
    required this.name,
    required this.className,
    required this.level,
    this.portraitPath,
  });

  /// Returns a formatted string of class and level (e.g. "Ranger (Beastbound) 6")
  String get classLevelString {
    return '$className $level';
  }
}
