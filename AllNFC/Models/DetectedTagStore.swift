//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import CoreNFC
import os

class DetectedTagStore: NSObject, ObservableObject {
    
    @Published var tags: [MyTag] = []
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private var appState = AppState.undefined
    private var readerSession: NFCTagReaderSession?
    private var ndefMessage: NFCNDEFMessage?
    
    func startSessionWith(appState: AppState, url: String?, contactsStore: ContactsStore?) {
        
        var records: [NFCNDEFPayload] = []
        
        if let url = url, url != "" {
            if let urlPayload = self.createURLPayloadWith(url: url) {
                records.append(urlPayload)
            }
        }
        
        if let store = contactsStore {
            for contactItem in store.contactItems {
                records.append(contactItem.payload)
            }
        }
        
        guard !records.isEmpty else {
            fatalError("da kamen keine Payloads")
        }
        
        ndefMessage = NFCNDEFMessage(records: records)
        self.startSessionWith(appState: appState)
    }
    
    func startSessionWith(appState: AppState) {
        self.appState = appState
        
        // 1
        // prüft ob das Gerät in der Lage ist NFC Tags zu lesen
        // da nur iPhone 7 und neuer in Frage kommt, und alles Ältere und alle iPads aussen vor sind, ist die Menge der nicht NFC fähigen geräte nicht zu unterschätzen
        guard NFCNDEFReaderSession.readingAvailable else {
            OperationQueue.main.addOperation {
                self.alertMessage = "Dieses Gerät kann keine NFC Tags lesen"
                self.showAlert.toggle()
            }
            return
        }
        
        switch self.appState {
        case .ndefRead, .ndefWrite:
            // 2
            // Initialisierung der Session mit pollingOptions
            // wird die pollingOption 18092 (FeliCa) gesetzt, muss in der info.plist der Eintrag
            // com.apple.developer.nfc.readersession.felica.systemcodes = 12FC gesetzt werden, sonst wird die Session nicht gestartet
            readerSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self, queue: nil)
            readerSession?.alertMessage = "Halte Dein iPhone nahe an einen NFC Tag."
            readerSession?.begin()
        case .undefined:
            OperationQueue.main.addOperation {
                self.alertMessage = "Ich bin in einem undefinierten Zustand. Dies sollte eigentlich nicht passieren, aber Glückwunsch, Du hast es geschafft!"
                self.showAlert.toggle()
            }
        }
    }
}

