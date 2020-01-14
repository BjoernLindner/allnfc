//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import SwiftUI

struct TagReadRecordView: View {
    
    let record: MyTagRecord
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack {
                    if self.record.type == "text/x-vCard" {
                        CNContactView(contact: self.record.contentAsVCard)
                    } else {
                        Text("Dieser Datensatz ist keine vCard, sondern ein anderes Medienformat")
                            .padding()
                    }
                }
                Spacer(minLength: 25)
            }
        }
        .navigationBarTitle(Text(record.typeNameFormat))
    }
}

struct TagReadRecordView_Previews: PreviewProvider {
    
    static let record = MyTagRecord(typeNameFormat: "media", type: "text/x-vCard", content: """
BEGIN:VCARD

    VERSION:3.0

    N:Muster;Max;;;

    FN:Max Muster

    END:VCARD
""")
    
    static var previews: some View {
        TagReadRecordView(record: record)
    }
}
