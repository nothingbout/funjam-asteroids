import Foundation

// Get the binary size of Web/wasm/App.wasm
// Write to const MODULE_FALLBACK_SIZE = {size}; in Web/index.html
let modulePath = "Web/wasm/App.wasm"
let indexHtmlPath = "Web/index.html"
guard let binaryContents = FileManager.default.contents(atPath: modulePath) else {
    print("Failed to get binary contents of \(modulePath)")
    exit(1)
}
let sizeString = "\(binaryContents.count)"
let indexHtml = try String(contentsOfFile: indexHtmlPath, encoding: .utf8)

let regex = try! NSRegularExpression(pattern: "const MODULE_FALLBACK_SIZE = .*;", options: [])
let range = NSRange(location: 0, length: indexHtml.count)
let matches = regex.matches(in: indexHtml, options: [], range: range)
guard let match = matches.first else {
    print("Failed to find match for const MODULE_FALLBACK_SIZE = .*; in index.html")
    exit(1)
}
let replacement = "const MODULE_FALLBACK_SIZE = \(sizeString);"
let newHtml = regex.stringByReplacingMatches(in: indexHtml, options: [], range: match.range, withTemplate: replacement)
try newHtml.write(toFile: indexHtmlPath, atomically: true, encoding: .utf8)

let humanReadableSize = String(format: "%.2f MB", Double(binaryContents.count) / 1024.0 / 1024.0)
print("Wrote binary size of \(sizeString) (\(humanReadableSize)) to \(indexHtmlPath)")
