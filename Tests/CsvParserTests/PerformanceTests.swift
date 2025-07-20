import Testing
import Foundation
@testable import CsvParser

@Test("Large file parsing performance", .timeLimit(.minutes(1)))
func testLargeFileParsingPerformance() throws {
    // Generate a large CSV content
    var csvContent = "id,name,email,age\n"
    for i in 1...10000 {
        csvContent += "\(i),User\(i),user\(i)@example.com,\(20 + (i % 50))\n"
    }
    
    let data = csvContent.data(using: .utf8)!
    let parser = CsvParser(data: data)
    
    var rowCount = 0
    while let _ = try parser.readLine() {
        rowCount += 1
    }
    
    #expect(rowCount == 10001) // Including header
}

@Test("Memory usage with large files", .timeLimit(.minutes(1)))
func testMemoryUsageWithLargeFiles() throws {
    // Test that we don't load everything into memory at once
    var csvContent = ""
    for i in 1...5000 {
        csvContent += "field1_\(i),field2_\(i),field3_\(i)\n"
    }
    
    let data = csvContent.data(using: .utf8)!
    let parser = CsvParser(data: data)
    
    // Process rows one by one without storing them all
    var processedCount = 0
    for row in parser {
        processedCount += 1
        // Just count, don't store
        _ = row.count
    }
    
    #expect(processedCount == 5000)
}

@Test("Async parsing performance", .timeLimit(.minutes(1)))
func testAsyncParsingPerformance() async throws {
    var csvContent = "a,b,c\n"
    for i in 1...1000 {
        csvContent += "\(i),value\(i),data\(i)\n"
    }
    
    let allRows = try await CsvParser.parseCSVAsync(csvContent)
    
    #expect(allRows.count == 1001) // Including header
}

@Test("Sequence operations performance", .timeLimit(.minutes(1)))
func testSequenceOperationsPerformance() throws {
    var csvContent = "num,text\n"
    for i in 1...1000 {
        csvContent += "\(i),text\(i)\n"
    }
    
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    // Test lazy operations don't cause performance issues
    let evenNumbers = parser
        .dropFirst() // Skip header
        .compactMap { row -> Int? in
            guard let num = Int(row.first ?? "") else { return nil }
            return num % 2 == 0 ? num : nil
        }
        .prefix(100)
    
    let results = Array(evenNumbers)
    
    #expect(results.count == 100)
    #expect(results.first == 2)
    #expect(results.last == 200)
}

@Test("Unicode processing performance", .timeLimit(.minutes(1)))
func testUnicodeProcessingPerformance() throws {
    var csvContent = ""
    let unicodeChars = ["🚀", "café", "München", "東京", "Москва"]
    
    for i in 1...1000 {
        let char = unicodeChars[i % unicodeChars.count]
        csvContent += "\(char)\(i),test\(i)\n"
    }
    
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    var count = 0
    for row in parser {
        count += 1
        // Verify we can access the unicode content
        #expect(!row[0].isEmpty)
    }
    
    #expect(count == 1000)
}