//
//  RemitlyCeWebViewController.swift
//  RemitlyCEKit
//
//  Created by Nick Hodapp on 9/28/22.
//

import Foundation
import UIKit
import WebKit
import SafariServices
import AnyCodable

class RemitlyCeWebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    enum NarwhalMessageKey: String {
        case handler = "cesdk"
        case topic = "topic"
        case payload = "payload"
        case eventType = "eventType"
    }

    enum NarwhalMessageTopic: String {
        case exitCE = "exitCE"
        case hideCloseButton = "hideCloseButton"
        case openHelpCenter = "openHelpCenter"
        case openLoginPage = "openLoginPage"
        case event = "event"
    }
    
    enum NarwhalEventType: String {
        case userActivity = "userActivity"
        case transferSubmitted = "transfer_submitted"
    }
    
    enum CloseRequestKind: String {
        case web = "web_close_button_pressed"
        case native = "modal_close_button_pressed"
    }
        
    @IBOutlet private var webViewContainer: UIView!
    @IBOutlet private var activityView: UIVisualEffectView!
    @IBOutlet private var errorStackView: UIStackView!
    @IBOutlet private var errorImageView: UIImageView!
    @IBOutlet private var errorImageLabel: UILabel!
    private var url: URL!
    private var webView: WKWebView!
    public weak var delegate: RemitlyCeViewControllerDelegate?
    private var isCloseButtonHidden = true
    private var isActivityOverlayHidden: Bool {
        get {
            return activityView.isHidden
        }
        set(isHidden) {
            if isHidden {
                UIView.transition(
                    with: activityView,
                    duration: 0.2,
                    options: .transitionCrossDissolve
                ) {
                    self.activityView.effect = nil
                } completion: { _ in
                    self.activityView.isHidden = true
                }
            } else {
                activityView.effect = UIBlurEffect(style: .extraLight)
                activityView.isHidden = isHidden
            }
        }
    }
    private var isLoading: Bool = false {
        willSet(loading) {
            if (loading) {
                isActivityOverlayHidden = false
                isCloseButtonHidden = false
            } else {
                isActivityOverlayHidden = true
            }
            navigationController?.setNavigationBarHidden(isCloseButtonHidden, animated: false)
        }
    }
    private var error: Error? = nil {
        willSet(e) {
            if let e = e as? NSError {
                errorStackView.isHidden = false
                errorImageLabel.text = e.localizedDescription
                isCloseButtonHidden = false
                EventLogger.shared.logHumio(topic: "renderError", data: [
                    "errorDesc": AnyCodable(e.localizedDescription),
                    "errorDomain": AnyCodable(e.domain),
                    "errorCode": AnyCodable(e.code),
                    "url": AnyCodable(e.userInfo[NSURLErrorFailingURLStringErrorKey] ?? "")
                ]);
            } else {
                errorStackView.isHidden = true
            }
        }
    }

    public init(url: URL) {
        let nibName = URL(string: #fileID)?.deletingPathExtension().lastPathComponent
        super.init(
            nibName: nibName,
            bundle: Bundle(for: type(of: self))
        )
        self.url = url

        navigationItem.hidesBackButton = true
        
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                style: .done,
                target: self,
                action: #selector(handleClose)
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .stop, // 'X' image pre iOS 13
                target: self,
                action: #selector(handleClose)
            )
         }
    }

    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)

        // injected script exposes `cesdk.postMessage()` to Narwhal
        let postMessageScript = WKUserScript(
            source: """
            window.cesdk = {
              postMessage: function (data) {
                  window.webkit.messageHandlers.cesdk.postMessage(JSON.parse(data));
              }
            }
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        let wvc = WKWebViewConfiguration()
        wvc.applicationNameForUserAgent = RemitlyCeConfiguration.userAgentApplicationName
        wvc.suppressesIncrementalRendering = true
        wvc.dataDetectorTypes = []
        wvc.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        if #available(iOS 13.0, *) {
            wvc.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        
        wvc.userContentController.add(self, name: NarwhalMessageKey.handler.rawValue)
        wvc.userContentController.addUserScript(postMessageScript)

        webView = WKWebView(frame: webViewContainer.bounds, configuration: wvc)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self

        webViewContainer.addSubview(webView)

        loadWeb()
        
        EventLogger.shared.logHumio(topic: "openWebView",
                        data: [
                            "url": AnyCodable(url)
                        ])
    }

    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        self.isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        self.isLoading = false
        saveCookies()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.error = error
        self.isLoading = false;
    }
    
    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        self.error = error
        self.isLoading = false;
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let destinationUrl = navigationAction.request.url else {
            decisionHandler(.allow);
            return;
        }
        
        // open in a new controller if we're navigating to a receipt (that isn't already being shown)
        if
            self.url != destinationUrl,
            !self.url.path.contains("/receipt/"),
            destinationUrl.path.contains("/receipt/")
        {
            presentCE(destinationUrl)
            decisionHandler(.cancel)
            return;
        }
        
        // certain links open in Safari controller
        let fullBrowserPaths = [
            "help.remitly.com",
            "/users/forgot_password",
            "/home/policy",
            "/home/privacy_policy",
            "/home/agreement"
        ]

        if (fullBrowserPaths.contains {
            return destinationUrl.absoluteString.contains($0)
        }) {
            presentSafari(destinationUrl)
            decisionHandler(.cancel);
            return;
        }

        decisionHandler(.allow);
    }
    
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard
            message.name == NarwhalMessageKey.handler.rawValue,
            let body = message.body as? NSDictionary,
            let rawTopic = body[NarwhalMessageKey.topic.rawValue] as? String,
            let topic = NarwhalMessageTopic(rawValue: rawTopic )
        else {
            return
        }
        
        switch topic {
        case .openLoginPage:
            loadWeb()
            break
        case .exitCE:
            exitCE(.web)
            break
        case .hideCloseButton:
            isCloseButtonHidden = true
            break
        case .openHelpCenter:
            if let payload = body[NarwhalMessageKey.payload.rawValue] as? String {
                if let url = URL(string: payload) {
                    presentSafari(url)
                }
            }
            break
        case .event:
            if let payload = body[NarwhalMessageKey.payload.rawValue] as? NSDictionary {
                if let eventType = NarwhalEventType(rawValue: payload[NarwhalMessageKey.eventType.rawValue] as! String) {
                    handleEvent(eventType)
                }
            }
            break
        }
    }
    
    private func saveCookies() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            cookies.forEach { cookie in
                HTTPCookieStorage.shared.setCookie(cookie)
                if (cookie.name == "de_id") {
                    RemitlyCeConfiguration.deviceEnvironmentId = cookie.value
                }
            }
        }
    }
    
    private func restoreCookies(completion: (() -> Void)? = nil) {
        if let cookies = HTTPCookieStorage.shared.cookies {
            DispatchQueue.main.async {
                let group = DispatchGroup()
                cookies.forEach { cookie in
                    group.enter()
                    self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                        group.leave()
                    }
                }
                
                // This cookie is needed for Portal to redirect users to the correct landing pages
                if let webUrl = try? RemitlyCeConfiguration.webUrl {
                    let cookieProps: [HTTPCookiePropertyKey : Any] = [
                        HTTPCookiePropertyKey.domain: self.url.host as Any,
                        HTTPCookiePropertyKey.path: "/",
                        HTTPCookiePropertyKey.name: "ce_login_redirect",
                        HTTPCookiePropertyKey.value: webUrl.lastPathComponent + "?" + (webUrl.query ?? ""),
                    ]

                    if let loginRedirectCookie = HTTPCookie(properties: cookieProps) {
                        group.enter()
                        self.webView.configuration.websiteDataStore.httpCookieStore.setCookie(loginRedirectCookie) {
                            group.leave()
                        }
                    }
                }

                group.notify(queue: DispatchQueue.main) {
                    completion?()
                }
            }
        }
    }

    private func loadWeb()  {
        self.error = nil
        restoreCookies() {
            let request = URLRequest(url: self.url)
            self.webView.load(request)
        }
    }
    
    private func presentCE(_ url: URL) {
        self.present(UINavigationController(rootViewController: RemitlyCeWebViewController(url: url)), animated: true)
    }
    
    private func presentSafari(_ url: URL) {
        let svc = SFSafariViewController(url: url)
        svc.modalPresentationStyle = .pageSheet
        self.present(svc, animated: true)
    }
    
    private func handleEvent(_ eventType: NarwhalEventType) {
        switch eventType {
        case .userActivity:
            delegate?.onUserActivity?()
            break
        case .transferSubmitted:
            delegate?.onTransferSubmitted?()
            break
        }
    }

    @objc private func handleClose() {
        exitCE(.native)
    }

    private func exitCE(_ closeRequestKind: CloseRequestKind) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        EventLogger.shared.logHumio(topic: "closeWebView",
                        data: [
                            "url": AnyCodable(self.url),
                            "closeReason": AnyCodable(closeRequestKind.rawValue)
                        ])
    }
}
