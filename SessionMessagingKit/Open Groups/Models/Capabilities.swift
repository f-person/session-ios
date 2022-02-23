// Copyright © 2022 Rangeproof Pty Ltd. All rights reserved.

import Foundation

extension OpenGroupAPI {
    public struct Capabilities: Codable {
        public enum Capability: Equatable, CaseIterable, Codable {
            public static var allCases: [Capability] {
                [.sogs, .blind]
            }
            
            case sogs
            case blind
            
            /// Fallback case if the capability isn't supported by this version of the app
            case unsupported(String)
            
            // MARK: - Convenience
            
            public var rawValue: String {
                switch self {
                    case .unsupported(let originalValue): return originalValue
                    default: return "\(self)"
                }
            }
            
            // MARK: - Codable
            
            public init(from valueString: String) {
                let maybeValue: Capability? = Capability.allCases.first { $0.rawValue == valueString }

                self = (maybeValue ?? .unsupported(valueString))
            }
        }
        
        public let capabilities: [Capability]
        public let missing: [Capability]?
    }
}

extension OpenGroupAPI.Capabilities.Capability {
    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        let container: SingleValueDecodingContainer = try decoder.singleValueContainer()
        let valueString: String = try container.decode(String.self)
        
        self = OpenGroupAPI.Capabilities.Capability(from: valueString)
    }
}
