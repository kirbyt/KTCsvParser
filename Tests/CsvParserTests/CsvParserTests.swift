import Testing
import Foundation
@testable import CsvParser

@Test("Simple line parsing") 
func testSimpleLineParse() throws {
    let csvString = "a, b, c"
    let values = try CsvParser.parseCSVLine(csvString)
    
    #expect(values.count == 3)
    #expect(values[0] == "a")
    #expect(values[1] == " b")
    #expect(values[2] == " c")
}

@Test("Ignore leading whitespaces")
func testIgnoreLeadingWhitespaces() throws {
    let csvString = "a, b, c "
    let config = CsvConfiguration(ignoreLeadingWhitespaces: true)
    let values = try CsvParser.parseCSVLine(csvString, configuration: config)
    
    #expect(values.count == 3)
    #expect(values[0] == "a")
    #expect(values[1] == "b")
    #expect(values[2] == "c ")
}

@Test("Embedded quotes parsing")
func testEmbeddedQuotes() throws {
    let csvString = "a,\"\"\"b\"\"\",c\r1,2,3"
    let parser = CsvParser(data: csvString.data(using: .utf8)!)
    
    var allRows: [[String]] = []
    while let row = try parser.readLine() {
        allRows.append(row)
    }
    
    #expect(allRows.count == 2)
    #expect(allRows[0].count == 3)
    #expect(allRows[0][0] == "a")
    #expect(allRows[0][1] == "\"b\"")
    #expect(allRows[0][2] == "c")
    #expect(allRows[1].count == 3)
    #expect(allRows[1][0] == "1")
    #expect(allRows[1][1] == "2")
    #expect(allRows[1][2] == "3")
}

@Test("Excel ellipsis bug handling")
func testExcelEllipsisBug() throws {
    let csvString = "…This is…a test.,another field"
    let parser = CsvParser(data: csvString.data(using: .utf8)!)
    
    guard let values = try parser.readLine() else {
        Issue.record("Expected to read a line")
        return
    }
    
    #expect(values.count == 2)
    #expect(values[0] == "…This is…a test.")
    #expect(values[1] == "another field")
}

@Test("Simple quote character handling")
func testSimpleQuoteCharacter() throws {
    let csvString = "a,\"b,c\",d"
    let values = try CsvParser.parseCSVLine(csvString)
    
    #expect(values.count == 3)
    #expect(values[0] == "a")
    #expect(values[1] == "b,c")
    #expect(values[2] == "d")
}

@Test("Quote character with embedded comma")
func testQuoteCharacter() throws {
    let csvString = "a,b,\"This is fun, ain't it.\",c"
    let values = try CsvParser.parseCSVLine(csvString)
    
    #expect(values.count == 4)
    #expect(values[0] == "a")
    #expect(values[1] == "b")
    #expect(values[2] == "This is fun, ain't it.")
    #expect(values[3] == "c")
}

@Test("Quote character as last field")
func testQuoteCharacterAsLastField() throws {
    let csvString = "a,b,\"This is fun, ain't it.\""
    let values = try CsvParser.parseCSVLine(csvString)
    
    #expect(values.count == 3)
    #expect(values[0] == "a")
    #expect(values[1] == "b")
    #expect(values[2] == "This is fun, ain't it.")
}

@Test("Quote character as last field with leading whitespace ignored")
func testQuoteCharacterAsLastFieldIgnoringWhitespaces() throws {
    let csvString = "a,b, \"This is fun, ain't it.\""
    let config = CsvConfiguration(ignoreLeadingWhitespaces: true)
    let values = try CsvParser.parseCSVLine(csvString, configuration: config)
    
    #expect(values.count == 3)
    #expect(values[0] == "a")
    #expect(values[1] == "b")
    #expect(values[2] == "This is fun, ain't it.")
}

// MARK: - Additional Swift-specific Tests

@Test("Error handling with invalid file path")
func testInvalidFilePath() {
    do {
        _ = try CsvParser(path: "/nonexistent/path/file.csv")
        Issue.record("Expected error for invalid file path")
    } catch {
        // Expected - file doesn't exist
        #expect(error is CsvParserError)
    }
}

@Test("Custom separator parsing")
func testCustomSeparator() throws {
    let csvString = "a|b|c"
    let config = CsvConfiguration(valueSeparator: "|")
    let values = try CsvParser.parseCSVLine(csvString, configuration: config)
    
    #expect(values.count == 3)
    #expect(values[0] == "a")
    #expect(values[1] == "b")
    #expect(values[2] == "c")
}

@Test("Result-based parsing success")
func testResultBasedParsingSuccess() {
    let csvString = "a,b,c"
    let result = CsvParser.parseCSVLineSafely(csvString)
    
    switch result {
    case .success(let values):
        #expect(values.count == 3)
        #expect(values[0] == "a")
        #expect(values[1] == "b")
        #expect(values[2] == "c")
    case .failure:
        Issue.record("Expected success but got failure")
    }
}

@Test("Empty fields handling")
func testEmptyFields() throws {
    let csvString = "a,,c"
    let values = try CsvParser.parseCSVLine(csvString)
    
    #expect(values.count == 3)
    #expect(values[0] == "a")
    #expect(values[1] == "")
    #expect(values[2] == "c")
}

@Test("Unicode character support")
func testUnicodeSupport() throws {
    let csvString = "🚀,café,München"
    let values = try CsvParser.parseCSVLine(csvString)
    
    #expect(values.count == 3)
    #expect(values[0] == "🚀")
    #expect(values[1] == "café")
    #expect(values[2] == "München")
}

@Test("Parse all rows functionality")
func testParseAllRows() throws {
    let csvContent = """
    name,age,city
    John,25,NYC
    Jane,30,LA
    """
    
    let allRows = try CsvParser.parseCSV(csvContent)
    
    #expect(allRows.count == 3)
    #expect(allRows[0] == ["name", "age", "city"])
    #expect(allRows[1] == ["John", "25", "NYC"])
    #expect(allRows[2] == ["Jane", "30", "LA"])
}