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

import 'package:heartcraft/models/trait.dart';
import 'package:xml/xml.dart';

class Tier2Advancements {
  int increaseTraits = 0;
  int increaseHitpoints = 0;
  int increaseStress = 0;
  bool additionalDomainCard = false;
  bool increaseExperiences = false;
  bool increaseEvasion = false;

  Tier2Advancements copy() {
    final copy = Tier2Advancements();
    copy.increaseTraits = increaseTraits;
    copy.increaseHitpoints = increaseHitpoints;
    copy.increaseStress = increaseStress;
    copy.additionalDomainCard = additionalDomainCard;
    copy.increaseExperiences = increaseExperiences;
    copy.increaseEvasion = increaseEvasion;
    return copy;
  }

  void toXml(XmlBuilder builder) {
    builder.element('tier2', nest: () {
      builder.element('increaseTraits', nest: increaseTraits.toString());
      builder.element('increaseHitpoints', nest: increaseHitpoints.toString());
      builder.element('increaseStress', nest: increaseStress.toString());
      builder.element('additionalDomainCard',
          nest: additionalDomainCard.toString());
      builder.element('increaseExperiences',
          nest: increaseExperiences.toString());
      builder.element('increaseEvasion', nest: increaseEvasion.toString());
    });
  }

  // The total number of selections made in Tier 2
  int get totalSelections {
    return increaseTraits +
        increaseHitpoints +
        increaseStress +
        (additionalDomainCard ? 1 : 0) +
        (increaseExperiences ? 1 : 0) +
        (increaseEvasion ? 1 : 0);
  }
}

class Tier3And4Advancements {
  int increaseTraits = 0;
  int increaseHitpoints = 0;
  int increaseStress = 0;
  bool additionalDomainCard = false;
  bool increaseExperiences = false;
  bool increaseEvasion = false;
  bool upgradeSubclass = false;
  bool increaseProficiency = false;
  bool multiclass = false;

  void toXml(XmlBuilder builder, String tierTag) {
    builder.element(tierTag, nest: () {
      builder.element('increaseTraits', nest: increaseTraits.toString());
      builder.element('increaseHitpoints', nest: increaseHitpoints.toString());
      builder.element('increaseStress', nest: increaseStress.toString());
      builder.element('additionalDomainCard',
          nest: additionalDomainCard.toString());
      builder.element('increaseExperiences',
          nest: increaseExperiences.toString());
      builder.element('increaseEvasion', nest: increaseEvasion.toString());
      builder.element('upgradeSubclass', nest: upgradeSubclass.toString());
      builder.element('increaseProficiency',
          nest: increaseProficiency.toString());
      builder.element('multiclass', nest: multiclass.toString());
    });
  }
}

class Advancements {
  Tier2Advancements tier2 = Tier2Advancements();
  Tier3And4Advancements tier3 = Tier3And4Advancements();
  Tier3And4Advancements tier4 = Tier3And4Advancements();

  List<Trait> markedTraits = [];

  void toXml(XmlBuilder builder) {
    builder.element('advancements', nest: () {
      tier2.toXml(builder);
      tier3.toXml(builder, 'tier3');
      tier4.toXml(builder, 'tier4');
      if (markedTraits.isNotEmpty) {
        builder.element('markedTraits', nest: () {
          for (var trait in markedTraits) {
            builder.element('trait', nest: () {
              builder.attribute('name', trait.name);
            });
          }
        });
      }
    });
  }

