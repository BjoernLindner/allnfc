//
//  AllNFC
//
//  Copyright © 2020 Björn Lindner. All rights reserved.
//

import ContactsUI

class ContactsStore: ObservableObject {
    @Published var contactItems: [ContactItem] = []
}
