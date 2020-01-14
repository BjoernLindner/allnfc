//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import Foundation
import Contacts

struct MyTag: Identifiable {
    let id = UUID()
    
    let tagType: String
    let tagTypeFamily: String
    
    var capacity: Int = 0
    var readOnly: Bool = false
    
    var records: [MyTagRecord] = []
}

struct MyTagRecord: Identifiable {
    let id = UUID()
    
    let typeNameFormat: String
    let type: String
    
    let content: String
}

extension MyTagRecord {
    var contentAsVCard: CNContact {
        if typeNameFormat == "media" && type == "text/x-vCard" {
            guard let data = content.data(using: .utf8) else {
                fatalError("Data von Payload kann nicht erstellt werden")
            }
            var contacts = [CNContact]()
            
            do{
                contacts = try CNContactVCardSerialization.contacts(with: data)
            }
            catch{
                // Error Handling
                print(error.localizedDescription)
            }
            
            guard let contact = contacts.first else {
                // Error Handling
                fatalError("Konnte keinen Kontakt finden.")
            }
            
            return contact
            
        } else {
            // Error Handling
            fatalError("Das ist keine VCard")
        }
    }
}
