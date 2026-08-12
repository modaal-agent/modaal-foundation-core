// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

/// Priority for handlers registered with `AppServicesRegistering`.
///
/// Higher-priority handlers win when multiple handlers claim the same URL or
/// remote notification. Choose `.high` for handlers that own a specific scheme
/// or payload shape (e.g. an OAuth callback), `.default` for feature deeplinks,
/// `.fallback` for catch-all handlers (e.g. dev-only logging).
public enum AppServicePriority: Int {
  case high     = 1000
  case `default` = 100
  case fallback = 0
}
