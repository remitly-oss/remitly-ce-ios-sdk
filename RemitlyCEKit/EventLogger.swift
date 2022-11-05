//
//  EventLogger.swift
//  RemitlyCEKit
//
//  Created by Nick Hodapp on 10/13/22.
//

import Foundation
import AnyCodable

internal class EventLogger {
    static internal let shared = EventLogger()
    
    let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter;
    }()
    let humioUrl: URL? = {
        return URL(string: "v1/humio", relativeTo: try? RemitlyCeConfiguration.apiUrl)
    }()
    var timer: Timer? = nil
    var events: Array<[String:AnyCodable]> = []
    
    private init() { /* use shared singleton */ }
    
    func logHumio(topic: String, data: [String:AnyCodable]? = nil) {
        if timer == nil {
            weak var logger = self
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { _ in
                if let events = logger?.events,
                   events.count > 0,
                   let url = logger?.humioUrl
                {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let encoder = JSONEncoder()
                    let wrapper = [
                        ["events": events]
                    ]
                    if let jsonData = try? encoder.encode(wrapper) {
                        request.httpBody = jsonData
                        URLSession.shared.dataTask(with: request).resume()
                    }
                    logger?.events.removeAll()
                }
                logger?.timer?.invalidate()
                logger?.timer = nil
            })
        }
        
        let timestamp: String = dateFormatter.string(from: Date())
        let event: [String:AnyCodable] = [
            "timestamp": AnyCodable(timestamp),
            "attributes": [
                "sdk": "ConnectedExperience",
                "topic": topic,
                "data": AnyCodable(data),
                "@timestamp": timestamp,
                "device_environment_id": AnyCodable(RemitlyCeConfiguration.deviceEnvironmentId),
                "forge": [
                    "app": "remitly-client",
                    "domain": RemitlyCeConfiguration.domain.rawValue,
                ],
                "env": [
                    "platform": "ios",
                    "locale": Locale.current.identifier,
                    "sdkVersion": RemitlyCeConfiguration.ceVersion
                ]
            ]
        ]
        events.append(event)
    }
}
