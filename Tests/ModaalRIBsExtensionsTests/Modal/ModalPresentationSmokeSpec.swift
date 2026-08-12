// Copyright (c) 2026 Modaal.dev
// Licensed under the MIT License. See LICENSE file for details.

import CombineRIBs
import Nimble
import PhotosUI
import Quick
import ModaalSupport
import UIKit
@testable import ModaalRIBsExtensions

/// Smoke spec for the `Modal/` seam. Verifies the public surface
/// constructs and that the delegate proxies forward each
/// `UIAdaptivePresentationControllerDelegate` / `PHPickerViewControllerDelegate`
/// / `UIImagePickerControllerDelegate` callback into its corresponding
/// `AnyActionHandler`.
///
/// The chained-dismissal correctness (the `+25 ms` `DispatchQueue.main.asyncAfter`
/// hop, UIKit's "calls to dismiss are ignored when the receiver is being
/// dismissed by another animation" rule, the outer-VC `deinit` timing) is
/// a UIKit transition-coordinator property and is NOT unit-testable here.
/// Verify those on device with `CombineRIBs.LeakDetector` enabled.
final class ModalPresentationSmokeSpec: QuickSpec {
  override class func spec() {

    describe("UIPresentationControllerDelegateProxy") {

      it("fires didDismissHandler when presentationControllerDidDismiss is invoked") {
        var didDismissCount = 0
        let proxy = UIPresentationControllerDelegateProxy(
          didDismissHandler: AnyActionHandler<Void> { _ in didDismissCount += 1 })

        proxy.presentationControllerDidDismiss(UIPresentationController(
          presentedViewController: UIViewController(),
          presenting: nil))

        expect(didDismissCount).to(equal(1))
      }

      it("returns true from presentationControllerShouldDismiss when no gate is supplied (allow by default)") {
        let proxy = UIPresentationControllerDelegateProxy(
          didDismissHandler: AnyActionHandler<Void> { _ in })

        let allow = proxy.presentationControllerShouldDismiss(UIPresentationController(
          presentedViewController: UIViewController(),
          presenting: nil))

        expect(allow).to(beTrue())
      }

      it("returns the gate's value from presentationControllerShouldDismiss when supplied") {
        var allowDismissal = false
        let proxy = UIPresentationControllerDelegateProxy(
          didDismissHandler: AnyActionHandler<Void> { _ in },
          shouldDismissHandler: { allowDismissal })

        let presentationController = UIPresentationController(
          presentedViewController: UIViewController(),
          presenting: nil)

        expect(proxy.presentationControllerShouldDismiss(presentationController)).to(beFalse())

        allowDismissal = true
        expect(proxy.presentationControllerShouldDismiss(presentationController)).to(beTrue())
      }

      it("fires didAttemptToDismissHandler when presentationControllerDidAttemptToDismiss is invoked") {
        var attemptCount = 0
        let proxy = UIPresentationControllerDelegateProxy(
          didDismissHandler: AnyActionHandler<Void> { _ in },
          shouldDismissHandler: { false },
          didAttemptToDismissHandler: AnyActionHandler<Void> { _ in attemptCount += 1 })

        proxy.presentationControllerDidAttemptToDismiss(UIPresentationController(
          presentedViewController: UIViewController(),
          presenting: nil))

        expect(attemptCount).to(equal(1))
      }
    }

    describe("AnyViewControllable") {

      it("returns the wrapped UIViewController unchanged") {
        let underlying = UIViewController()
        let wrapper = AnyViewControllable(underlying)

        expect(wrapper.uiviewController).to(beIdenticalTo(underlying))
      }

      it("retains the wrapped UIViewController strongly") {
        weak var probe: UIViewController?
        var wrapper: AnyViewControllable? = {
          let vc = UIViewController()
          probe = vc
          return AnyViewControllable(vc)
        }()

        expect(probe).toNot(beNil(), description: "wrapper retains VC while wrapper is alive")
        expect(wrapper).toNot(beNil(), description: "sanity: wrapper not released early")

        wrapper = nil

        expect(probe).to(beNil(), description: "VC deallocates once wrapper is released")
      }
    }

    describe("PHPickerResultsHandlerProxy") {

      it("forwards picker results to the onResults handler") {
        var receivedCount: Int?
        let proxy = PHPickerResultsHandlerProxy(
          onResults: AnyActionHandler<[PHPickerResult]> { results in
            receivedCount = results.count
          })

        let config = PHPickerConfiguration()
        let picker = PHPickerViewController(configuration: config)
        proxy.picker(picker, didFinishPicking: [])

        expect(receivedCount).to(equal(0))
      }
    }

    describe("UIImagePickerControllerStillImageDelegateProxy") {

      it("forwards the cancel path as a nil UIImage") {
        // Tracks invocation explicitly via a Bool flag rather than the
        // `Optional<Optional<UIImage>>` pattern: Nimble's `beNil` matcher
        // collapses nested optionals (treats `.some(nil)` as nil) so a
        // double-optional cannot distinguish "handler not called" from
        // "handler called with nil".
        var invocationCount = 0
        var receivedImage: UIImage?
        let proxy = UIImagePickerControllerStillImageDelegateProxy(
          onCapture: AnyActionHandler<UIImage?> { image in
            invocationCount += 1
            receivedImage = image
          })

        proxy.imagePickerControllerDidCancel(UIImagePickerController())

        expect(invocationCount).to(equal(1))
        expect(receivedImage).to(beNil())
      }
    }

    describe("UIImagePickerControllerVideoDelegateProxy") {

      it("forwards the cancel path as a nil URL") {
        var invocationCount = 0
        var receivedURL: URL?
        let proxy = UIImagePickerControllerVideoDelegateProxy(
          onCapture: AnyActionHandler<URL?> { url in
            invocationCount += 1
            receivedURL = url
          })

        proxy.imagePickerControllerDidCancel(UIImagePickerController())

        expect(invocationCount).to(equal(1))
        expect(receivedURL).to(beNil())
      }
    }

    describe("Modal public surface — construction smoke") {

      it("every shipped Modal/ public type instantiates with its canonical initializer") {
        // Catches accidental signature drift on any of the public initializers.
        // Each constructed instance is unused — successful compilation +
        // non-nil return is the entire assertion.
        let presentationDelegate = UIPresentationControllerDelegateProxy(
          didDismissHandler: AnyActionHandler<Void> { _ in })
        let anyViewControllable = AnyViewControllable(UIViewController())
        let phPickerProxy = PHPickerResultsHandlerProxy(
          onResults: AnyActionHandler<[PHPickerResult]> { _ in })
        let imageStillProxy = UIImagePickerControllerStillImageDelegateProxy(
          onCapture: AnyActionHandler<UIImage?> { _ in })
        let imageVideoProxy = UIImagePickerControllerVideoDelegateProxy(
          onCapture: AnyActionHandler<URL?> { _ in })

        expect(presentationDelegate).toNot(beNil())
        expect(anyViewControllable).toNot(beNil())
        expect(phPickerProxy).toNot(beNil())
        expect(imageStillProxy).toNot(beNil())
        expect(imageVideoProxy).toNot(beNil())
      }
    }
  }
}
