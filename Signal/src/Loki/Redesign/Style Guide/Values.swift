
@objc(LKValues)
final class Values : NSObject {
    
    // MARK: - Alpha Values
    @objc static let unimportantElementOpacity = CGFloat(0.6)
    @objc static let conversationCellTimestampOpacity = CGFloat(0.4)
    @objc static let textFieldBorderOpacity = CGFloat(0.4)
    @objc static let modalBackgroundOpacity = CGFloat(0.75)
    
    // MARK: - Font Sizes
    @objc static let verySmallFontSize = CGFloat(10)
    @objc static let smallFontSize = CGFloat(13)
    @objc static let mediumFontSize = CGFloat(15)
    @objc static let largeFontSize = CGFloat(20)
    @objc static let veryLargeFontSize = CGFloat(25)
    @objc static let massiveFontSize = CGFloat(50)
    
    // MARK: - Element Sizes
    @objc static let mediumButtonHeight = CGFloat(34)
    @objc static let largeButtonHeight = CGFloat(45)
    @objc static let accentLineThickness = CGFloat(4)
    @objc static let verySmallProfilePictureSize = CGFloat(26)
    @objc static let smallProfilePictureSize = CGFloat(35)
    @objc static let mediumProfilePictureSize = CGFloat(45)
    @objc static let largeProfilePictureSize = CGFloat(75)
    @objc static let borderThickness = CGFloat(1)
    @objc static let conversationCellStatusIndicatorSize = CGFloat(14)
    @objc static let searchBarHeight = CGFloat(36)
    @objc static let newConversationButtonSize = CGFloat(45)
    @objc static let textFieldHeight = CGFloat(80)
    @objc static let textFieldCornerRadius = CGFloat(8)
    @objc static let separatorLabelHeight = CGFloat(24)
    @objc static var separatorThickness: CGFloat { return 1 / UIScreen.main.scale }
    @objc static let tabBarHeight = CGFloat(48)
    @objc static let settingButtonHeight = CGFloat(75)
    @objc static let modalCornerRadius = CGFloat(10)
    @objc static let modalButtonCornerRadius = CGFloat(5)
    @objc static let fakeChatBubbleWidth = CGFloat(224)
    @objc static let fakeChatBubbleCornerRadius = CGFloat(10)
    @objc static let fakeChatViewHeight = CGFloat(320)
    
    // MARK: - Distances
    @objc static let verySmallSpacing = CGFloat(4)
    @objc static let smallSpacing = CGFloat(8)
    @objc static let mediumSpacing = CGFloat(16)
    @objc static let largeSpacing = CGFloat(24)
    @objc static let veryLargeSpacing = CGFloat(35)
    @objc static let massiveSpacing = CGFloat(64)
    @objc static let newConversationButtonBottomOffset = CGFloat(52)
    @objc static let onboardingButtonBottomOffset = CGFloat(72)
    
    // MARK: - Animation Values
    @objc static let fakeChatStartDelay: TimeInterval = 2
    @objc static let fakeChatAnimationDuration: TimeInterval = 0.4
    @objc static let fakeChatDelay: TimeInterval = 4
    @objc static let fakeChatMessagePopAnimationStartScale: CGFloat = 0.6
}
