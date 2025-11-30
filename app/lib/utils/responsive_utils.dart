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

/// Utility class for handling responsive design across the app
class ResponsiveUtils {
  // The common breakpoint width in pixels that determines mobile vs tablet/desktop layout
  static const double breakpointWidth = 600.0;

  // Returns true if the screen width is less than the breakpoint (mobile/narrow screens)
  static bool isNarrowScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointWidth;
  }

  // Returns true if the screen width is greater than or
  // equal to the breakpoint (tablet/desktop/wide screens)
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointWidth;
  }

  // Returns a value based on screen size: narrow for mobile, wide for tablet/desktop
  static T responsiveValue<T>(
    BuildContext context, {
    required T narrow,
    required T wide,
  }) {
    return isNarrowScreen(context) ? narrow : wide;
  }

  // Returns the current screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Returns the current screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
