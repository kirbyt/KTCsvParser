import Testing
import Foundation
@testable import CsvParser

@Test("Sequence conformance for-in loop")
func testSequenceForInLoop() throws {
    let csvContent = "a,b\n1,2\n3,4"
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    var collectedRows: [[String]] = []
    
    for row in parser {
        collectedRows.append(row)
    }
    
    #expect(collectedRows.count == 3)
    #expect(collectedRows[0] == ["a", "b"])
    #expect(collectedRows[1] == ["1", "2"])
    #expect(collectedRows[2] == ["3", "4"])
}

@Test("Lazy mapping operations")
func testLazyMapping() throws {
    let csvContent = "1,2\n3,4\n5,6"
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    let sums = parser
        .map { row in row.compactMap(Int.init).reduce(0, +) }
        .prefix(2)
    
    let results = Array(sums)
    
    #expect(results.count == 2)
    #expect(results[0] == 3) // 1 + 2
    #expect(results[1] == 7) // 3 + 4
}

@Test("Filtering rows")
func testFilteringRows() throws {
    let csvContent = "name,age\nJohn,25\nJane,17\nBob,30"
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    // Skip header and filter for adults (age >= 18)
    let adults = parser
        .dropFirst() // Skip header
        .filter { row in
            guard row.count >= 2, let age = Int(row[1]) else { return false }
            return age >= 18
        }
    
    let results = Array(adults)
    
    #expect(results.count == 2)
    #expect(results[0][0] == "John")
    #expect(results[1][0] == "Bob")
}

@Test("Non-empty rows filtering")
func testNonEmptyRowsFiltering() throws {
    let csvContent = "a,b\n1,2\n3,4"
    let data = csvContent.data(using: .utf8)!
    
    let nonEmptyRows = CsvParser.nonEmptyRows(data: data)
    let results = Array(nonEmptyRows)
    
    #expect(results.count == 3)
    #expect(results[0] == ["a", "b"])
    #expect(results[1] == ["1", "2"])
    #expect(results[2] == ["3", "4"])
}

@Test("Minimum columns filtering")
func testMinimumColumnsFiltering() throws {
    let csvContent = "a\na,b\na,b,c\nd"
    let data = csvContent.data(using: .utf8)!
    
    let rowsWithMinCols = CsvParser.rowsWithMinimumColumns(data: data, minimumColumns: 2)
    let results = Array(rowsWithMinCols)
    
    #expect(results.count == 2)
    #expect(results[0] == ["a", "b"])
    #expect(results[1] == ["a", "b", "c"])
}

@Test("Dictionary parsing")
func testDictionaryParsing() throws {
    let csvContent = "name,age,city\nJohn,25,NYC\nJane,30,LA"
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    let dictionaries = try parser.parseAsDictionaries()
    
    #expect(dictionaries.count == 2)
    #expect(dictionaries[0]["name"] == "John")
    #expect(dictionaries[0]["age"] == "25")
    #expect(dictionaries[0]["city"] == "NYC")
    #expect(dictionaries[1]["name"] == "Jane")
    #expect(dictionaries[1]["age"] == "30")
    #expect(dictionaries[1]["city"] == "LA")
}

@Test("Header separation")
func testHeaderSeparation() throws {
    let csvContent = "name,age\nJohn,25\nJane,30"
    let parser = CsvParser(data: csvContent.data(using: .utf8)!)
    
    let (header, dataParser) = try parser.separateHeader()
    
    #expect(header == ["name", "age"])
    
    var dataRows: [[String]] = []
    while let row = try dataParser.readLine() {
        dataRows.append(row)
    }
    
    #expect(dataRows.count == 2)
    #expect(dataRows[0] == ["John", "25"])
    #expect(dataRows[1] == ["Jane", "30"])
}