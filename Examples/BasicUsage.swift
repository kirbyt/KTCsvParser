import Foundation
import CsvParser

// MARK: - Basic CSV Parsing Examples

/// Basic parsing of CSV strings
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

/// Parsing with custom configuration
func customConfigurationExample() {
    print("\n=== Custom Configuration Example ===")
    
    let tsvString = "name\tage\tcity\nJohn\t25\tNYC\nJane\t30\tLA"
    
    let config = CsvConfiguration(
        valueSeparator: "\t",           // Tab-separated
        quoteCharacter: nil,            // No quotes
        ignoreLeadingWhitespaces: true  // Ignore leading spaces
    )
    
    do {
        let rows = try CsvParser.parseCSV(tsvString, configuration: config)
        print("Parsed TSV data:")
        for row in rows {
            print(row)
        }
    } catch {
        print("Error parsing TSV: \(error)")
    }
}

/// Handling quoted fields with embedded commas
func quotedFieldsExample() {
    print("\n=== Quoted Fields Example ===")
    
    let csvString = """
    name,description,price
    "Apple iPhone","Latest smartphone, very expensive",999.99
    "MacBook Pro","Laptop for professionals, with M1 chip",2499.00
    """
    
    do {
        let rows = try CsvParser.parseCSV(csvString)
        print("Products:")
        for row in rows.dropFirst() { // Skip header
            print("Name: \(row[0])")
            print("Description: \(row[1])")
            print("Price: $\(row[2])")
            print("---")
        }
    } catch {
        print("Error parsing CSV: \(error)")
    }
}

/// Error handling with Result types
func errorHandlingExample() {
    print("\n=== Error Handling Example ===")
    
    let csvString = "a,b,c\n1,2,3"
    
    // Using Result type for safe parsing
    let result = CsvParser.parseCSVSafely(csvString)
    
    switch result {
    case .success(let rows):
        print("Successfully parsed \(rows.count) rows")
        for row in rows {
            print(row)
        }
    case .failure(let error):
        print("Parsing failed: \(error.localizedDescription)")
    }
}

/// File parsing example
func fileParsingExample() {
    print("\n=== File Parsing Example ===")
    
    // Create a temporary CSV file
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("sample.csv")
    
    let csvContent = """
    id,name,email,department
    1,John Doe,john@example.com,Engineering
    2,Jane Smith,jane@example.com,Marketing
    3,Bob Johnson,bob@example.com,Sales
    """
    
    do {
        // Write sample data to file
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Parse the file
        let parser = try CsvParser(path: fileURL.path)
        
        var rowCount = 0
        for row in parser {
            print("Row \(rowCount): \(row)")
            rowCount += 1
        }
        
        // Clean up
        try FileManager.default.removeItem(at: fileURL)
        
    } catch {
        print("Error with file parsing: \(error)")
    }
}

// MARK: - Run Examples

func runBasicExamples() {
    basicParsingExample()
    customConfigurationExample()
    quotedFieldsExample()
    errorHandlingExample()
    fileParsingExample()
}

// Uncomment to run examples:
// runBasicExamples()