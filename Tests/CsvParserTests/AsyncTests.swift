import Testing
import Foundation
@testable import CsvParser

@Test("Async line parsing")
func testAsyncLineParsing() async throws {
    let csvString = "a,b,c\n1,2,3"
    let parser = CsvParser(data: csvString.data(using: .utf8)!)
    
    let firstRow = try await parser.readLineAsync()
    #expect(firstRow == ["a", "b", "c"])
    
    let secondRow = try await parser.readLineAsync()
    #expect(secondRow == ["1", "2", "3"])
    
    let thirdRow = try await parser.readLineAsync()
    #expect(thirdRow == nil)
}

@Test("Async parse all")
func testAsyncParseAll() async throws {
    let csvContent = """
    name,age,city
    John,25,NYC
    Jane,30,LA
    """
    
    let allRows = try await CsvParser.parseCSVAsync(csvContent)
    
    #expect(allRows.count == 3)
    #expect(allRows[0] == ["name", "age", "city"])
    #expect(allRows[1] == ["John", "25", "NYC"])
    #expect(allRows[2] == ["Jane", "30", "LA"])
}

@Test("Async sequence iteration")
func testAsyncSequence() async throws {
    let csvContent = "a,b\n1,2\n3,4"
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    var collectedRows: [[String]] = []
    
    for try await row in parser.asyncSequence {
        collectedRows.append(row)
    }
    
    #expect(collectedRows.count == 3)
    #expect(collectedRows[0] == ["a", "b"])
    #expect(collectedRows[1] == ["1", "2"])
    #expect(collectedRows[2] == ["3", "4"])
}

@Test("Async progress reporting")
func testAsyncProgressReporting() async throws {
    let csvContent = String(repeating: "a,b,c\n", count: 500)
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    var progressUpdates: [Int] = []
    
    let rows = try await parser.parseAllAsync { lineNumber in
        progressUpdates.append(lineNumber)
    }
    
    #expect(rows.count == 500)
    #expect(!progressUpdates.isEmpty)
    #expect(progressUpdates.last == 500)
}