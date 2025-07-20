# CsvParser Examples

This directory contains comprehensive examples demonstrating all features of the Swift CsvParser library. Each example file showcases different aspects of the library with working code that you can run and modify.

## 📁 Example Files Overview

### 1. `BasicUsage.swift`
**What it covers:**
- Simple CSV string parsing
- Custom configuration (separators, quotes)
- Quoted fields with embedded commas
- Error handling with Result types
- File parsing

### 2. `AsyncExample.swift`
**What it covers:**
- Async/await parsing with progress reporting
- AsyncSequence streaming
- Concurrent processing of multiple CSV sources
- Task-based parsing with cancellation

### 3. `SwiftUIExample.swift`
**What it covers:**
- SwiftUI integration with @Observable
- Real-time parsing progress in UI
- File picker integration
- CSV data table views
- Legacy SwiftUI support (iOS 13+)

### 4. `AdvancedUsage.swift`
**What it covers:**
- Functional programming patterns
- Data transformation and aggregation
- Memory-efficient large file processing
- Custom CSV formats (European semicolon-separated)
- Real-time log processing

## 🚀 How to Run the Examples

### Method 1: Swift Playground (Recommended for Learning)

1. **Create a new Swift Playground in Xcode:**
   ```
   File → New → Playground → macOS → Blank
   ```

2. **Add the CsvParser package:**
   - In the playground, go to File → Add Package Dependency
   - Enter the local path, for example: `~/Documents/OpenSourceProjects/KTCsvParser`
   - Or use the GitHub URL if published

3. **Copy example code:**
   ```swift
   import CsvParser
   
   // Copy any function from the example files
   // For example, from BasicUsage.swift:
   
   func basicParsingExample() {
       print("=== Basic Parsing Example ===")
       
       let csvString = "name,age,city\nJohn,25,NYC\nJane,30,LA"
       
       do {
           let rows = try CsvParser.parseCSV(csvString)
           print("Parsed \(rows.count) rows:")
           for (index, row) in rows.enumerated() {
               print("Row \(index): \(row)")
           }
       } catch {
           print("Error parsing CSV: \(error)")
       }
   }
   
   // Run the example
   basicParsingExample()
   ```

### Method 2: Command Line Swift Package

1. **Create a new executable Swift package:**
   ```bash
   mkdir CsvParserExamples
   cd CsvParserExamples
   swift package init --type executable
   ```

2. **Edit `Package.swift` to add CsvParser dependency:**
   ```swift
   // swift-tools-version: 5.9
   import PackageDescription
   
   let package = Package(
       name: "CsvParserExamples",
       platforms: [.macOS(.v14)],
       dependencies: [
           .package(path: "/Volumes/MyData/Source/OpenSourceProjects/KTCsvParser")
       ],
       targets: [
           .executableTarget(
               name: "CsvParserExamples",
               dependencies: ["CsvParser"]
           )
       ]
   )
   ```

3. **Replace `Sources/CsvParserExamples/main.swift` with example code:**
   ```swift
   import Foundation
   import CsvParser
   
   // Copy any example function here and call it
   basicParsingExample()
   ```

4. **Run the examples:**
   ```bash
   swift run
   ```

### Method 3: Xcode Project Integration

1. **Create new Xcode project:**
   ```
   File → New → Project → macOS → Command Line Tool
   ```

2. **Add CsvParser package:**
   ```
   File → Add Package Dependencies → Add Local → Browse to KTCsvParser folder
   ```

3. **Copy example code to `main.swift`:**
   ```swift
   import Foundation
   import CsvParser
   
   // Copy and paste example functions here
   runBasicExamples()
   ```

## 📖 Running Specific Examples

### Basic Usage Examples

```swift
import CsvParser

// Uncomment in BasicUsage.swift and run:
runBasicExamples()
```

**Expected Output:**
```
=== Basic Parsing Example ===
Parsed 2 rows:
Row 0: ["name", "age", "city"]
Row 1: ["John", "25", "NYC"]
Row 2: ["Jane", "30", "LA"]

=== Custom Configuration Example ===
Parsed TSV data:
["name", "age", "city"]
["John", "25", "NYC"]
["Jane", "30", "LA"]
...
```

### Async Examples

```swift
import CsvParser

// For async examples, use:
Task {
    await runAsyncExamples()
}
```

**Expected Output:**
```
=== Async Parsing with Progress Example ===
Async parsing completed: 1001 rows

=== Async File Parsing Example ===
Progress: 1000 lines processed
Progress: 2000 lines processed
...
Completed: 5001 total rows
```

### SwiftUI Examples

