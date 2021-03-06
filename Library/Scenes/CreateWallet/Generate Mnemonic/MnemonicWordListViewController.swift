//
//  Zap
//
//  Created by Otto Suess on 16.04.18.
//  Copyright © 2018 Zap. All rights reserved.
//

import UIKit

extension UIStoryboard {
    static func instantiateMnemonicWordListViewController(with mnemonicWords: [MnemonicWord]) -> MnemonicWordListViewController {
        let viewController = Storyboard.createWallet.instantiate(viewController: MnemonicWordListViewController.self)
        viewController.mnemonicWords = mnemonicWords
        return viewController
    }
}

final class MnemonicWordListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    fileprivate var mnemonicWords: [MnemonicWord]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 58
        tableView.backgroundColor = .clear
        view.backgroundColor = .clear
    }
}

extension MnemonicWordListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mnemonicWords?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MnemonicWordTableViewCell = tableView.dequeueCellForIndexPath(indexPath)
        
        let word = mnemonicWords?[indexPath.row]
        cell.index = word?.index
        cell.word = word?.word
        
        return cell
    }
}
