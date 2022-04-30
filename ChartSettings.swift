import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var Image: UIImage?
    let configuration: PHPickerConfiguration
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Use a Coordinator to act as your PHPickerViewControllerDelegate
    class Coordinator: PHPickerViewControllerDelegate {
        private let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false // Set isPresented to false because picking has finished.
            let itemProviders = results.map(\.itemProvider)
            for item in itemProviders {
                if item.canLoadObject(ofClass: UIImage.self) {
                    item.loadObject(ofClass: UIImage.self) { image, _ in
                        DispatchQueue.main.async { [self] in
                            if let image = image as? UIImage {
                                self.parent.Image = image
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ChartSettings: View {
    @EnvironmentObject private var data: DataStructure

    let offsetRange = -10.0 ... 10.0 // acceptable offset range
    let chartLengthRange = 0 ... 600 // acceptable chartLength range
    @State private var newPreferTick = 3.0
    @State private var image: Image?
    @State private var showingImagePicker = false
    @State private var showingMusicPicker = false

    var body: some View {
        List {
            Section(header: Text("File Operation:")) {
                Button("Import Music...") {
                    showingMusicPicker = true
                }

                Button("Import Photo...") {
                    showingImagePicker = true
                }
                Button("Export '.pxf' file...") {
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                }
            }.textCase(nil)
            Section(header: Text("Information:")) {
                HStack {
                    Text("Music Name:")
                    TextField("Music", text: $data.musicName).foregroundColor(Color.blue)
                }
                HStack {
                    Text("Music Author:")
                    TextField("Author", text: $data.authorName).foregroundColor(Color.blue)
                }
                HStack {
                    Text("Chart Level:")
                    TextField("Level", text: $data.chartLevel).foregroundColor(Color.orange)
                }
                HStack {
                    Text("Chart Author:")
                    TextField("Chart Author", text: $data.chartAuthorName).foregroundColor(Color.orange)
                }
                Menu("Copyright Info") {
                    Button("[Full copyright]", action: {})
                    Button("[Limited copyright]", action: {})
                    Button("[No copyright]", action: {})
                }
            }.textCase(nil)
            Section(header: Text("Variables:")) {
                Stepper(value: $data.offset, in: offsetRange, step: 0.05) {
                    Text("Offset: \(NSString(format: "%.2f", data.offset))s")
                }

                Toggle(isOn: $data.changeBpm) {
                    Text("Allow BPM changes")
                }
                if !data.changeBpm {
                    Stepper(value: $data.bpm) {
                        Text("BPM: \(data.bpm)")
                    }
                } else {
                    // work to be done here. - give a editor on time-changing BPM
                    Button("Edit BPM Props") {}
                }
                Stepper(value: $data.chartLength, in: chartLengthRange) {
                    Text("Length: \(data.chartLength)s")
                }
            }.textCase(nil)

            Section(header: Text("Preferred Ticks")) {
                ForEach($data.preferTicks, id: \.value) { $tick in
                    ColorPicker("Tick: 1/" + String(tick.value), selection: $tick.color)

                }.onDelete(perform: { offset in
                    data.preferTicks.remove(atOffsets: offset)
                })

                VStack {
                    Stepper(value: $newPreferTick, in: 0 ... Double(data.tickPerSecond), step: 1) {
                        Text("NewTick: 1/\(Int(newPreferTick))")
                    }
                    Button("Add tick", action: {
                        if data.preferTicks.filter({ $0.value == Int(newPreferTick) }).count != 0 || data.tickPerSecond % Int(newPreferTick) != 0 {
                            return
                        } else {
                            data.preferTicks.append(ColoredInt(_value: Int(newPreferTick), _color: Color(red: .random(in: 0 ... 1), green: .random(in: 0 ... 1), blue: .random(in: 0 ... 1))))
                        }

                    })
                }
            }.onChange(of: data.preferTicks) { _ in
                dataK.preferTicks = data.preferTicks
            }.textCase(nil)

            Section(header: Text("Do not change these:")) {
                Stepper(value: $data.tickPerSecond,
                        onEditingChanged: { _ in
                            dataK.tickPerSecond = data.tickPerSecond
                        }) {
                    Text("Tick: \(data.tickPerSecond)")
                }
            }
        }.sheet(isPresented: $showingImagePicker) {
            let configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            ImagePicker(Image: $data.imageFile, configuration: configuration, isPresented: $showingImagePicker)
        }
        .fileImporter(
            isPresented: $showingMusicPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                if selectedFile.startAccessingSecurityScopedResource() {
                    data.audioFileURL = selectedFile
                } else {
                    // Handle denied access
                }
            } catch {
                // Handle failure.
            }
        }
    }
}

struct MyPreviewProvider_Previews: PreviewProvider {
    static var previews: some View {
        let tmpData = DataStructure(_id: 0)
        ChartSettings().environmentObject(tmpData)
    }
}
