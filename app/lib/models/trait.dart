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

enum Trait {
  agility,
  strength,
  finesse,
  instinct,
  presence,
  knowledge;

  String get displayName {
    switch (this) {
      case Trait.agility:
        return 'Agility';
      case Trait.strength:
        return 'Strength';
      case Trait.finesse:
        return 'Finesse';
      case Trait.instinct:
        return 'Instinct';
      case Trait.presence:
        return 'Presence';
      case Trait.knowledge:
        return 'Knowledge';
    }
  }

  String get name {
    return toString().split('.').last;
  }

  static Trait? fromName(String id) {
    try {
      return Trait.values.byName(id);
    } catch (e) {
      return null;
    }
  }
}
