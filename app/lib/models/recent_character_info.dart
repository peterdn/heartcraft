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

/// Information for tracking recently opened characters
class RecentCharacterInfo {
  final String characterId;
  final DateTime lastAccessed;

  RecentCharacterInfo({
    required this.characterId,
    required this.lastAccessed,
  });

  Map<String, dynamic> serialise() {
    return {
      'characterId': characterId,
      'lastAccessed': lastAccessed.millisecondsSinceEpoch,
    };
  }

  static RecentCharacterInfo deserialise(Map<String, dynamic> map) {
    return RecentCharacterInfo(
      characterId: map['characterId'] ?? '',
      lastAccessed:
          DateTime.fromMillisecondsSinceEpoch(map['lastAccessed'] ?? 0),
    );
  }
}