  static Advancements fromXml(XmlElement? advancementsElement) {
    final advancements = Advancements();
    if (advancementsElement == null) return advancements;
    // Tier 2
    final tier2Element = advancementsElement.getElement('tier2');
    if (tier2Element != null) {
      advancements.tier2.increaseTraits = int.tryParse(
              tier2Element.getElement('increaseTraits')?.innerText ?? '0') ??
          0;
      advancements.tier2.increaseHitpoints = int.tryParse(
              tier2Element.getElement('increaseHitpoints')?.innerText ?? '0') ??
          0;
      advancements.tier2.increaseStress = int.tryParse(
              tier2Element.getElement('increaseStress')?.innerText ?? '0') ??
          0;
      advancements.tier2.additionalDomainCard = bool.tryParse(
              tier2Element.getElement('additionalDomainCard')?.innerText ??
                  'false') ??
          false;
      advancements.tier2.increaseExperiences = bool.tryParse(
              tier2Element.getElement('increaseExperiences')?.innerText ??
                  'false') ??
          false;
      advancements.tier2.increaseEvasion = bool.tryParse(
              tier2Element.getElement('increaseEvasion')?.innerText ??
                  'false') ??
          false;
    }
    // Tier 3
    final tier3Element = advancementsElement.getElement('tier3');
    if (tier3Element != null) {
      advancements.tier3.increaseTraits = int.tryParse(
              tier3Element.getElement('increaseTraits')?.innerText ?? '0') ??
          0;
      advancements.tier3.increaseHitpoints = int.tryParse(
              tier3Element.getElement('increaseHitpoints')?.innerText ?? '0') ??
          0;
      advancements.tier3.increaseStress = int.tryParse(
              tier3Element.getElement('increaseStress')?.innerText ?? '0') ??
          0;
      advancements.tier3.additionalDomainCard = bool.tryParse(
              tier3Element.getElement('additionalDomainCard')?.innerText ??
                  'false') ??
          false;
      advancements.tier3.increaseExperiences = bool.tryParse(
              tier3Element.getElement('increaseExperiences')?.innerText ??
                  'false') ??
          false;
      advancements.tier3.increaseEvasion = bool.tryParse(
              tier3Element.getElement('increaseEvasion')?.innerText ??
                  'false') ??
          false;
      advancements.tier3.upgradeSubclass = bool.tryParse(
              tier3Element.getElement('upgradeSubclass')?.innerText ??
                  'false') ??
          false;
      advancements.tier3.increaseProficiency = bool.tryParse(
              tier3Element.getElement('increaseProficiency')?.innerText ??
                  'false') ??
          false;
      advancements.tier3.multiclass = bool.tryParse(
              tier3Element.getElement('multiclass')?.innerText ?? 'false') ??
          false;
    }
    // Tier 4
    final tier4Element = advancementsElement.getElement('tier4');
    if (tier4Element != null) {
      advancements.tier4.increaseTraits = int.tryParse(
              tier4Element.getElement('increaseTraits')?.innerText ?? '0') ??
          0;
      advancements.tier4.increaseHitpoints = int.tryParse(
              tier4Element.getElement('increaseHitpoints')?.innerText ?? '0') ??
          0;
      advancements.tier4.increaseStress = int.tryParse(
              tier4Element.getElement('increaseStress')?.innerText ?? '0') ??
          0;
      advancements.tier4.additionalDomainCard = bool.tryParse(
              tier4Element.getElement('additionalDomainCard')?.innerText ??
                  'false') ??
          false;
      advancements.tier4.increaseExperiences = bool.tryParse(
              tier4Element.getElement('increaseExperiences')?.innerText ??
                  'false') ??
          false;
      advancements.tier4.increaseEvasion = bool.tryParse(
              tier4Element.getElement('increaseEvasion')?.innerText ??
                  'false') ??
          false;
      advancements.tier4.upgradeSubclass = bool.tryParse(
              tier4Element.getElement('upgradeSubclass')?.innerText ??
                  'false') ??
          false;
      advancements.tier4.increaseProficiency = bool.tryParse(
              tier4Element.getElement('increaseProficiency')?.innerText ??
                  'false') ??
          false;
      advancements.tier4.multiclass = bool.tryParse(
              tier4Element.getElement('multiclass')?.innerText ?? 'false') ??
          false;
    }
    // Marked traits (global; independent of Tier)
    final markedTraitsElement = advancementsElement.getElement('markedTraits');
    advancements.markedTraits.clear();
    if (markedTraitsElement != null) {
      for (var traitElement in markedTraitsElement.findElements('trait')) {
        final traitName = traitElement.getAttribute('name');
        final trait = Trait.fromName(traitName ?? '');
        if (trait != null) {
          advancements.markedTraits.add(trait);
        }
      }
    }
    return advancements;
  }
}
