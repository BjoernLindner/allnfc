//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import SwiftUI
import ContactsUI

struct WriteView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var detectedTagStore: DetectedTagStore
    
    @ObservedObject var contactsStore = ContactsStore()
    
    @State private var url = ""
    @State private var showSheet = false
    
    @State private var inputContact: CNContact?
    
    var body: some View {
        GeometryReader { geometry in
            Form {
                Section(header: Text("Möchten Sie eine Kontakt-URL hinterlegen?")) {
                    TextField("URL", text: self.$url)
                        .keyboardType(.URL)
                }
                
                Section(header: Text("Vistenkarten")) {
                    ForEach(self.contactsStore.contactItems) { contactItem in
                        VStack(alignment: .leading) {
                            Text("\(contactItem.contact.familyName), \(contactItem.contact.givenName)")
                                .font(.headline)
                            Text("Größe: \(contactItem.length) Bytes")
                                .font(.caption)
                        }
                    }
                    .onDelete { indexSet in
                        self.contactsStore.contactItems.remove(at: indexSet.first!)
                    }
                    
                    NavigationLink(destination: ContactPicker(contactsStore: self.contactsStore), isActive: self.$showSheet) {
                        Button(action: {
                            self.showSheet.toggle()
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("VCard Datensatz")
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle(Text("Datensätze erstellen"))
        .navigationBarItems(trailing:
            Button(action: {
                self.detectedTagStore.startSessionWith(appState: .ndefWrite, url: self.url, contactsStore: self.contactsStore)
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "square.and.arrow.down")
            }
        )
    }
}

struct WriteView_Previews: PreviewProvider {
    static var previews: some View {
        WriteView()
    }
}
