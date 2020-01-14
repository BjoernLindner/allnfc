//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var detectedTagStore: DetectedTagStore
    
    @State private var showTagReadView = false
    @State private var showTagWriteView = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    NavigationLink(destination: TagReadView(), isActive: self.$showTagReadView) {
                        Button(action: {
                            self.detectedTagStore.startSessionWith(appState: .ndefRead)
                            self.showTagReadView.toggle()
                        }) {
                            HStack {
                                Text("Lese NDEF")
                            }
                            .frame(width: geometry.size.width - 10, height: geometry.size.height / 3 - 10)
                            .background(Color.red)
                            .font(.title)
                        }
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: WriteView(), isActive: self.$showTagWriteView) {
                        Button(action: {
                            self.showTagWriteView.toggle()
                        }) {
                            HStack {
                                Text("Schreibe NDEF")
                            }
                            .frame(width: geometry.size.width - 10, height: geometry.size.height / 3 - 10)
                            .background(Color.yellow)
                            .font(.title)
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("Viel Spaß")
                    }
                    .frame(width: geometry.size.width - 10, height: geometry.size.height / 3 - 10)
                    .background(Color.green)
                    .font(.title)
                    
                    Spacer()
                    
                }
                .alert(isPresented: self.$detectedTagStore.showAlert) {
                    Alert(title: Text("Warnhinweis"), message: Text(self.detectedTagStore.alertMessage), dismissButton: .default(Text("OK :(")) {
                        return
                        }
                    )
                }
            }
            .navigationBarTitle(Text("All NFC"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
