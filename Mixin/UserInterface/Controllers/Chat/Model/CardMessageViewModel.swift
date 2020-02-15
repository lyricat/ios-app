import UIKit

class CardMessageViewModel: DetailInfoMessageViewModel {
    
    static let spacing: CGFloat = 12
    
    override class var bubbleImageSet: BubbleImageSet.Type {
        return LightRightBubbleImageSet.self
    }
    
    override class var quotedMessageMargin: Margin {
        Margin(leading: 9, trailing: 2, top: 1, bottom: 0)
    }
    
    class var leftViewSideLength: CGFloat {
        40
    }
    
    let receivedLeftMargin: CGFloat = 22
    let sentLeftMargin: CGFloat = 12
    let maxRightMargin: CGFloat = 24
    let minRightMargin: CGFloat = 10
    let minContentWidth: CGFloat = 140
    
    override var maxContentWidth: CGFloat {
        240
    }
    
    var contentWidth: CGFloat = 220
    
    var fullnameHeight: CGFloat {
        style.contains(.fullname) ? fullnameFrame.height : 0
    }
    
    private(set) var leadingConstant: CGFloat = 0
    private(set) var trailingConstant: CGFloat = 0
    
    private var contentHeight: CGFloat {
        var height: CGFloat = 72
        if let viewModel = quotedMessageViewModel {
            height += Self.quotedMessageMargin.vertical + viewModel.contentSize.height
        }
        return height
    }
    
    override func quoteViewLayoutWidth(from width: CGFloat) -> CGFloat {
        contentWidth - Self.quotedMessageMargin.horizontal
    }
    
    override func layout(width: CGFloat, style: MessageViewModel.Style) {
        if style.contains(.received) {
            leadingConstant = receivedLeftMargin
        } else {
            leadingConstant = sentLeftMargin
        }
        
        switch leadingConstant + contentWidth + maxRightMargin {
        case ...minContentWidth:
            trailingConstant = minContentWidth - leadingConstant - contentWidth
        case ...maxContentWidth:
            trailingConstant = maxRightMargin
        default:
            trailingConstant = minRightMargin
        }
        
        // Fill the space between canvas' edge and the bubble's
        if style.contains(.received) {
            trailingConstant += 2
        } else {
            trailingConstant += 9
        }
        
        contentWidth = leadingConstant + contentWidth + trailingConstant
        contentWidth = max(minContentWidth, min(maxContentWidth, contentWidth))
        
        super.layout(width: width, style: style)
        
        let x: CGFloat
        if style.contains(.received) {
            x = Self.bubbleMargin.leading
        } else {
            x = width - Self.bubbleMargin.leading - contentWidth
        }
        backgroundImageFrame = CGRect(x: x, y: fullnameHeight, width: contentWidth, height: contentHeight)
        cellHeight = fullnameHeight + backgroundImageFrame.height + timeFrame.height + timeMargin.bottom + bottomSeparatorHeight
        layoutDetailInfo(insideBackgroundImage: false, backgroundImageFrame: backgroundImageFrame)
        layoutQuotedMessageIfPresent()
    }
    
}
