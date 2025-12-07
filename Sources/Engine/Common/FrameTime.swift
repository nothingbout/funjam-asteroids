import Foundation

public struct FrameTime: Equatable, Hashable, Sendable {
    public let frameNumber: Int64
    public let timeSinceStartup: Duration
    public let deltaTime: Duration

    public init(frameNumber: Int64, timeSinceStartup: Duration, deltaTime: Duration) {
        self.frameNumber = frameNumber
        self.timeSinceStartup = timeSinceStartup
        self.deltaTime = deltaTime
    }

    public var secondsSinceStart: Double {
        return timeSinceStartup / Duration.seconds(1)
    }

    public var deltaSeconds: Double {
        return deltaTime / Duration.seconds(1)
    }
}
