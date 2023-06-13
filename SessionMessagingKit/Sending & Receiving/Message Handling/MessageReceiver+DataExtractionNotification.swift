// Copyright © 2022 Rangeproof Pty Ltd. All rights reserved.

import Foundation
import GRDB
import SessionSnodeKit

extension MessageReceiver {
    internal static func handleDataExtractionNotification(
        _ db: Database,
        threadId: String,
        threadVariant: SessionThread.Variant,
        message: DataExtractionNotification
    ) throws {
        guard
            threadVariant == .contact,
            let sender: String = message.sender,
            let messageKind: DataExtractionNotification.Kind = message.kind
        else { throw MessageReceiverError.invalidMessage }
        
        _ = try Interaction(
            serverHash: message.serverHash,
            threadId: threadId,
            authorId: sender,
            variant: {
                switch messageKind {
                    case .screenshot: return .infoScreenshotNotification
                    case .mediaSaved: return .infoMediaSavedNotification
                }
            }(),
            timestampMs: (
                message.sentTimestamp.map { Int64($0) } ??
                SnodeAPI.currentOffsetTimestampMs()
            )
        ).inserted(db)
    }
}
