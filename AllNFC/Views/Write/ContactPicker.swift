//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {

    final class Coordinator: NSObject, EmbeddedContactPickerViewControllerDelegate {
        
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func embeddedContactPickerViewController(_ viewController: EmbeddedContactPickerViewController, didSelect contact: CNContact) {
            let selectedContact = ContactItem(contact: contact)
            parent.selectedContact = selectedContact
            parent.contactsStore.contactItems.append(selectedContact)
            
            parent.presentationMode.wrappedValue.dismiss()
        }

        func embeddedContactPickerViewControllerDidCancel(_ viewController: EmbeddedContactPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var contactsStore: ContactsStore
    var selectedContact: ContactItem?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ContactPicker>) -> EmbeddedContactPickerViewController {
        let result = EmbeddedContactPickerViewController()
        result.delegate = context.coordinator
        return result
    }

    func updateUIViewController(_ uiViewController: EmbeddedContactPickerViewController, context: UIViewControllerRepresentableContext<ContactPicker>) { }
}