extension DetectedTagStore: NFCTagReaderSessionDelegate {
    // MARK: - NFCTagReaderSessionDelegate
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // wenn irgendetwas ausgeführt werden soll, direkt beim Start der Session
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                OperationQueue.main.addOperation {
                    self.alertMessage = error.localizedDescription
                    self.showAlert.toggle()
                }
            }
        }
        readerSession = nil
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        // beim Schreiben ist es von Vorteil zu Prüfen ob nur ein Tag in der Nähe ist
        // will man mehrere Tags gleichzeitig beschreiben, ist dieser Bereich überflüssig, allerdings, muss dann eine Queue aufgebaut werden
        if appState == .ndefWrite {
            if tags.count > 1 {
                session.alertMessage = "Es wurden mehr als 1 Tag gefunden. Bitte halte nur 1 Tag in die Nähe."
                self.tagRemovalDetect(tags.first!)
                return
            }
        }
        
        for nfcTag in tags {
            
            var myTag: MyTag
            
            // initialisiere einen NFCNDEFTag mit dem jeweiligen Tag-Typen (z.B. NFCISO7816Tag)
            let ndefTag: NFCNDEFTag
            
            switch nfcTag {
            case let .iso7816(tag):
                myTag = MyTag(tagType: "iso7816", tagTypeFamily: "")
                ndefTag = tag
                
                session.connect(to: nfcTag) { (error: Error?) in
                    
                    let apdu = NFCISO7816APDU(instructionClass: 0, instructionCode: 0xB2, p1Parameter: 0, p2Parameter: 0, data: Data(), expectedResponseLength: 16)
                    tag.sendCommand(apdu: apdu) { (response, sw1, sw2, error) in
                        if let readerError = error as? NFCReaderError {
                            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                                print(error!.localizedDescription)
                            }
                        }

                        guard error == nil else {
                            print("error beim apdu zugriff: \(error?.localizedDescription)")
                            return
                        }

                        if sw1 == 144 && sw2 == 0 {
                            // 90 & 00
                            os_log("Befehl erfolgreich abgeschlossen")
                        } else if sw1 == 105 && sw2 == 130 {
                            // 69 & 82
                            os_log("Sicherheitsstatus nicht erfüllt")
                        } else if sw1 == 109 && sw2 == 0 {
                            // 6D & 00
                            os_log("INS Feld nicht unterstützt")
                        }

                        let dataString = String(data: response, encoding: .utf8) ?? ""
                        print("Daten: \(dataString)")
                        print("sw1: \(sw1)")
                        print("sw2: \(sw2)")
                    }
                }
                
            case let .feliCa(tag):
                myTag = MyTag(tagType: "FeliCa", tagTypeFamily: "")
                ndefTag = tag
            case let .iso15693(tag):
                myTag = MyTag(tagType: "iso15693", tagTypeFamily: "")
                ndefTag = tag
            case let .miFare(tag):
                ndefTag = tag
                switch tag.mifareFamily {
                case .desfire:
                    myTag = MyTag(tagType: "MiFare", tagTypeFamily: "DESFire")
                    
                    let data = "test".data(using: .utf8)!
                    
                    session.connect(to: nfcTag) { (error: Error?) in
                        self.write(data, to: tag)
                    }
                case .unknown:
                    myTag = MyTag(tagType: "MiFare", tagTypeFamily: "Unbekannt")
                case .ultralight:
                    myTag = MyTag(tagType: "MiFare", tagTypeFamily: "Ultralight")
                    
                    let data = "test".data(using: .utf8)!
                            let tagUIDData = tag.identifier
                            var byteData: [UInt8] = []
                            tagUIDData.withUnsafeBytes { byteData.append(contentsOf: $0) }
                            var uidString = ""
                            for byte in byteData {
                                let decimalNumber = String(byte, radix: 16)
                                if (Int(decimalNumber) ?? 0) < 10 { // add leading zero
                                    uidString.append("0\(decimalNumber)")
                                } else {
                                    uidString.append(decimalNumber)
                                }
                            }
                            debugPrint("\(byteData) converted to Tag UID: \(uidString)")
                    session.connect(to: nfcTag) { (error: Error?) in
                        self.write(data, to: tag)
                    }
                case .plus:
                    myTag = MyTag(tagType: "MiFare", tagTypeFamily: "Plus")
                @unknown default:
                    myTag = MyTag(tagType: "MiFare", tagTypeFamily: "Unspezifiziert")
                }
            @unknown default:
                session.invalidate(errorMessage: "Tag nicht valide.")
                return
            }
            
            // baue eine Verbindung von der Session zu dem Tag auf
            // wichtig ist hier, das die Verbindung zu dem NFCTag und nicht zu dem NFCNDEFTag aufgeaubt wird
            session.connect(to: nfcTag) { (error) in
                guard error == nil else {
                    session.invalidate(errorMessage: "Verbindungsfehler. Bitte versuche es erneut")
                    return
                }
                
                // der NDEF Status gibt Informationen darüber, ob der Tag überhaupt NDEF unterstützt zum aktuellen Zeitpunkt
                // und den verfügbaren Speicherplatz auf dem Tag
                ndefTag.queryNDEFStatus { (status, capacity, error) in
                    guard error == nil else {
                        OperationQueue.main.addOperation {
                            self.tags.append(myTag)
                        }
                        session.invalidate(errorMessage: "Konnte Status nicht ermitteln. Bitte versuche es erneut")
                        return
                    }
                    
                    myTag.capacity = capacity
                    
                    if status == .notSupported {
                        OperationQueue.main.addOperation {
                            self.tags.append(myTag)
                        }
                        session.invalidate(errorMessage: "Tag nicht valide.")
                        return
                    } else if status == .readOnly {
                        myTag.readOnly = true
                    }
                    if self.appState == .ndefRead {
                        // ab hier wird die Nachricht vom Tag im NDEF Format ausgelesen
                        ndefTag.readNDEF { (ndefMessage, error) in
                            guard error == nil else {
                                OperationQueue.main.addOperation {
                                    self.tags.append(myTag)
                                }
                                session.invalidate(errorMessage: "Konnte Tag nicht lesen. Bitte versuche es erneut")
                                return
                            }
                            
                            guard let message = ndefMessage else {
                                OperationQueue.main.addOperation {
                                    self.tags.append(myTag)
                                }
                                session.alertMessage = "Der Tag enthält keine Daten."
                                session.invalidate()
                                return
                            }
                            
                            let myTagRecords = message.records.map { self.readRecord($0) }
                            myTag.records = myTagRecords
                            
                            OperationQueue.main.addOperation {
                                self.tags.append(myTag)
                            }
                            
                            session.alertMessage = "Tag erfolgreich gelesen."
                            session.invalidate()
                        }
                    } else if self.appState == .ndefWrite && status == .readWrite {
                        // verfügbare Kapazität des tags mit der zu schreibenden Payload vergleichen
                        if self.ndefMessage!.length > capacity {
                            session.invalidate(errorMessage: "Tag Kapazität reicht nicht aus. Es werden mindestens \(self.ndefMessage!.length) bytes benötigt.")
                            return
                        }
                        
                        // ab hier wird die Nachricht auf den Tag im NDEF Format geschrieben
                        ndefTag.writeNDEF(self.ndefMessage!) { (error: Error?) in
                            if error != nil {
                                session.invalidate(errorMessage: "Schreiben fehlgeschlagen. Bitte erneut versuchen.")
                            } else {
                                session.alertMessage = "Schreiben erfolgreich!"
                                session.invalidate()
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension DetectedTagStore {
    // MARK: - Private helper functions
    func tagRemovalDetect(_ tag: NFCTag) {
        self.readerSession?.connect(to: tag) { (error: Error?) in
            if error != nil || !tag.isAvailable {
                os_log("Restart polling.")
                self.readerSession?.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
                self.tagRemovalDetect(tag)
            })
        }
    }
    
    func readRecord(_ record: NFCNDEFPayload) -> MyTagRecord {
        var typeNameFormat = ""
        var type: String? = nil
        var content: String? = nil
        var locale: Locale? = nil
        
        switch record.typeNameFormat {
        case .absoluteURI:
            typeNameFormat = "absoluteURI"
            if let url = record.wellKnownTypeURIPayload() {
                content = url.absoluteString
            } else {
                content = "Die URL ist leider nicht lesbar"
            }
        case .empty:
            typeNameFormat = "empty"
            type = ""
            content = "leerer Datensatz"
        case .nfcWellKnown:
            typeNameFormat = "nfcWellKnown"
            
            let status = record.payload[0]
            let encodingBit = Int(status & 0x80)
            
            var encoding: String.Encoding
            if encodingBit == 0 {
                encoding = .utf8
            } else {
                encoding = .utf16
            }
            type = String(data: record.type, encoding: encoding)
            
            (content, locale) = record.wellKnownTypeTextPayload()
            
            // manchmal werden URL's nicht als absoluteURI gespeichert, sondern als nfcWellKnown
            // wellKnownTypeTextPayload() erkennt diesen Inhalt dann nicht
            // deshalb empfiehlt es sich noch mit wellKnownTypeURIPayload() zu prüfen ob eine URL da ist
            if content == nil {
                content = record.wellKnownTypeURIPayload()?.absoluteString
            }
            
            if content == nil {
                content = "keine Daten vorhanden"
            }
        case .media:
            typeNameFormat = "media"
            
            let status = record.payload[0]
            let encodingBit = Int(status & 0x80)
            
            var encoding: String.Encoding
            if encodingBit == 0 {
                encoding = .utf8
            } else {
                encoding = .utf16
            }
            type = String(data: record.type, encoding: encoding)
            
            if type == "text/x-vCard" {
                content = String(data: record.payload, encoding: encoding)
            }
        case .nfcExternal:
            typeNameFormat = "nfcExternal"
            type = ""
            content = "muss noch implementiert werden"
        case .unknown:
            typeNameFormat = "unknown"
            type = ""
            content = "muss noch implementiert werden"
        case .unchanged:
            typeNameFormat = "unchanged"
            type = ""
            content = "muss noch implementiert werden"
        @unknown default:
            typeNameFormat = "unknown default"
            type = ""
            content = "Absolut unbekannter Zustand, sollte eigentlich nicht passieren."
        }
        
        return MyTagRecord(typeNameFormat: typeNameFormat, type: type ?? "", content: content ?? "")
    }
    
    func createURLPayloadWith(url: String) -> NFCNDEFPayload? {
        guard let urlComponent = URLComponents(string: url) else { return nil }
        return NFCNDEFPayload.wellKnownTypeURIPayload(url: (urlComponent.url)!)
    }
    
    func write(_ data: Data, to tag: NFCMiFareTag) {
        
        // verschiedene Kommandos nachschlagen
        // https://www.st.com/resource/en/datasheet/st25ta64k.pdf
        
        // Prüft die Zugriffsrechte des NDEF-Files oder schickt ein Passwort
        let apdu = NFCISO7816APDU(instructionClass: 0x00, instructionCode: 0x20, p1Parameter: 0, p2Parameter: 0, data: Data(), expectedResponseLength: 16)
        
        tag.sendMiFareISO7816Command(apdu) { (data, sw1, sw2, error) in
            if let readerError = error as? NFCReaderError {
                if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                    && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                    print(error!.localizedDescription)
                }
            }
            
            guard error == nil else {
                print("error beim apdu zugriff: \(error?.localizedDescription)")
                return
            }
            
            if sw1 == 144 && sw2 == 0 {
                // 90 & 00
                os_log("Befehl erfolgreich abgeschlossen")
            } else if sw1 == 105 && sw2 == 130 {
                // 69 & 82
                os_log("Sicherheitsstatus nicht erfüllt")
            } else if sw1 == 109 && sw2 == 0 {
                // 6D & 00
                os_log("INS Feld nicht unterstützt")
            } else if sw1 == 106 && sw2 == 134 {
                // 6A & 86
                os_log("falsche p1 und/oder p2 Parameter")
            }
            
            let dataString = String(data: data, encoding: .utf8) ?? ""
            print("Daten: \(dataString)")
            print("sw1: \(sw1)")
            print("sw2: \(sw2)")
        }
    }
}
