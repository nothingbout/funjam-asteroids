import Foundation
import JavaScriptKit

public class WebSoundPlayer {
    public var volume: Double = 1.0

    public init() {
    }

    public func playSound(_ name: String) {
        let filePath = "./resources/\(name).wav"
        let Audio = JSObject.global.Audio.object!
        let audio = Audio.new(filePath).jsValue
        audio.volume = volume.jsValue
        _ = audio.play()
    }
}
