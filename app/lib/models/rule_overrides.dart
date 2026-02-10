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

import 'package:xml/xml.dart';

/// Represents rules overrides that can be applied by features,
/// classes, abilities, or character-specific choices
///
/// TODO: should probably be a tree structure as overrides can be
/// applied at multiple levels - would also provide provenance
/// for why a particular override is in place
class RuleOverrides {
  final RuleOverrides? _parent;
  bool? _ignoreWeaponBurden;

  bool get ignoreWeaponBurden =>
      _ignoreWeaponBurden ?? _parent?.ignoreWeaponBurden ?? false;

  RuleOverrides({
    RuleOverrides? parent,
    bool? ignoreWeaponBurden,
  })  : _ignoreWeaponBurden = ignoreWeaponBurden,
        _parent = parent;

  factory RuleOverrides.fromXml(XmlElement element) {
    return RuleOverrides(
      ignoreWeaponBurden:
          element.getElement('ignoreWeaponBurden')?.innerText.toLowerCase() ==
              'true',
    );
  }

  void merge(RuleOverrides other) {
    if (other._ignoreWeaponBurden != null) {
      _ignoreWeaponBurden = _ignoreWeaponBurden == null
          ? other._ignoreWeaponBurden
          : _ignoreWeaponBurden! || other._ignoreWeaponBurden!;
    }
  }
}
