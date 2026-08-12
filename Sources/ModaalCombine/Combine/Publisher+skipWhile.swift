// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Combine

@available(iOS 13.0, *)
extension Publisher {
  public func skip(while predicate: @escaping (Output) -> Bool) -> AnyPublisher<Output, Failure> {
    return self
      .scan((skipping: true, output: Optional<Output>.none)) { state, value in
        if state.skipping && predicate(value) {
          return (true, nil)
        } else {
          return (false, value)
        }
      }
      .compactMap { $0.output }
      .eraseToAnyPublisher()
  }
}
