// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

extension LocalizedStringResource {
  public func localized(_ locale: Locale) -> LocalizedStringResource {
    var copy = self
    copy.locale = locale
    return copy.localizedStringResource
  }
}
