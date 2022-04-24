import Foundation
import MixinServices

enum ScreenLockTimeFormatter {
    
    static func string(from timeInterval: TimeInterval) -> String {
        if timeInterval == 0 {
            return R.string.localizable.immediately()
        } else if timeInterval == 60 * 60 {
            return R.string.localizable.one_hour()
        } else if timeInterval == 60 {
            return R.string.localizable.one_minute()
        } else {
            return R.string.localizable.wallet_pin_pay_interval_minutes_count(Int(timeInterval / 60))
        }
    }
    
}
