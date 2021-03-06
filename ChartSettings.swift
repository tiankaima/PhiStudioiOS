/**
 * Created on Fri Jun 03 2022
 *
 * Copyright (c) 2022 TianKaiMa
 */
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

let offsetRange = -10.0 ... 10.0 // acceptable offset range
let chartLengthRange = 0 ... 600 // acceptable chartLength range

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var Image: UIImage?
    @Binding var isPresented: Bool
    let configuration: PHPickerConfiguration
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

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

struct URLExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.zip]
    var data: DataStructure?
    init(data: DataStructure) {
        self.data = data
    }

    init(configuration _: ReadConfiguration) throws {}
    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: try data!.exportZip())
    }
}

struct ChartSettings: View {
    @EnvironmentObject private var data: DataStructure
    @State private var newPreferTick = 3.0
    @State private var image: Image?
    @State private var zipURL: URL?
    @State private var showAlert = false
    @State private var showAlertNext = false
    @State private var showingImagePicker = false
    @State private var showingFileExporter = false
    @State private var showingFileImporter = false
    @State private var numberFormatter: NumberFormatter = {
        var nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf
    }()

    var body: some View {
        List {
            Section(header: Text("File Operation:")) {
                Button("Import Music / '.zip' file") {
                    showingFileImporter = true
                }

                Button("Import Photo") {
                    showingImagePicker = true
                }
                Button("Export '.zip' file") {
                    if !showingFileExporter {
                        do {
                            try _ = data.saveCache()
                            try self.zipURL = data.exportZip()
                            showingFileExporter = true
                        } catch {
                            print(error)
                        }
                    }
                }
                Button("Save to local storage") {
                    do {
                        try _ = data.saveCache()
                    } catch {
                        print(error)
                    }
                }
                Button("Reload from local storage") {
                    showAlert = true
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Confirm reload?"), message: Text("This would override all current settings"), primaryButton: .default(Text("cancel")), secondaryButton: .destructive(Text("Reload"), action: {
                        do {
                            try _ = data.loadCache()
                        } catch {
                            print(error)
                        }
                    }))
                }
                .foregroundColor(Color.red)
                Button("Fuck it") {
                    showAlertNext = true
                }.alert(isPresented: $showAlertNext) {
                    Alert(title: Text("Remove everything?"), message: Text("This would remove everything and start over!"), primaryButton: .default(Text("cancel")), secondaryButton: .destructive(Text("Remove"), action: {
                        do {
                            try _ = data.fuckIt()
                        } catch {
                            print(error)
                        }
                    }))
                }
                .foregroundColor(Color.red)
            }.textCase(nil)
            Section(header: Text("Information:")) {
                HStack {
                    Text("Music Name:")
                        .foregroundColor(.cyan)
                    TextField("Music", text: $data.musicName).foregroundColor(Color.blue)
                }.onChange(of: data.musicName) { _ in
                    if data.windowStatus == .preview || data.windowStatus == .pannelPreview {
                        data.chartPreviewScene.createLintNodes()
                    }
                }
                HStack {
                    Text("Music Author:")
                        .foregroundColor(.cyan)
                    TextField("Author", text: $data.authorName).foregroundColor(Color.blue)
                }.onChange(of: data.authorName) { _ in
                    if data.windowStatus == .preview || data.windowStatus == .pannelPreview {
                        data.chartPreviewScene.createLintNodes()
                    }
                }
                HStack {
                    Text("Chart Level:")
                        .foregroundColor(.cyan)
                    TextField("Level", text: $data.chartLevel).foregroundColor(Color.orange)
                }.onChange(of: data.chartLevel) { _ in
                    if data.windowStatus == .preview || data.windowStatus == .pannelPreview {
                        data.chartPreviewScene.createLintNodes()
                    }
                }
                HStack {
                    Text("Chart Author:")
                        .foregroundColor(.cyan)
                    TextField("Chart Author", text: $data.chartAuthorName).foregroundColor(Color.orange)
                }.onChange(of: data.chartAuthorName) { _ in
                    if data.windowStatus == .preview || data.windowStatus == .pannelPreview {
                        data.chartPreviewScene.createLintNodes()
                    }
                }
                Menu("Copyright: \(String(describing: data.copyright).capitalizingFirstLetter())") {
                    Button("[Full copyright]", action: {
                        data.copyright = .full
                    })
                    Button("[Limited copyright]", action: {
                        data.copyright = .limited
                    })
                    Button("[No copyright]", action: {
                        data.copyright = .none
                        // WARNING: DEBUG ONLY
                        NotificationCenter.default.post(name: NSNotification.Name("com.app.close"), object: nil)
                    })
                }.onChange(of: data.copyright) { _ in
                    if data.windowStatus == .preview || data.windowStatus == .pannelPreview {
                        data.chartPreviewScene.createLintNodes()
                    }
                }
            }.textCase(nil)
            Section(header: Text("Settings:")) {
                Stepper(value: $data.offsetSecond, in: offsetRange, step: 0.005) {
                    HStack {
                        Text("Offset:")
                        TextField("[Double]/s", value: $data.offsetSecond, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                    }
                }
                .foregroundColor(.cyan)

                Toggle(isOn: $data.bpmChangeAccrodingToTime) {
                    Text("Allow BPM changes")
                        .foregroundColor(.red)
                }
                if !data.bpmChangeAccrodingToTime {
                    Stepper(value: $data.bpm) {
                        HStack {
                            Text("BPM:")
                            TextField("[Double]", value: $data.bpm, formatter: numberFormatter)
                                .keyboardType(.numberPad)
                                .submitLabel(.done)
                        }
                    }
                    .foregroundColor(.cyan)
                } else {
                    // TODO: Add support for changing BPM, gonna be a pain in the ass
                    Button("Edit BPM Props") {}
                }
                Stepper(value: $data.chartLengthSecond, in: chartLengthRange) {
                    HStack {
                        Text("Chart Length:")
                        TextField("[Int]/s", value: $data.chartLengthSecond, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                    }
                }
                .foregroundColor(.cyan)
            }.textCase(nil)

            Section(header: Text("HighLight Tick:")) {
                ForEach($data.highlightedTicks, id: \.value) { $tick in
                    ColorPicker("Beat: 1/" + String(tick.value), selection: $tick.color)

                }.onDelete(perform: { offset in
                    data.highlightedTicks.remove(atOffsets: offset)
                    data.rebuildScene()
                })

                VStack {
                    Stepper(value: $newPreferTick, in: 0 ... Double(data.tickPerBeat), step: 1) {
                        Text("New Beat: 1/\(Int(newPreferTick))")
                    }
                    Button("Add", action: {
                        if data.highlightedTicks.filter({ $0.value == Int(newPreferTick) }).count != 0 || data.tickPerBeat % Int(newPreferTick) != 0 {
                            return
                        } else {
                            // add a random color to the new preferTick
                            data.highlightedTicks.append(ColoredInt(value: Int(newPreferTick), color: Color(red: .random(in: 0 ... 1), green: .random(in: 0 ... 1), blue: .random(in: 0 ... 1))))
                            data.rebuildScene()
                        }

                    })
                }
            }.onChange(of: data.highlightedTicks) { _ in }
                .textCase(nil)

            Section(header: Text("Advanced Settings:")) {
                Stepper(value: $data.tickPerBeat, onEditingChanged: { _ in }) {
                    Text("Tick: \(data.tickPerBeat)")
                }.foregroundColor(.red)
                Toggle(isOn: $data.fastHold) {
                    Text("Fast Hold")
                        .foregroundColor(.red)
                }
                Stepper(value: $data.maxAcceptableNotes, onEditingChanged: { _ in }) {
                    HStack {
                        Text("Note Division:")
                        TextField("[Int]", value: $data.maxAcceptableNotes, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                    }
                }
                .foregroundColor(.cyan)
                Stepper(value: $data.defaultHoldTimeTick, onEditingChanged: { _ in }) {
                    HStack {
                        Text("Default Hold Time:")
                        TextField("[Int]/T", value: $data.defaultHoldTimeTick, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                    }
                }
                .foregroundColor(.cyan)
            }.textCase(nil)
        }.sheet(isPresented: $showingImagePicker) {
            let configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            ImagePicker(Image: $data.imageFile, isPresented: $showingImagePicker, configuration: configuration)
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.zip, .mp3], allowsMultipleSelection: false) { result in
            // Hint here: the file importer doesn't actually care which button user hit, whether it's importing a .zip file or a .mp3 file, they're all handled here.
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                if selectedFile.startAccessingSecurityScopedResource() {
                    let fm = FileManager.default
                    let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
                    if let url = urls.first {
                        // TODO: I would probably argue that this part of logic should move to definition.swift...
                        if selectedFile.pathExtension == "zip" {
                            let fileURL = url.appendingPathComponent("import.zip")
                            if fm.fileExists(atPath: fileURL.path) {
                                try fm.removeItem(at: fileURL)
                            }
                            try fm.copyItem(at: selectedFile, to: fileURL)
                            try _ = self.data.importZip()
                        } else {
                            let dirPath = url.appendingPathComponent("tmp")
                            if !fm.fileExists(atPath: dirPath.path) {
                                try fm.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
                            }
                            let fileURL = dirPath.appendingPathComponent("tmp.mp3")
                            if fm.fileExists(atPath: fileURL.path) {
                                try fm.removeItem(at: fileURL)
                            }
                            try fm.copyItem(at: selectedFile, to: fileURL)
                            data.audioFileURL = fileURL
                        }
                    } else {
                        print("[Err]: Failed to access document url at ChartSettings.swift")
                    }
                } else {
                    print("[Err]: Denied access to user-seleted file at ChartSettings.swift")
                }
            } catch {
                print(error)
            }
        }
        .fileExporter(isPresented: $showingFileExporter, document: URLExportDocument(data: data), contentType: .zip, onCompletion: { _ in })
    }
}
