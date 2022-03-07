import UIKit

class ExportTransactionsWindow: BottomSheetView {
    
    @IBOutlet weak var exportButton: RoundedButton!
    @IBOutlet weak var startDateButton: UIButton!
    @IBOutlet weak var endDateButton: UIButton!
    
    private let today = DateFormatter.yyyymmddDate.string(from: Date())
    
    override func awakeFromNib() {
        super.awakeFromNib()
        exportButton.isEnabled = false
        endDateButton.setTitle(today, for: .normal)
    }
    
    class func instance() -> ExportTransactionsWindow {
        R.nib.exportTransactionsWindow(owner: self)!
    }
    
    @IBAction func selectStartDateAction(_ sender: Any) {
        presentDatePicker(target: startDateButton)
    }
    
    @IBAction func selectEndDateAction(_ sender: Any) {
        presentDatePicker(target: endDateButton)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        dismissPopupControllerAnimated()
    }
    
    @IBAction func exportAction(_ sender: Any) {
        
    }
    
    private func presentDatePicker(target: UIButton) {
        let title: String
        let maximumDate: String
        if target.isEqual(endDateButton) {
            title = R.string.localizable.transaction_export_end_date()
            maximumDate = today
        } else {
            title = R.string.localizable.transaction_export_start_date()
            maximumDate = endDateButton.titleLabel?.text ?? today
        }
        let window = DatePickerWindow.instance(title: title,
                                               currentDate: target.titleLabel?.text,
                                               maximumDate: maximumDate)
        window.selectCompletion = { date in
            self.updateSelectedDate(date, for: target)
        }
        window.presentPopupControllerAnimated()
    }
    
    private func updateSelectedDate(_ date: String, for target: UIButton) {
        let startDateTitle = R.string.localizable.transaction_export_start_date()
        target.setTitle(date, for: .normal)
        if target.isEqual(startDateButton) {
            startDateButton.setTitleColor(.title, for: .normal)
        } else if date < startDateButton.titleLabel?.text ?? "" {
            startDateButton.setTitle(startDateTitle, for: .normal)
            startDateButton.setTitleColor(R.color.text_desc(), for: .normal)
        }
        exportButton.isEnabled = startDateButton.titleLabel?.text != startDateTitle
    }
    
}
