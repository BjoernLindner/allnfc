//
//  AllNFC
//  Copyright © 2020 Björn Lindner. All rights reserved.
//

import Foundation
import ContactsUI
import CoreNFC

struct ContactItem: Identifiable {
    var id = UUID()
    var contact: CNContact
}

extension ContactItem {
    var payload: NFCNDEFPayload {
        let type = "text/x-vCard".data(using: .utf8)!
        let identifier = "".data(using: .utf8)!
        guard let data = payloadString.data(using: .utf8) else {
            fatalError("Payload konnte nicht erstellt werden")
        }
        
        return NFCNDEFPayload(format: .media, type: type, identifier: identifier, payload: data)
    }
    
    var payloadString: String {
        do {
            let vcarddat = try CNContactVCardSerialization.data(with: [contact])
            if let vcardAsString = String(data: vcarddat, encoding: .utf8) {
                var stringWithoutProdID = ""
                // WICHTIG ! Dies ist nötig, da sonst automatisiert folgende Zeile in die VCard eingefügt wird:
                // PRODID:-//Apple Inc.//iPhone OS 13.1.3//EN
                // spart 84 Bytes Bytes
                vcardAsString.enumerateLines { (line, _) in
                    if !line.hasPrefix("PRODID") {
                        stringWithoutProdID.append(line)
                        stringWithoutProdID.append("\r\n")
                    }
                }
                return stringWithoutProdID
            }
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
    
    var length: Int {
        var records: [NFCNDEFPayload] = []
        records.append(payload)
        
        return NFCNDEFMessage(records: records).length
    }
}
