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

import 'package:heartcraft/models/compendium.dart';
import 'package:xml/xml.dart';

/// Enum representing weapon burden (i.e. one-handed or two-handed)
enum WeaponBurden {
  unknown,
  oneHanded,
  twoHanded;

  String get displayName {
    switch (this) {
      case WeaponBurden.unknown:
        return 'Unknown';
      case WeaponBurden.oneHanded:
        return 'One-Handed';
      case WeaponBurden.twoHanded:
        return 'Two-Handed';
    }
  }

  /// Parse burden from XML attribute value
  static WeaponBurden fromString(String value) {
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case '1h':
      case 'one-handed':
        return WeaponBurden.oneHanded;
      case '2h':
      case 'two-handed':
        return WeaponBurden.twoHanded;
      default:
        throw WeaponBurden.unknown;
    }
  }
}

enum Range {
  melee,
  veryClose,
  close,
  far,
  veryFar;

  String get displayName {
    switch (this) {
      case Range.melee:
        return 'Melee';
      case Range.veryClose:
        return 'Very Close';
      case Range.close:
        return 'Close';
      case Range.far:
        return 'Far';
      case Range.veryFar:
        return 'Very Far';
    }
  }

  /// Parse range from XML attribute value
  static Range fromString(String value) {
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'melee':
        return Range.melee;
      case 'very close':
        return Range.veryClose;
      case 'close':
        return Range.close;
      case 'far':
        return Range.far;
      case 'very far':
        return Range.veryFar;
      default:
        throw FormatException('Unknown range value: $value');
    }
  }
}

enum DamageDie {
  d4,
  d6,
  d8,
  d10,
  d12,
  d20;

  String get displayName {
    switch (this) {
      case DamageDie.d4:
        return 'd4';
      case DamageDie.d6:
        return 'd6';
      case DamageDie.d8:
        return 'd8';
      case DamageDie.d10:
        return 'd10';
      case DamageDie.d12:
        return 'd12';
      case DamageDie.d20:
        return 'd20';
    }
  }

  /// Parse damage die from XML attribute value
  static DamageDie fromString(String value) {
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'd4':
        return DamageDie.d4;
      case 'd6':
        return DamageDie.d6;
      case 'd8':
        return DamageDie.d8;
      case 'd10':
        return DamageDie.d10;
      case 'd12':
        return DamageDie.d12;
      case 'd20':
        return DamageDie.d20;
      default:
        throw FormatException('Unknown damage die value: $value');
    }
  }
}

class Weapon {
  // TODO: make some of this stuff enums or classes
  final String id;
  final String name;
  final String trait;
  final String range;
  final String damage;
  final WeaponBurden burden;
  final String feature;
  final String damageType;
  final String type;
  final int tier;
  bool custom;

  Weapon({
    required this.id,
    required this.name,
    required this.trait,
    required this.range,
    required this.damage,
    required this.burden,
    required this.feature,
    required this.damageType,
    required this.type,
    required this.tier,
    this.custom = false,
  });

  factory Weapon.fromXml(
      XmlElement element, String damageType, String type, int tier,
      [Compendium? compendium]) {
    final burdenStr = element.getAttribute('burden') ?? 'unknown';
    return Weapon(
      id: compendium?.fullyQualifiedId(element.getAttribute('id')!) ??
          element.getAttribute('id')!,
      name: element.getAttribute('name') ?? '',
      trait: element.getAttribute('trait') ?? '',
      range: element.getAttribute('range') ?? '',
      damage: element.getAttribute('damage') ?? '',
      burden: WeaponBurden.fromString(burdenStr),
      feature: element.getAttribute('feature') ?? '',
      damageType: damageType,
      type: type,
      tier: tier,
      custom: false,
    );
  }
}

class Armor {
  final String id;
  final String name;
  final int majorDamageThreshold;
  final int severeDamageThreshold;
  final int baseScore;
  final String feature;
  final int tier;
  bool custom;

  // TODO: uhgghggg make class rather than parsing strings
  String get baseThresholds => '$majorDamageThreshold / $severeDamageThreshold';

  Armor({
    required this.id,
    required this.name,
    required this.majorDamageThreshold,
    required this.severeDamageThreshold,
    required this.baseScore,
    required this.feature,
    required this.tier,
    this.custom = false,
  });

  factory Armor.fromXml(XmlElement element, int tier,
      [Compendium? compendium]) {
    final thresholds = element.getAttribute('baseThresholds')?.split('/');

    if (thresholds == null || thresholds.length != 2) {
      throw FormatException(
          'Invalid baseThresholds format for armor ${element.getAttribute('id')}');
    }

    final majorDamageThreshold = int.parse(thresholds[0].trim());
    final severeDamageThreshold = int.parse(thresholds[1].trim());

    return Armor(
      id: compendium?.fullyQualifiedId(element.getAttribute('id')!) ??
          element.getAttribute('id')!,
      name: element.getAttribute('name')!,
      majorDamageThreshold: majorDamageThreshold,
      severeDamageThreshold: severeDamageThreshold,
      baseScore: int.parse(element.getAttribute('baseScore')!),
      feature: element.getAttribute('feature')!,
      tier: tier,
    );
  }
}

/// Represents a starting item option group (e.g., potion selection)
class OptionGroup {
  final String id;
  final String name;
  final List<OptionGroupItem> options;

  OptionGroup({
    required this.id,
    required this.name,
    required this.options,
  });

  factory OptionGroup.fromXml(XmlElement element, Compendium compendium) {
    final options = <OptionGroupItem>[];

    for (final optionElement in element.findElements('option')) {
      options.add(OptionGroupItem.fromXml(optionElement));
    }

    return OptionGroup(
      id: compendium.fullyQualifiedId(element.getAttribute('id')!),
      name: element.getAttribute('name')!,
      options: options,
    );
  }
}

/// Represents an option within a starting item option group
class OptionGroupItem {
  final String item;
  final String? description;

  OptionGroupItem({
    required this.item,
    this.description,
  });

  factory OptionGroupItem.fromXml(XmlElement element) {
    return OptionGroupItem(
      item: element.getElement('item')!.innerText,
      description: element.getElement('description')?.innerText,
    );
  }
}

/// Represents a generic inventory item
class Item {
  String id;
  String name;
  String? description;
  int quantity; // TODO: decouple item from quantity?

  Item({
    required this.id,
    required this.name,
    this.description,
    this.quantity = 1,
  });
}
