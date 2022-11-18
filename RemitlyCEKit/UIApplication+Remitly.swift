//
//  UIApplication+Remitly.swift
//  RemitlyCEKit
//
//  Created by Nick Hodapp on 9/28/22.
//

import Foundation

extension UIApplication {
    
    private var rmKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication
                .shared
                .connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow;
        }
    }
    
    internal var keyWindowPresentedController: UIViewController? {
        var viewController = self.rmKeyWindow?.rootViewController
      
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
