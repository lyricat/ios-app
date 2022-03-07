import UIKit

class DatePickerWindow: BottomSheetView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var selectCompletion: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 14, *) {
            datePicker.preferredDatePickerStyle = .inline
        } else if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
    }
    
    class func instance(title: String, currentDate: String?, maximumDate: String) -> DatePickerWindow {
        let window = R.nib.datePickerWindow(owner: self)!
        window.titleLabel.text = title
        window.datePicker.maximumDate = DateFormatter.yyyymmddDate.date(from: maximumDate)
        if let currentDate = currentDate, let date = DateFormatter.yyyymmddDate.date(from: currentDate) {
            window.datePicker.setDate(date, animated: false)
        }
        return window
    }
    
    @IBAction func closeAction(_ sender: Any) {
        dismissPopupControllerAnimated()
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        selectCompletion?(DateFormatter.yyyymmddDate.string(from: datePicker.date))
        dismissPopupControllerAnimated()
    }
    
}
