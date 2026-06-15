//
//  UIView+ParentViewController.swift
//  IMap
//
//  Walks the responder chain to find the nearest owning `UIViewController`.
//  Used by `UniversalMapContainerView` to perform proper child-VC containment
//  for the map's native view controller.
//

import UIKit

extension UIView {
    /// The nearest `UIViewController` in the responder chain, if any.
    var parentViewController: UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}
