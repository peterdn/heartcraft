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

class Domain {
  String id;
  String name;
  String? description;

  Domain({
    required this.id,
    required this.name,
    this.description,
  });
}

/// Represents a domain ability (for domain card selection)
class DomainAbility {
  String id;
  String name;
  String? description;
  final String domain; // domain id
  final int level;
  final int recallCost;

  DomainAbility({
    required this.id,
    required this.domain,
    required this.name,
    required this.level,
    required this.recallCost,
    required String this.description,
  });
}
