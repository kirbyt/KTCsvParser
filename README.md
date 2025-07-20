# KTCsvParser

A modern Swift CSV parser converted from the original KTCsvParser Objective-C library. This parser provides efficient, streaming CSV parsing with full Swift language support including async/await, Sequence conformance, and SwiftUI integration.

## Features

- 🚀 **Modern Swift**: Built with Swift 5.9+ features
- ⚡ **Streaming Parser**: Memory-efficient parsing of large files
- 🔄 **Async/Await**: Full async support for non-blocking operations
- 📱 **SwiftUI Ready**: Observable framework integration for reactive UIs
- 🧪 **Swift Testing**: Comprehensive test suite using Swift Testing framework
- 🔗 **Sequence Conformance**: Use with for-in loops and functional operations
- 🌍 **Unicode Support**: Proper UTF-8 handling for international content
- ⚠️ **Error Handling**: Swift-native error handling with Result types

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/CsvParser", from: "1.0.0")
]
```

Or add via Xcode: File → Add Package Dependencies

## Quick Start

### Basic Usage

```swift
import CsvParser

// Parse a CSV string
let csvString = "name,age,city\nJohn,25,NYC\nJane,30,LA"
let rows = try CsvParser.parseCSV(csvString)
print(rows) // [["name", "age", "city"], ["John", "25", "NYC"], ["Jane", "30", "LA"]]

// Parse a single line
let values = try CsvParser.parseCSVLine("a,b,c")
print(values) // ["a", "b", "c"]
```

### Streaming Large Files

```swift
// Stream parsing for memory efficiency
let parser = try CsvParser(path: "large_file.csv")

for row in parser {
    print("Processing row: \(row)")
    // Process each row without loading entire file into memory
}
```

### Async/Await Support

```swift
// Parse asynchronously
let rows = try await CsvParser.parseFileAsync(path: "data.csv") { lineNumber in
    print("Processed \(lineNumber) lines")
}

// Stream with async sequence
let parser = try CsvParser(path: "data.csv")
for try await row in parser.asyncSequence {
    await processRow(row)
}
```

### Configuration

```swift
let config = CsvConfiguration(
    valueSeparator: "|",           // Use pipe instead of comma
    quoteCharacter: "'",           // Use single quotes
    ignoreLeadingWhitespaces: true // Skip leading spaces
)

let values = try CsvParser.parseCSVLine("a | b | c", configuration: config)
```

### SwiftUI Integration

```swift
import SwiftUI
import CsvParser

struct ContentView: View {
    @State private var parser = CsvParser(data: csvData)
    
    var body: some View {
        VStack {
            Text("Lines processed: \(parser.linesProcessed)")
            Text("Current row: \(parser.currentRow.joined(separator: ", "))")
            
            Button("Start Parsing") {
                Task {
                    await parser.startParsingAsync()
                }
            }
        }
    }
}
```

### Functional Programming

```swift
let parser = try CsvParser(path: "employees.csv")

// Chain operations with lazy evaluation
let adultNames = parser
    .dropFirst()                    // Skip header
    .filter { row in                // Filter adults
        guard let age = Int(row[1]) else { return false }
        return age >= 18
    }
    .map { $0[0] }                  // Extract names
    .prefix(10)                     // Take first 10

let names = Array(adultNames)
```

### Error Handling

```swift
// Using Result types
let result = CsvParser.parseCSVSafely(csvString)

switch result {
case .success(let rows):
    print("Parsed \(rows.count) rows")
case .failure(let error):
    print("Parsing failed: \(error.localizedDescription)")
}

// Traditional try-catch
do {
    let rows = try CsvParser.parseCSV(csvString)
    processRows(rows)
} catch {
    handleError(error)
}
```

### Dictionary Support

```swift
// Parse with headers as dictionary keys
let parser = try CsvParser(path: "users.csv")
let dictionaries = try parser.parseAsDictionaries()

for user in dictionaries {
    print("Name: \(user["name"] ?? ""), Age: \(user["age"] ?? "")")
}
```

## Advanced Usage

### Custom Separators

```swift
// Tab-separated values
let tsvConfig = CsvConfiguration(valueSeparator: "\t")
let parser = CsvParser(data: tsvData, configuration: tsvConfig)

// Semicolon-separated (European format)
let csvConfig = CsvConfiguration(valueSeparator: ";")
```

### Memory-Efficient Processing

```swift
// Process large files without loading everything into memory
let parser = try CsvParser(path: "huge_file.csv")

var sum = 0
for row in parser.lazy.compactMap({ Int($0.first ?? "") }) {
    sum += row
    // Only keeps current row in memory
}
```

### Progress Monitoring

```swift
let parser = try CsvParser(path: "data.csv")

let rows = try await parser.parseAllAsync { linesProcessed in
    print("Progress: \(linesProcessed) lines")
    // Update UI progress indicator
}
```

## Error Types

The parser defines specific error types for better error handling:

```swift
public enum CsvParserError: Error {
    case streamError(String)           // File/stream reading errors
    case encodingError                 // UTF-8 encoding issues
    case bufferOverflow               // Data too large for buffer
    case invalidConfiguration(String)  // Invalid parser settings
}
```

## Performance

- **Streaming**: Processes files line-by-line for constant memory usage
- **Lazy Evaluation**: Sequence operations are computed on-demand
- **Buffered Reading**: Efficient UTF-8 character boundary handling
- **Async Support**: Non-blocking operations for UI responsiveness

## Migration from Objective-C Version

The Swift version maintains API compatibility while adding modern Swift features:

```swift
// Old Objective-C style
let values = KTCsvParser.values(fromCsvLine: csvString, withValueSeparator: ",")

// New Swift style
let values = try CsvParser.parseCSVLine(csvString)

// With configuration
let config = CsvConfiguration(valueSeparator: ",")
let values = try CsvParser.parseCSVLine(csvString, configuration: config)
```

## Requirements

- iOS 17.0+ / macOS 14.0+ / watchOS 10.0+ / tvOS 17.0+ (for Observation framework)
- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+ (for basic functionality)
- Swift 5.9+
- Xcode 15.0+

## Testing

The library includes comprehensive tests using Swift Testing framework:

```bash
swift test
```

Test categories:
- Basic parsing functionality
- Error handling and edge cases
- Performance tests
- Async/await operations
- Sequence conformance
- Unicode support

# Support, Bugs and Feature requests

There's absolutely **no support** offered for this project. You're on your own. If you're using this code, then you're a developer — so you should be able to submit code changes for features requests and bug fixes yourself without expecting me to make the code changes for you.

To contribute to the project:

1. Fork the repository.
2. Create a feature branch.
3. Add tests for your changes.
4. Ensure all tests pass.
5. Submit a pull request.


# License

The MIT License

Copyright (c) 2025 Kirby Turner
Copyright (c) 2010-2014 White Peak Software Inc

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.