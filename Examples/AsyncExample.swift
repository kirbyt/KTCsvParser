import Foundation
import CsvParser

// MARK: - Async/Await Examples

/// Async parsing with progress reporting
func asyncParsingWithProgressExample() async {
    print("=== Async Parsing with Progress Example ===")
    
    // Generate large CSV content
    var csvContent = "id,name,score\n"
    for i in 1...1000 {
        csvContent += "\(i),User\(i),\(Float.random(in: 0...100))\n"
    }
    
    do {
        let rows = try await CsvParser.parseCSVAsync(csvContent)
        print("Async parsing completed: \(rows.count) rows")
    } catch {
        print("Async parsing failed: \(error)")
    }
}

/// Async file parsing with progress monitoring
func asyncFileParsingExample() async {
    print("\n=== Async File Parsing Example ===")
    
    // Create a larger temporary file
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("large_sample.csv")
    
    var csvContent = "timestamp,user_id,action,value\n"
    for i in 1...5000 {
        csvContent += "\(Date().timeIntervalSince1970),\(i % 100),action_\(i % 10),\(Int.random(in: 1...1000))\n"
    }
    
    do {
        // Write sample data to file
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Parse with progress reporting
        let rows = try await CsvParser.parseFileAsync(path: fileURL.path) { linesProcessed in
            if linesProcessed % 1000 == 0 {
                print("Progress: \(linesProcessed) lines processed")
            }
        }
        
        print("Completed: \(rows.count) total rows")
        
        // Clean up
        try FileManager.default.removeItem(at: fileURL)
        
    } catch {
        print("Error with async file parsing: \(error)")
    }
}

/// AsyncSequence streaming example
func asyncSequenceExample() async {
    print("\n=== AsyncSequence Streaming Example ===")
    
    let csvContent = """
    product,category,price,stock
    iPhone,Electronics,999.99,50
    MacBook,Electronics,2499.00,25
    AirPods,Electronics,249.99,100
    iPad,Electronics,799.99,75
    """
    
    do {
        let parser = CsvParser(data: csvContent.data(using: .utf8)!)
        
        print("Streaming with AsyncSequence:")
        var rowIndex = 0
        
        for try await row in parser.asyncSequence {
            print("Row \(rowIndex): \(row)")
            rowIndex += 1
            
            // Simulate some async processing
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
    } catch {
        print("AsyncSequence error: \(error)")
    }
}

/// Concurrent processing example
func concurrentProcessingExample() async {
    print("\n=== Concurrent Processing Example ===")
    
    let csvData1 = "a,b,c\n1,2,3\n4,5,6"
    let csvData2 = "x,y,z\n7,8,9\n10,11,12"
    let csvData3 = "p,q,r\n13,14,15\n16,17,18"
    
    // Process multiple CSV sources concurrently
    async let result1 = CsvParser.parseCSVAsync(csvData1)
    async let result2 = CsvParser.parseCSVAsync(csvData2)
    async let result3 = CsvParser.parseCSVAsync(csvData3)
    
    do {
        let (rows1, rows2, rows3) = try await (result1, result2, result3)
        
        print("Concurrent parsing results:")
        print("Dataset 1: \(rows1.count) rows")
        print("Dataset 2: \(rows2.count) rows")
        print("Dataset 3: \(rows3.count) rows")
        
        let totalRows = rows1.count + rows2.count + rows3.count
        print("Total rows processed: \(totalRows)")
        
    } catch {
        print("Concurrent processing error: \(error)")
    }
}

/// Task-based parsing with cancellation
func taskBasedParsingExample() async {
    print("\n=== Task-based Parsing with Cancellation Example ===")
    
    // Generate large dataset
    var csvContent = "id,data\n"
    for i in 1...10000 {
        csvContent += "\(i),data_\(i)\n"
    }
    
    let task = Task {
        return try await CsvParser.parseCSVAsync(csvContent)
    }
    
    // Simulate cancellation after a short delay
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
        task.cancel()
    }
    
    do {
        let rows = try await task.value
        print("Task completed: \(rows.count) rows")
    } catch {
        if error is CancellationError {
            print("Task was cancelled")
        } else {
            print("Task failed: \(error)")
        }
    }
}

// MARK: - Run Async Examples

func runAsyncExamples() async {
    await asyncParsingWithProgressExample()
    await asyncFileParsingExample()
    await asyncSequenceExample()
    await concurrentProcessingExample()
    await taskBasedParsingExample()
}

// Uncomment to run async examples:
// Task {
//     await runAsyncExamples()
// }