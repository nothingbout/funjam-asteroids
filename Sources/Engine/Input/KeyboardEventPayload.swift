import Foundation

public struct KeyboardEventPayload: Sendable {
    public let eventType: EventType
    public let modifiers: ModifierKeys
    public let key: PhysicalKey?
    public let text: String?

    public enum EventType: Hashable, Sendable {
        case keyDown
        case keyRepeat
        case keyUp
    }

    public struct ModifierKeys: OptionSet, CustomStringConvertible, Equatable, Hashable, Sendable {
        public static let shift = Self(rawValue: 1 << 0)
        public static let control = Self(rawValue: 1 << 1)
        public static let alt = Self(rawValue: 1 << 2)

        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue }

        public var description: String {
            var str = ""
            if contains(.shift) { str += (str.isEmpty ? "" : "+") + "shift" }
            if contains(.control) { str += (str.isEmpty ? "" : "+") + "control" }
            if contains(.alt) { str += (str.isEmpty ? "" : "+") + "alt" }
            if str.isEmpty { str = "none" }
            return str
        }
    }

    /// The PhysicalKey enum represent the physical position of the key according to a typical US QWERTY keyboard layout, 
    /// and remains unchanged even if the keyboard layout or locale is changed.
    ///
    /// The text that is produced by pressing the key may not correspond with the PhysicalKey value, as the produced text depends
    /// on the current locale, keyboard layout, and held modifier keys, while none of these affect the PhysicalKey value.
    /// 
    /// Below is the typical layout for letters and special character keys that the PhysicalKey enum is based on.
    /// NOTE: On some systems the locations of the `backquote` and `intlBackslash` keys are swapped.
    /// ```
    ///          <backquote> 1 2 3 4 5 6 7 8 9 0 <minus> <equal> <backspace>
    ///                 <tab> Q W E R T Y U I O P <leftBracket> <rightBracket> <enter>
    ///                 <caps> A S D F G H J K L <semicolon> <quote> <backslash> <enter>
    /// <shift> <intlBackslash> Z X C V B N M <comma> <period> <slash> <shift>
    /// 
    /// For reference: https://www.w3.org/TR/uievents-code/
    /// ```
    public enum PhysicalKey: Hashable, Sendable {
        public enum Location: Hashable, Sendable {
            case left
            case right
        }
        
        // Modifier keys
        case alt(Location)
        case control(Location)
        case shift(Location)
        
        // Special keys
        case escape
        case function(Int) // F1, F2, ..., F12, ...
        case tab; case space
        case backspace; case delete
        case enter
        case arrowLeft; case arrowRight; case arrowUp; case arrowDown
        case pageUp; case pageDown
        case home; case end
        
        // Special characters with a physical key code
        case backquote                              // left of '1'
        case intlBackslash                          // left of 'Z'
        case minus; case equal                      // right of '0'
        case leftBracket; case rightBracket         // right of 'P'
        case semicolon; case quote; case backslash  // right of 'L'
        case comma; case period; case slash         // right of 'M'

        // Digits and letters
        case digit(Int)
        case a; case b; case c; case d; case e; case f; case g; case h; case i; case j
        case k; case l; case m; case n; case o; case p; case q; case r; case s; case t
        case u; case v; case w; case x; case y; case z;
    }
}
