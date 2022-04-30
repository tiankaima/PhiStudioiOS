import AVFoundation
import SpriteKit
import SwiftUI

public enum NOTETYPE {
    case Tap
    case Hold
    case Flick
    case Drag
}

enum EASINGTYPE {
    case linear
    case easeInSine
    case easeOutSine
    case easeInOutSine
    case easeInQuad
    case easeOutQuad
    case easeInOutQuad
    case easeInCubic
    case easeOutCubic
    case easeInOutCubic
    case easeInQuart
    case easeOutQuart
    case easeInOutQuart
    case easeInQuint
    case easeOutQuint
    case easeInOutQuint
    case easeInExpo
    case easeOutExpo
    case easeInOutExpo
    case easeInCirc
    case easeOutCirc
    case easeInOutCirc
    case easeInBack
    case easeOutBack
    case easeInOutBack
    case easeInElastic
    case easeOutElastic
    case easeInOutElastic
    case easeInBounce
    case easeOutBounce
    case easeInOutBounce
}

enum WINDOWSTATUS {
    case pannelNote
    case pannelProp
    case note
    case prop
}

public class Note: Equatable {
    var id: Int? // identify usage
    var noteType: NOTETYPE

    var posX: Double
    var width: Double // relative size to default, keep 1 for most cases

    var isFake: Bool
    var fallSpeed: Double // HSL per tick, relative to default
    var fallSide: Bool

    var time: Int // measured in tick
    var holdTime: Int? // measured in tick, only used for Hold variable
    init(Type: NOTETYPE, Time: Int, PosX: Double) {
        noteType = Type

        posX = PosX
        width = 1.0

        isFake = false
        fallSpeed = 1
        fallSide = true

        time = Time
    }

    func defaultInit() {
        id = 1
        noteType = NOTETYPE.Tap

        posX = 0
        width = 1.0

        isFake = false
        fallSpeed = 1
        fallSide = true

        time = 1
    }

    public static func == (l: Note, r: Note) -> Bool {
        return l.id == r.id && l.fallSpeed == r.fallSpeed && l.noteType == r.noteType && l.time == r.time && l.holdTime == r.holdTime && l.posX == r.posX && l.width == r.width && l.fallSide == r.fallSide && l.isFake == r.isFake
    }
}

struct PropStatus {
    var time: Int? // in Tick
    var value: Int?
    var nextEasing: EASINGTYPE?
}

public class JudgeLine: Identifiable, Equatable {
    class JudgeLineProps {
        var controlX: [PropStatus]?
        var controlY: [PropStatus]?
        var angle: [PropStatus]?
        var speed: [PropStatus]?
        var noteAlpha: [PropStatus]?
        var lineAlpha: [PropStatus]?
        var displayRange: [PropStatus]?
        init() {
            controlX = []
            controlY = []
            angle = []
            speed = []
            noteAlpha = []
            lineAlpha = []
            displayRange = []
        }
    }

    public var id: Int
    var noteList: [Note]
    var props: JudgeLineProps?

    init(_id: Int) {
        id = _id
        noteList = []
    }

    public static func == (l: JudgeLine, r: JudgeLine) -> Bool {
        return l.id == r.id && r.noteList == r.noteList
    }
}

public class ColoredInt: Equatable {
    var value: Int
    var color: Color = .white
    init(_value: Int, _color: Color = Color.white) {
        value = _value
        color = _color
    }

    public static func == (l: ColoredInt, r: ColoredInt) -> Bool {
        return l.value == r.value && l.color == r.color
    }
}

public class DataStructure: ObservableObject {
    // global data structure.
    // @Published meaning the swiftUI should look out if the variable is changing
    // for performance issue, please double check the usage for that
    var id: Int
    var timer = Timer()
    let now = Date()
    var timeWhenStart: Double?
    var lastTime = 0.0
    let updateTime = 0.01
    @Published var offset: Double
    @Published var bpm: Int // beat per minute
    @Published var changeBpm: Bool // if bpm is changing according to time
    @Published var tickPerSecond: Int // 1 second = x ticks
    @Published var preferTicks: [ColoredInt]
    @Published var chartLength: Int { // in ticks
        didSet {
            if chartLength < 0 {
                chartLength = 0
            }
            if id == 0 {
                dataK.chartLength = chartLength
            }
        }
    }

    @Published var musicName: String
    @Published var authorName: String
    @Published var audioFileURL: URL? {
        didSet {
            if audioFileURL != nil {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL!)
                    print("L")
//                    audioPlayer?.prepareToPlay()
                } catch {}
            }
        }
    }

    @Published var audioPlayer: AVAudioPlayer?
    @Published var imageFile: UIImage? {
        didSet {
            if id == 0 {
                dataK.imageFile = imageFile
            }
        }
    }

    @Published var imgFile: URL?
    @Published var chartLevel: String
    @Published var chartAuthorName: String
    @Published var windowStatus: WINDOWSTATUS
    @Published var listOfJudgeLines: [JudgeLine]
    @Published var currentTime: Double { // in ticks
        didSet {
            if id == 0 {
                // sync with dataK.
                dataK.currentTime = currentTime
            }
        }
    }

    @Published var currentNoteType: NOTETYPE

    @Published var isRunning: Bool {
        didSet {
            if id == 0 {
                dataK.isRunning = isRunning
            }
            if isRunning {
                audioPlayer?.volume = 1.0
                audioPlayer?.currentTime = currentTime / Double(tickPerSecond)
                audioPlayer?.play()
                lastTime = currentTime
                timeWhenStart = Date().timeIntervalSince1970
                timer = Timer.scheduledTimer(timeInterval: updateTime, target: self, selector: #selector(updateCurrentTime), userInfo: nil, repeats: true)
            } else {
                audioPlayer?.stop()
                if let t = timeWhenStart {
                    currentTime = (Date().timeIntervalSince1970 - t) * Double(tickPerSecond) + lastTime
                    timeWhenStart = nil
                }
            }
        }
    }

    @objc func updateCurrentTime() {
        if isRunning {
            currentTime = (Date().timeIntervalSince1970 - timeWhenStart!) * Double(tickPerSecond) + lastTime
        }
    }

    @Published var currentLineId: Int?
    init(_id: Int) {
        id = _id
        offset = 0.0
        bpm = 96
        changeBpm = false
        tickPerSecond = 48
        preferTicks = [ColoredInt(_value: 2, _color: Color.blue), ColoredInt(_value: 4, _color: Color.red)]
        chartLength = 120
        musicName = ""
        authorName = ""
        chartLevel = ""
        chartAuthorName = ""
        windowStatus = WINDOWSTATUS.pannelNote
        listOfJudgeLines = [JudgeLine(_id: 0)]
        currentTime = 0.0
        currentNoteType = NOTETYPE.Tap
        isRunning = false
    }
}
