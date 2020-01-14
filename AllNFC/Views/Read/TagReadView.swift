//
//  AllNFC
//  Copyright © 2019 Björn Lindner. All rights reserved.
//

import SwiftUI

struct TagReadView: View {
    
    @EnvironmentObject var detectedTagStore: DetectedTagStore
    
    var body: some View {
        GeometryReader { geometry in
            if self.detectedTagStore.tags.isEmpty {
                Text("keine Tags gefunden")
            }
            
            ForEach(self.detectedTagStore.tags) { tag in
                MyTagRowView(tag: tag)
            }
        }
        .navigationBarTitle(Text("Read NDEF Tag"))
    }
}

struct TagReadView_Previews: PreviewProvider {
    static var previews: some View {
        TagReadView()
    }
}
