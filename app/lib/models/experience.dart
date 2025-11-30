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

class Experience {
  String name;
  int modifier;

  Experience({
    required this.name,
    this.modifier = 2,
  });
}

// TODO: really should be part of the model?
Icon iconForExperienceCategory(String? category) {
  switch (category) {
    case 'Backgrounds':
      return const Icon(Icons.work);
    case 'Characteristics':
      return const Icon(Icons.person);
    case 'Specialties':
      return const Icon(Icons.science);
    case 'Phrases':
      return const Icon(Icons.format_quote);
    default:
      return const Icon(Icons.star);
  }
}
