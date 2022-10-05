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
    @objc public static var endpoint: String?
    @objc public static var appID: String?
    @objc public static var defaultSendCountry: String?
    @objc public static var defaultReceiveCountry: String?
    @objc public static var customerEmail: String?
    @objc public static var languageCode: String?
    @objc public static var ceVersion: String {
        RemitlyCeVersion()
    }

    @objc public static func loadConfig() {
        let options = Bundle.main.infoDictionary?["remitly"] as? NSDictionary
        if let endpoint = options?["endpoint"] as? String {
            self.endpoint = endpoint
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
    
    internal static var url: URL {
        get throws {
            guard let appID = appID else {
                throw RemitlyCeError.invalidAppID
            }
            guard var components = URLComponents(string: endpoint!) else {
                throw RemitlyCeError.invalidEndpoint
            }
            if components.scheme == nil {
                throw RemitlyCeError.invalidEndpoint
            }
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
