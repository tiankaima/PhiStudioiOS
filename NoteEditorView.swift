import SpriteKit
import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject private var data: DataStructure
    
    var body: some View {
        SpriteKitContainer(scene: NoteEditScene())
    }
}

struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditorView()
    }
}
