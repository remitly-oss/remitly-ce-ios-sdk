//
//  RemitlyCeViewController.swift
//  RemitlyCE
//
//  Created by Nick Hodapp on 8/22/22.
//

import UIKit

@objc(RECEViewControllerDelegate) public protocol RemitlyCeViewControllerDelegate {
    @objc optional func onUserActivity() -> Void
    @objc optional func onTransferSubmitted() -> Void
    @objc optional func onDismissed() -> Void
}

@objc(RECEViewController) public class RemitlyCeViewController: UIViewController {
    
    @IBOutlet public var delegate: RemitlyCeViewControllerDelegate? {
        set(delegate) {
            self.ceWebViewController.delegate = delegate
        }
        get {
            return self.ceWebViewController.delegate
        }
    }
    
    private var ceWebViewController = RemitlyCeWebViewController(url: try! RemitlyCeConfiguration.webUrl)
    
    public override var navigationItem: UINavigationItem {
        get {
            return ceWebViewController.navigationItem;
        }
    }
    
    public final override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            return .pageSheet;
        }
        set (style) { /* noop */ }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let embedVc: UIViewController = self.isBeingPresented ? UINavigationController(rootViewController: ceWebViewController) : ceWebViewController
        addChild(embedVc)
        view.addSubview(embedVc.view)
        embedVc.view.frame = self.view.bounds
        embedVc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        embedVc.didMove(toParent: self)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if (isBeingDismissed) {
            self.delegate?.onDismissed?()
        }
    }
    
    @objc public static func present() -> RemitlyCeViewController? {
        guard let topvc = UIApplication.shared.keyWindowPresentedController else {
            return nil
        }
        let rvc = RemitlyCeViewController()
        topvc.present(rvc, animated: true, completion: nil)
        return rvc
    }
    
    @objc public static func logout() -> Void {
        if let webUrl = try? RemitlyCeConfiguration.webUrl {
            if let cookies = HTTPCookieStorage.shared.cookies(for: webUrl),
               let token = cookies.first(where: { cookie in
                   cookie.name == "token"
               }),
               let gr = cookies.first(where: { cookie in
                   cookie.name == "gr"
               })
            {
                if let apiUrl = try? RemitlyCeConfiguration.apiUrl,
                   let logoutURL = URL(string: "v1/auth/logout", relativeTo: apiUrl)
                {
                    var request = URLRequest(url: logoutURL)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(token.value)", forHTTPHeaderField: "Authorization")
                    request.setValue(gr.value, forHTTPHeaderField: "X-Remitly-GlobalRiskPublicId")
                    request.setValue(RemitlyCeConfiguration.deviceEnvironmentId, forHTTPHeaderField: "Remitly-DeviceEnvironmentID")
                    URLSession.shared.dataTask(with: request).resume()
                }
                HTTPCookieStorage.shared.deleteCookie(token)
            }
        }
    }
}
