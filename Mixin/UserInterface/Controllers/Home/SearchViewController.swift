import UIKit

class SearchViewController: UIViewController {
    
    enum ReuseId {
        static let header = "header"
        static let footer = "footer"
    }
    
    enum Section: Int, CaseIterable {
        case searchNumber = 0
        case asset
        case contact
        case group
        case message
        
        var title: String? {
            switch self {
            case .searchNumber:
                return nil
            case .asset:
                return R.string.localizable.search_section_title_assets()
            case .contact:
                return R.string.localizable.search_section_title_contacts()
            case .group:
                return R.string.localizable.search_section_title_group()
            case .message:
                return R.string.localizable.search_section_title_messages()
            }
        }
    }
    
    @IBOutlet weak var searchBox: SearchBoxView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recentBotsContainerView: UIView!
    
    private let searchingFooterView = R.nib.searchingFooterView(owner: nil)
    private let resultLimit = 3
    
    private var queue = OperationQueue()
    private var assets = [AssetSearchResult]()
    private var contacts = [ConversationSearchResult]()
    private var groups = [ConversationSearchResult]()
    private var conversations = [ConversationSearchResult]()
    
    private var textField: UITextField {
        return searchBox.textField
    }
    
    private var keywordMaybeIdOrPhone: Bool {
        return textField.text?.isNumeric ?? false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queue.maxConcurrentOperationCount = 1
        tableView.register(SearchHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: ReuseId.header)
        tableView.register(SearchFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ReuseId.footer)
        tableView.register(R.nib.searchResultCell)
        tableView.register(R.nib.assetCell)
        let tableHeaderView = UIView()
        tableHeaderView.frame = CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude)
        tableView.tableHeaderView = tableHeaderView
        tableView.dataSource = self
        tableView.delegate = self
        textField.addTarget(self, action: #selector(searchAction(_:)), for: .editingChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(contactsDidChange(_:)), name: .ContactsDidChange, object: nil)
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        guard !super.becomeFirstResponder() else {
            return false
        }
        return textField.becomeFirstResponder()
    }
    
    @IBAction func searchAction(_ sender: Any) {
        guard let keyword = textField.text?.lowercased(), !keyword.isEmpty else {
            tableView.isHidden = true
            recentBotsContainerView.isHidden = false
            return
        }
        tableView.isHidden = false
        recentBotsContainerView.isHidden = true
        let limit = self.resultLimit
        let op = BlockOperation()
        op.addExecutionBlock { [unowned op, weak self] in
            guard self != nil, !op.isCancelled else {
                return
            }
            let assets = AssetDAO.shared.getAssets(keyword: keyword, limit: limit)
                .map { AssetSearchResult(asset: $0, keyword: keyword) }
            let contacts = UserDAO.shared.getUsers(keyword: keyword, limit: limit)
                .map { ConversationSearchResult(user: $0, keyword: keyword) }
            let groups = ConversationDAO.shared.getGroupConversation(nameLike: keyword, limit: limit)
                .map { ConversationSearchResult(group: $0, keyword: keyword) }
            let conversations = ConversationDAO.shared.getConversation(withMessageLike: keyword, limit: limit)
            guard let weakSelf = self, !op.isCancelled else {
                return
            }
            DispatchQueue.main.sync {
                weakSelf.assets = assets
                weakSelf.contacts = contacts
                weakSelf.groups = groups
                weakSelf.conversations = conversations
                weakSelf.tableView.reloadData()
            }
        }
        queue.addOperation(op)
    }
    
    func prepare() {
        
    }
    
    @objc func contactsDidChange(_ notification: Notification) {
        
    }
    
    private func isEmptySection(_ section: Section) -> Bool {
        switch section {
        case .searchNumber:
            return !keywordMaybeIdOrPhone
        case .asset:
            return assets.isEmpty
        case .contact:
            return contacts.isEmpty
        case .group:
            return groups.isEmpty
        case .message:
            return conversations.isEmpty
        }
    }
    
    private func isFirstSection(_ section: Section) -> Bool {
        switch section {
        case .searchNumber:
            return keywordMaybeIdOrPhone
        case .asset:
            return !keywordMaybeIdOrPhone
        case .contact:
            return !keywordMaybeIdOrPhone && assets.isEmpty
        case .group:
            return !keywordMaybeIdOrPhone && assets.isEmpty && contacts.isEmpty
        case .message:
            return !keywordMaybeIdOrPhone && assets.isEmpty && contacts.isEmpty && groups.isEmpty
        }
    }
    
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .searchNumber:
            return keywordMaybeIdOrPhone ? 1 : 0
        case .asset:
            return assets.count
        case .contact:
            return contacts.count
        case .group:
            return groups.count
        case .message:
            return conversations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .searchNumber:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.search_number, for: indexPath)!
            if let keyword = textField.text {
                cell.render(number: keyword)
            }
            return cell
        case .asset:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.asset, for: indexPath)!
            let result = assets[indexPath.row]
            cell.render(asset: result.asset, attributedSymbol: result.attributedSymbol)
            return cell
        case .contact:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.search_result, for: indexPath)!
            cell.render(result: contacts[indexPath.row])
            return cell
        case .group:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.search_result, for: indexPath)!
            cell.render(result: groups[indexPath.row])
            return cell
        case .message:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.search_result, for: indexPath)!
            cell.render(result: conversations[indexPath.row])
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .searchNumber:
            return UITableView.automaticDimension
        case .asset, .contact, .group, .message:
            return SearchResultCell.height
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .searchNumber:
            return .leastNormalMagnitude
        case .asset, .contact, .group, .message:
            if isEmptySection(section) {
                return .leastNormalMagnitude
            } else {
                return SearchHeaderView.height(isFirstSection: isFirstSection(section))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let section = Section(rawValue: section)!
        switch section {
        case .searchNumber:
            return .leastNormalMagnitude
        case .asset, .contact, .group, .message:
            return isEmptySection(section) ? .leastNormalMagnitude : SearchFooterView.height
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = Section(rawValue: section)!
        switch section {
        case .searchNumber:
            return nil
        case .asset, .contact, .group, .message:
            if isEmptySection(section) {
                return nil
            } else {
                let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseId.header) as! SearchHeaderView
                view.isFirstSection = isFirstSection(section)
                view.label.text = section.title
                return view
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let section = Section(rawValue: section)!
        switch section {
        case .searchNumber:
            return nil
        case .asset, .contact, .group, .message:
            if isEmptySection(section) {
                return nil
            } else {
                return tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseId.footer)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
