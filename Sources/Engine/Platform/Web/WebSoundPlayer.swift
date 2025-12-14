import Foundation
import JavaScriptKit

public class WebSoundPlayer {
    public var volume: Double = 1.0

    public init() {
    }

    public func playSound(_ name: String, volume: Double = 1.0, pitch: Double = 1.0, pitchVariance: Double = 0.1) {
        let filePath = "./resources/\(name).wav"
        let Audio = JSObject.global.Audio.object!
        let audio = Audio.new(filePath).jsValue
        audio.volume = (self.volume * volume).jsValue
        audio.playbackRate = (pitch * Double.random(in: 1.0 / (1.0 + pitchVariance)...(1.0 + pitchVariance))).jsValue
        audio.preservesPitch = false.jsValue
        _ = audio.play()
    }
}
