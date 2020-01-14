//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//
// Workaround aufgrund von Bug
// https://stackoverflow.com/questions/57246685/uiviewcontrollerrepresentable-and-cncontactpickerviewcontroller
// Dank gilt: https://stackoverflow.com/users/435040/arturgrigor
//

import Foundation
import ContactsUI

protocol EmbeddedContactPickerViewControllerDelegate: class {
    func embeddedContactPickerViewControllerDidCancel(_ viewController: EmbeddedContactPickerViewController)
    func embeddedContactPickerViewController(_ viewController: EmbeddedContactPickerViewController, didSelect contact: CNContact)
}

class EmbeddedContactPickerViewController: UIViewController, CNContactPickerDelegate {
    weak var delegate: EmbeddedContactPickerViewControllerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.open(animated: animated)
    }

    private func open(animated: Bool) {
        let viewController = CNContactPickerViewController()
        viewController.delegate = self
        viewController.modalPresentationStyle = .currentContext
        self.present(viewController, animated: false)
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        self.dismiss(animated: false) {
            self.delegate?.embeddedContactPickerViewControllerDidCancel(self)
        }
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        self.delegate?.embeddedContactPickerViewController(self, didSelect: contact)
    }

}
