//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import SwiftUI

struct MyTagRowView: View {
    var tag: MyTag
    
    var body: some View {
        List {
            Section(header: Text(tag.tagType)) {
                if !tag.tagTypeFamily.isEmpty {
                    Text(tag.tagTypeFamily)
                }
                Text("Kapazität: \(tag.capacity) Byte")
                
                ForEach(tag.records) { record in
                    if (record.typeNameFormat == "media" && record.type == "text/x-vCard") {
                        NavigationLink(destination: TagReadRecordView(record: record)) {
                            VStack(alignment: .leading) {
                                Text("vCard")
                                    .font(.headline)
                                Spacer()
                                Text("\(record.contentAsVCard.givenName) \(record.contentAsVCard.familyName)")
                            }
                        }
                    } else if (record.typeNameFormat == "media") {
                        VStack(alignment: .leading) {
                            Text("Media")
                                .font(.headline)
                            Spacer()
                            Text("Muss noch implementiert werden")
                        }
                    } else if (record.typeNameFormat == "absolutURI") {
                        VStack(alignment: .leading) {
                            Text("Homepage")
                                .font(.headline)
                            Spacer()
                            Text("\(record.content)")
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Text")
                                .font(.headline)
                            Spacer()
                            Text("\(record.content)")
                        }
                    }
                }
            }
        }
    }
}

struct MyTagRowView_Previews: PreviewProvider {
    static let tag = MyTag(tagType: "Dummy Tag", tagTypeFamily: "DummyTagFamily", capacity: 47, readOnly: true, records: [])
    
    static var previews: some View {
        MyTagRowView(tag: tag)
    }
}
