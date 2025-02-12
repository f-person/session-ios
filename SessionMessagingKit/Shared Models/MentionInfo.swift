// Copyright © 2022 Rangeproof Pty Ltd. All rights reserved.

import GRDB
import SessionUtilitiesKit

public struct MentionInfo: FetchableRecord, Decodable {
    fileprivate static let threadVariantKey: SQL = SQL(stringLiteral: CodingKeys.threadVariant.stringValue)
    fileprivate static let openGroupServerKey: SQL = SQL(stringLiteral: CodingKeys.openGroupServer.stringValue)
    fileprivate static let openGroupRoomTokenKey: SQL = SQL(stringLiteral: CodingKeys.openGroupRoomToken.stringValue)
    
    fileprivate static let profileString: String = CodingKeys.profile.stringValue
    
    public let profile: Profile
    public let threadVariant: SessionThread.Variant
    public let openGroupServer: String?
    public let openGroupRoomToken: String?
}

public extension MentionInfo {
    static func query(
        userPublicKey: String,
        threadId: String,
        threadVariant: SessionThread.Variant,
        targetPrefix: SessionId.Prefix,
        pattern: FTS5Pattern?
    ) -> AdaptedFetchRequest<SQLRequest<MentionInfo>>? {
        guard threadVariant != .contact || userPublicKey != threadId else { return nil }
        
        let profile: TypedTableAlias<Profile> = TypedTableAlias()
        let interaction: TypedTableAlias<Interaction> = TypedTableAlias()
        let openGroup: TypedTableAlias<OpenGroup> = TypedTableAlias()
        let groupMember: TypedTableAlias<GroupMember> = TypedTableAlias()
        
        let prefixLiteral: SQL = SQL(stringLiteral: "\(targetPrefix.rawValue)%")
        let profileFullTextSearch: SQL = SQL(stringLiteral: Profile.fullTextSearchTableName)
        
        /// The query needs to differ depending on the thread variant because the behaviour should be different:
        ///
        /// **Contact:** We should show the profile directly (filtered out if the pattern doesn't match)
        /// **Closed Group:** We should show all profiles within the group, filtered by the pattern
        /// **Open Group:** We should show only the 20 most recent profiles which match the pattern
        let request: SQLRequest<MentionInfo> = {
            let hasValidPattern: Bool = (pattern != nil && pattern?.rawPattern != "\"\"*")
            let targetJoin: SQL = {
                guard hasValidPattern else { return "FROM \(Profile.self)" }
                
                return """
                    FROM \(profileFullTextSearch)
                    JOIN \(Profile.self) ON (
                        \(Profile.self).rowid = \(profileFullTextSearch).rowid AND
                        \(SQL("\(profile[.id]) != \(userPublicKey)")) AND (
                            \(SQL("\(threadVariant) != \(SessionThread.Variant.openGroup)")) OR
                            \(SQL("\(profile[.id]) LIKE '\(prefixLiteral)'"))
                        )
                    )
                """
            }()
            let targetWhere: SQL = {
                guard let pattern: FTS5Pattern = pattern, pattern.rawPattern != "\"\"*" else {
                    return """
                        WHERE (
                            \(SQL("\(profile[.id]) != \(userPublicKey)")) AND (
                                \(SQL("\(threadVariant) != \(SessionThread.Variant.openGroup)")) OR
                                \(SQL("\(profile[.id]) LIKE '\(prefixLiteral)'"))
                            )
                        )
                    """
                }
                
                let matchLiteral: SQL = SQL(stringLiteral: "\(Profile.Columns.nickname.name):\(pattern.rawPattern) OR \(Profile.Columns.name.name):\(pattern.rawPattern)")
                
                return "WHERE \(profileFullTextSearch) MATCH '\(matchLiteral)'"
            }()
            
            switch threadVariant {
                case .contact:
                    return SQLRequest("""
                        SELECT
                            \(Profile.self).*,
                            \(SQL("\(threadVariant) AS \(MentionInfo.threadVariantKey)"))
                    
                        \(targetJoin)
                        \(targetWhere) AND \(SQL("\(profile[.id]) = \(threadId)"))
                    """)
                    
                case .closedGroup:
                    return SQLRequest("""
                        SELECT
                            \(Profile.self).*,
                            \(SQL("\(threadVariant) AS \(MentionInfo.threadVariantKey)"))
                    
                        \(targetJoin)
                        JOIN \(GroupMember.self) ON (
                            \(SQL("\(groupMember[.groupId]) = \(threadId)")) AND
                            \(groupMember[.profileId]) = \(profile[.id]) AND
                            \(SQL("\(groupMember[.role]) = \(GroupMember.Role.standard)"))
                        )
                        \(targetWhere)
                        GROUP BY \(profile[.id])
                        ORDER BY IFNULL(\(profile[.nickname]), \(profile[.name])) ASC
                    """)
                    
                case .openGroup:
                    return SQLRequest("""
                        SELECT
                            \(Profile.self).*,
                            MAX(\(interaction[.timestampMs])),  -- Want the newest interaction (for sorting)
                            \(SQL("\(threadVariant) AS \(MentionInfo.threadVariantKey)")),
                            \(openGroup[.server]) AS \(MentionInfo.openGroupServerKey),
                            \(openGroup[.roomToken]) AS \(MentionInfo.openGroupRoomTokenKey)
                    
                        \(targetJoin)
                        JOIN \(Interaction.self) ON (
                            \(SQL("\(interaction[.threadId]) = \(threadId)")) AND
                            \(interaction[.authorId]) = \(profile[.id])
                        )
                        JOIN \(OpenGroup.self) ON \(SQL("\(openGroup[.threadId]) = \(threadId)"))
                        \(targetWhere)
                        GROUP BY \(profile[.id])
                        ORDER BY \(interaction[.timestampMs].desc)
                        LIMIT 20
                    """)
            }
        }()
        
        return request.adapted { db in
            let adapters = try splittingRowAdapters(columnCounts: [
                Profile.numberOfSelectedColumns(db)
            ])
            
            return ScopeAdapter([
                MentionInfo.profileString: adapters[0]
            ])
        }
    }
}
