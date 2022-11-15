//
//  Configuration.swift
//  RemitlyCE
//
//  Created by Nick Hodapp on 8/22/22.
//

import Foundation

public enum RemitlyCeError: Error {
    case invalidConfiguration
    case invalidEndpoint
    case invalidAppID
    case invalidSendCountry
    case invalidReceiveCountry
    case invalidLanguageCode
}

@objc(RECEConfiguration) public class RemitlyCeConfiguration: NSObject {
    
    enum Domain: String {
        case prod = "prod"
        case dev = "dev"
        case staging = "staging"
    }
    
    private static let prodWebHost = "www.remitly.com"
    private static let prodApiHost = "api.remitly.io"
    
    @objc public static var webHost: String?
    @objc public static var apiHost: String?
    @objc public static var appID: String?
    @objc public static var defaultSendCountry: String?
    @objc public static var defaultReceiveCountry: String?
    @objc public static var customerEmail: String?
    @objc public static var languageCode: String?
    @objc public static var ceVersion: String {
        RemitlyCeVersion()
    }
    
    internal static var domain: Domain {
        switch (try? apiUrl.host, try? webUrl.host)  {
        case (prodApiHost, prodWebHost):
            return .prod
        case (.some(let a), .some(let w)) where a.contains("preprod") && w.contains("preprod"):
            return .staging
        default:
            return .dev
        }
    }
    
    internal static var deviceEnvironmentId: String? {
        get {
            return UserDefaults.standard.string(forKey: "com.remitly.deid")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "com.remitly.deid")
        }
    }

    @objc public static func loadConfig() {
        let options = Bundle.main.infoDictionary?["remitly"] as? NSDictionary

        if let webHost = options?["webHost"] as? String {
            self.webHost = webHost
        }

        if let apiHost = options?["apiHost"] as? String {
            self.apiHost = apiHost
        }

        if let appID = options?["appID"] as? String {
            self.appID = appID
        }

        if let defaultSendCountry = options?["defaultSendCountry"] as? String {
            self.defaultSendCountry = defaultSendCountry
        }

        if let defaultReceiveCountry = options?["defaultReceiveCountry"] as? String {
            self.defaultReceiveCountry = defaultReceiveCountry
        }
    }
    
    internal static var apiUrl: URL {
        get throws {
            var components = URLComponents()
            components.scheme = "https"
            components.host = self.apiHost ?? self.prodApiHost
            guard let url = components.url else {
                throw RemitlyCeError.invalidEndpoint
            }
            return url
        }
    }
    
    internal static var webUrl: URL {
        get throws {
            guard let appID = appID else {
                throw RemitlyCeError.invalidAppID
            }
            var components = URLComponents()
            components.scheme = "https"
            components.host = self.webHost ?? self.prodWebHost
            components.scheme = "https"
            if (defaultSendCountry != nil && defaultSendCountry?.count != 3) {
                throw RemitlyCeError.invalidSendCountry
            }
            if (defaultReceiveCountry != nil && defaultReceiveCountry?.count != 3) {
                throw RemitlyCeError.invalidReceiveCountry
            }
            components.queryItems = [
                URLQueryItem(name: "utm_medium", value: "channelpartner"),
                URLQueryItem(name: "utm_source", value: appID)
            ]
            if let customerEmail = customerEmail {
                components.queryItems?.append(
                    URLQueryItem(name: "email_prefill", value: customerEmail.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
                )
            }
            guard var url = components.url else {
                throw RemitlyCeError.invalidConfiguration
            }
            url.appendPathComponent(defaultSendCountry?.uppercased() ?? "USA")
            url.appendPathComponent(languageCode ?? Locale.current.languageCode ?? "en")
            url.appendPathComponent(defaultReceiveCountry?.uppercased() ?? "PHL")
            url.appendPathComponent(appID)
            return url;
        }
    }
    
    internal static var userAgentApplicationName: String {
        get {
            return "RemitlyCE/\(ceVersion)"
        }
    }
}
