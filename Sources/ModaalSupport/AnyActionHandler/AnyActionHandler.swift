// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import Foundation

/// A helper class to avoid capturing `self` strongly when passing events from a SwiftUI view
/// to the hosting view controller.
///
/// Example:
/// ```
/// struct SomeView: View {
///   private var onTapHandler: AnyActionHandler<Void>?
///
///   var body: some View {
///     // ...
///     Button("") {
///       onTapHandler?.invoke(())
///     }
///   }
///
///   func onTap(_ handler: AnyActionHandler<Void>?) -> Self {
///     var copy = self
///     copy.onTapHandler = handler
///     return copy
///   }
/// }
///
/// // ...
///
/// class SomeHostingController: UIHostingController<SomeView> {
///   init() {
///     super.init(rootView: SomeView())
///   }
///
///   override func viewDidLoad() {
///     super.viewDidLoad()
///     self.rootView = SomeView()
///       .onTap(onTapHandler)
///   }
///
///   var onTapHandler: AnyActionHandler<Void> {
///     AnyActionHandler(self) { controller, _ in
///       // `controller` is a strong reference
///       // Do whatever
///     }
///   }
/// }
/// ```
public struct AnyActionHandler<A> {
  public typealias AnyEventHandler = (A) -> ()
  private let handler: AnyEventHandler

  public init<T: AnyObject>(_ weakOwner: T, closure: @escaping ActionHandler<T, A>.EventHandler) {
    self = ActionHandler(weakOwner, closure: closure).eraseToAny()
  }

  public init(_ handler: @escaping AnyEventHandler) {
    self.handler = handler
  }

  public func invoke(_ arg: A) {
    handler(arg)
  }
}

extension AnyActionHandler where A == Void {
  public init<T: AnyObject>(_ weakOwner: T, closure: @escaping (T) -> ()) {
    self.init(weakOwner) { owner, _ in
      closure(owner)
    }
  }

  public func invoke() {
    handler(())
  }
}

public struct ActionHandler<T: AnyObject, A> {
  public typealias EventHandler = (T, A) -> ()

  private weak var weakOwner: T?
  private let closure: EventHandler

  fileprivate init(_ weakOwner: T, closure: @escaping EventHandler) {
    self.weakOwner = weakOwner
    self.closure = closure
  }

  fileprivate func invoke(_ arg: A) {
    guard let strongOwner = weakOwner else {
      return
    }

    closure(strongOwner, arg)
  }

  fileprivate func eraseToAny() -> AnyActionHandler<A> {
    AnyActionHandler { arg in
      invoke(arg)
    }
  }
}

extension AnyActionHandler {
  public func mapHandler<U>(_ transform: @escaping (U) -> A) -> AnyActionHandler<U> {
    AnyActionHandler<U> { u in
      self.invoke(transform(u))
    }
  }
}