For SwiftUI examples, create a new SwiftUI app and use the provided views:

```swift
import SwiftUI
import CsvParser

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 14.0, *) {
                CsvViewerApp()
            } else {
                LegacyCsvViewer()
            }
        }
    }
}
```

### Advanced Usage Examples

```swift
import CsvParser

// Uncomment in AdvancedUsage.swift and run:
runAdvancedExamples()
```

**Expected Output:**
```
=== Functional Programming Example ===
Engineering Department (by salary):
  Charlie Wilson - Age: 38, Salary: $80000
  Jane Smith - Age: 32, Salary: $85000
  John Doe - Age: 28, Salary: $75000
Average Engineering Salary: $80000

=== Data Transformation Example ===
Product Sales Summary:
  Widget B: 20 units, $900.00 revenue
  Widget A: 24 units, $612.00 revenue
  Widget C: 12 units, $429.00 revenue
...
```

## 🔧 Modifying Examples

### Adding Your Own CSV Data

1. **Replace sample data:**
   ```swift
   // Instead of:
   let csvString = "name,age,city\nJohn,25,NYC"
   
   // Use your own:
   let csvString = "product,price,stock\niPhone,999,50\nMacBook,2499,25"
   ```

2. **Load from file:**
   ```swift
   let fileURL = URL(fileURLWithPath: "/path/to/your/data.csv")
   let parser = try CsvParser(url: fileURL)
   ```

### Customizing Configuration

```swift
// European CSV format
let config = CsvConfiguration(
    valueSeparator: ";",
    quoteCharacter: "\"",
    ignoreLeadingWhitespaces: true
)

// Tab-separated values
let tsvConfig = CsvConfiguration(
    valueSeparator: "\t",
    quoteCharacter: nil
)
```

### Adding Progress Tracking

```swift
let rows = try await CsvParser.parseFileAsync(path: "large_file.csv") { lineCount in
    print("Progress: \(lineCount) lines processed")
    
    // Update a progress bar
    DispatchQueue.main.async {
        progressBar.progress = Float(lineCount) / Float(estimatedTotal)
    }
}
```

## 📝 Creating Your Own Examples

### Template for New Examples

```swift
import Foundation
import CsvParser

func myCustomExample() {
    print("=== My Custom Example ===")
    
    // Your CSV data
    let csvData = "..."
    
    do {
        // Your parsing logic
        let parser = CsvParser(data: csvData.data(using: .utf8)!)
        
        // Process data
        for row in parser {
            // Your processing logic
            print("Processing: \(row)")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Run your example
myCustomExample()
```

### Common Patterns

1. **Processing large files efficiently:**
   ```swift
   let parser = try CsvParser(path: "huge_file.csv")
   
   for row in parser.lazy.enumerated() {
       if row.offset % 1000 == 0 {
           print("Processed \(row.offset) rows")
       }
       // Process row.element
   }
   ```

2. **Converting to custom types:**
   ```swift
   struct Person {
       let name: String
       let age: Int
       let city: String
   }
   
   let people = parser
       .dropFirst() // Skip header
       .compactMap { row -> Person? in
           guard row.count >= 3, let age = Int(row[1]) else { return nil }
           return Person(name: row[0], age: age, city: row[2])
       }
   ```

3. **Error handling patterns:**
   ```swift
   switch CsvParser.parseCSVSafely(csvString) {
   case .success(let rows):
       processRows(rows)
   case .failure(let error):
       handleError(error)
   }
   ```

## 🧪 Testing Your Examples

Add simple assertions to verify your examples work:

```swift
func testMyExample() {
    let result = try CsvParser.parseCSVLine("a,b,c")
    assert(result.count == 3, "Expected 3 fields")
    assert(result[0] == "a", "First field should be 'a'")
    print("✅ Test passed!")
}
```

## 🔍 Troubleshooting

### Common Issues

1. **"No such module 'CsvParser'"**
   - Ensure the package is properly added to your project
   - Check that the import statement is correct

2. **File not found errors**
   - Use absolute paths or bundle resources
   - Check file permissions

3. **Memory issues with large files**
   - Use streaming parsing (for-in loops)
   - Avoid calling `parseAll()` on very large files

4. **Encoding issues**
   - Ensure your CSV files are UTF-8 encoded
   - Check for BOM (Byte Order Mark) at file start

### Getting Help

- Check the main README.md for API documentation
- Review the test files for additional usage patterns
- Examine the CONVERSION_SUMMARY.md for implementation details

---

**Start with `BasicUsage.swift` examples and gradually move to more advanced patterns as you become familiar with the library!**