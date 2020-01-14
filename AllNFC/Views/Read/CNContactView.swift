//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import SwiftUI
import Contacts

struct CNContactView: View {
    let contact: CNContact
    
    var body: some View {
        VStack {
            Spacer()
            
            if contact.imageDataAvailable {
                Image(uiImage: UIImage(data: contact.imageData!)!)
                Spacer()
            }
            
            HStack {
                Text(contact.familyName)
                Text(contact.givenName)
            }
            
            Spacer()
            
            ForEach(contact.postalAddresses, id: \.self) { postalAddress in
                VStack {
                    Text("Strasse: \(postalAddress.value.street)")
                    Text("Ort: \(postalAddress.value.city)")
                    Text("Bundesland: \(postalAddress.value.state)")
                    Text("PLZ: \(postalAddress.value.postalCode)")
                    Text("Land: \(postalAddress.value.country)")
                }
            }
            
            Spacer()
            
            ForEach(contact.phoneNumbers, id: \.self) { phoneNumber in
                VStack {
                    Text("\(self.getLocalizedPhoneLabelFor(phoneNumber.label ?? "unbekanntes Label")): \(phoneNumber.value.stringValue)")
                }
            }
            
            Spacer()
            
            ForEach(contact.emailAddresses, id: \.self) { emailAddress in
                VStack {
                    Text("\(self.getLocalizedStringLabelFor(emailAddress.label ?? "unbekanntes Label")): \(emailAddress.value)")
                }
            }
            
            Spacer()
        }
    }
    
    func getLocalizedStringLabelFor(_ label: String) -> String {
        let localizedLabel = CNLabeledValue<NSString>.localizedString(forLabel: label)
        return localizedLabel
    }
    
    func getLocalizedPhoneLabelFor(_ label: String) -> String {
        let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
        return localizedLabel
    }
}

struct CNContactView_Previews: PreviewProvider {
    static let contact = createDummyContact()
    
    static var previews: some View {
        CNContactView(contact: contact)
    }
    
    static func createDummyContact() -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = "Max"
        contact.familyName = "Mustermann"
        contact.organizationName = "Musterfirma"
        contact.jobTitle = "Experte"
        
        let phone = CNLabeledValue(label: CNLabelWork, value:CNPhoneNumber(stringValue: "+491234567890"))
        contact.phoneNumbers = [phone]
        let email = CNLabeledValue(label: CNLabelWork, value: "info@musterdomain.de" as NSString)
        contact.emailAddresses = [email]

        let address = CNMutablePostalAddress()
        address.street = "Musterstrasse 1"
        address.city = "Musterstadt"
        address.state = "Muster-Bundesland"
        address.postalCode = "0815"
        address.country = "Musterland"

        let labeledAddress = CNLabeledValue<CNPostalAddress>(label: CNLabelHome, value: address)

        contact.postalAddresses = [labeledAddress]
        
        return contact
    }
}
