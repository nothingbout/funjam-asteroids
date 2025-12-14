import Foundation
import JavaScriptKit

public class WebStorage {
    public init() {
    }

    public func save(key: String, value: String) {
        let localStorage = JSObject.global.localStorage
        _ = localStorage.setItem(key.jsValue, value.jsValue)
    }

    public func load(key: String) -> String? {
        let localStorage = JSObject.global.localStorage
        return localStorage.getItem(key.jsValue).string
    }
}
