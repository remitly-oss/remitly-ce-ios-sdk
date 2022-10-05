//
//  UIApplication+Remitly.swift
//  RemitlyCEKit
//
//  Created by Nick Hodapp on 9/28/22.
//

import Foundation

extension UIApplication {
    
    private var keyWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }
    
    internal var keyWindowPresentedController: UIViewController? {
        var viewController = self.keyWindow?.rootViewController
      
        while let presentedController = viewController?.presentedViewController {
            if let presentedController = presentedController as? UITabBarController {
                viewController = presentedController.selectedViewController
            } else {
                viewController = presentedController
            }
        }
        
        return viewController
    }
}
