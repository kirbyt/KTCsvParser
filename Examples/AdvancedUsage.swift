import Foundation
import CsvParser

// MARK: - Advanced Usage Examples

/// Functional programming with CSV data
func functionalProgrammingExample() {
    print("=== Functional Programming Example ===")
    
    let csvContent = """
    name,age,salary,department
    John Doe,28,75000,Engineering
    Jane Smith,32,85000,Engineering
    Bob Johnson,45,95000,Management
    Alice Brown,29,70000,Design
    Charlie Wilson,38,80000,Engineering
    Diana Lee,41,90000,Management
    """
    
    do {
        let parser = CsvParser(data: csvContent.data(using: .utf8)!)
        
        // Complex functional chain
        let engineeringStats = parser
            .dropFirst()                           // Skip header
            .filter { $0.count >= 4 }             // Ensure complete rows
            .filter { $0[3] == "Engineering" }    // Engineering department only
            .compactMap { row -> (String, Int, Double)? in
                guard let age = Int(row[1]),
                      let salary = Double(row[2]) else { return nil }
                return (row[0], age, salary)
            }
            .sorted { $0.2 > $1.2 }               // Sort by salary descending
        
        print("Engineering Department (by salary):")
        for (name, age, salary) in engineeringStats {
            print("  \(name) - Age: \(age), Salary: $\(Int(salary))")
        }
        
        // Calculate statistics
        let salaries = Array(engineeringStats.map { $0.2 })
        let averageSalary = salaries.reduce(0, +) / Double(salaries.count)
        print("Average Engineering Salary: $\(Int(averageSalary))")
        
    } catch {
        print("Error in functional programming example: \(error)")
    }
}

/// Data transformation and aggregation
func dataTransformationExample() {
    print("\n=== Data Transformation Example ===")
    
    let salesData = """
    date,product,quantity,price
    2024-01-01,Widget A,10,25.50
    2024-01-01,Widget B,5,45.00
    2024-01-02,Widget A,8,25.50
    2024-01-02,Widget C,12,35.75
    2024-01-03,Widget B,15,45.00
    2024-01-03,Widget A,6,25.50
    """
    
    do {
        let parser = CsvParser(data: salesData.data(using: .utf8)!)
        
        // Transform to dictionaries
        let salesRecords = try parser.parseAsDictionaries()
        
        // Group by product and calculate totals
        var productTotals: [String: (quantity: Int, revenue: Double)] = [:]
        
        for record in salesRecords {
            guard let product = record["product"],
                  let quantityStr = record["quantity"],
                  let priceStr = record["price"],
                  let quantity = Int(quantityStr),
                  let price = Double(priceStr) else { continue }
            
            let revenue = Double(quantity) * price
            
            if var existing = productTotals[product] {
                existing.quantity += quantity
                existing.revenue += revenue
                productTotals[product] = existing
            } else {
                productTotals[product] = (quantity: quantity, revenue: revenue)
            }
        }
        
        print("Product Sales Summary:")
        for (product, totals) in productTotals.sorted(by: { $0.value.revenue > $1.value.revenue }) {
            print("  \(product): \(totals.quantity) units, $\(String(format: "%.2f", totals.revenue)) revenue")
        }
        
    } catch {
        print("Error in data transformation: \(error)")
    }
}

/// Memory-efficient large file processing
func largeFileProcessingExample() {
    print("\n=== Large File Processing Example ===")
    
    // Simulate a large dataset
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent("large_dataset.csv")
    
    do {
        // Generate large CSV file
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        defer { fileHandle.closeFile() }
        
        // Write header
        let header = "id,timestamp,user_id,action,value\n"
        fileHandle.write(header.data(using: .utf8)!)
        
        // Write 50,000 records in batches
        for batch in 0..<500 {
            var batchData = ""
            for i in 1...100 {
                let id = batch * 100 + i
                let timestamp = Date().timeIntervalSince1970 + Double(id)
                let userId = (id % 1000) + 1
                let action = "action_\(id % 10)"
                let value = Int.random(in: 1...1000)
                
                batchData += "\(id),\(timestamp),\(userId),\(action),\(value)\n"
            }
            fileHandle.write(batchData.data(using: .utf8)!)
        }
        
        print("Generated large CSV file with 50,000+ records")
        
        // Process file efficiently
        let parser = try CsvParser(path: fileURL.path)
        
        var recordCount = 0
        var actionCounts: [String: Int] = [:]
        var totalValue = 0
        
        // Process one row at a time (memory efficient)
        for row in parser.lazy {
            recordCount += 1
            
            if recordCount == 1 { continue } // Skip header
            
            if row.count >= 5 {
                let action = row[3]
                let value = Int(row[4]) ?? 0
                
                actionCounts[action, default: 0] += 1
                totalValue += value
            }
            
            // Progress indicator
            if recordCount % 10000 == 0 {
                print("Processed \(recordCount) records...")
            }
        }
        
        print("Processing complete:")
        print("  Total records: \(recordCount)")
        print("  Total value: \(totalValue)")
        print("  Action distribution:")
        for (action, count) in actionCounts.sorted(by: { $0.key < $1.key }) {
            print("    \(action): \(count)")
        }
        
        // Clean up
        try FileManager.default.removeItem(at: fileURL)
        
    } catch {
        print("Error in large file processing: \(error)")
    }
}

/// Custom CSV format handling
func customFormatExample() {
    print("\n=== Custom Format Example ===")
    
    // European CSV format (semicolon separated, comma as decimal)
    let europeanCSV = """
    Name;Age;Salary;City
    "Müller, Hans";35;45.500,50;München
    "Dupont, Marie";28;38.250,75;Paris
    "Smith, John";42;52.750,00;London
    """
    
    let config = CsvConfiguration(
        valueSeparator: ";",
        quoteCharacter: "\"",
        ignoreLeadingWhitespaces: true
    )
    
    do {
        let rows = try CsvParser.parseCSV(europeanCSV, configuration: config)
        
        print("European CSV Format:")
        for (index, row) in rows.enumerated() {
            if index == 0 {
                print("Headers: \(row.joined(separator: " | "))")
            } else {
                // Parse salary (replace comma with dot for decimal)
                let salary = row[2].replacingOccurrences(of: ",", with: ".")
                print("  \(row[0]) - Age: \(row[1]), Salary: €\(salary), City: \(row[3])")
            }
        }
        
    } catch {
        print("Error parsing European CSV: \(error)")
    }
}

/// Streaming with real-time processing
func streamingProcessingExample() {
    print("\n=== Streaming Processing Example ===")
    
    let logData = """
    timestamp,level,module,message
    2024-01-01T10:00:00Z,INFO,auth,User login successful
    2024-01-01T10:01:00Z,ERROR,database,Connection timeout
    2024-01-01T10:02:00Z,WARN,cache,Cache miss for key abc123
    2024-01-01T10:03:00Z,INFO,api,Request processed successfully
    2024-01-01T10:04:00Z,ERROR,auth,Invalid password attempt
    2024-01-01T10:05:00Z,DEBUG,performance,Query took 250ms
    """
    
    do {
        let parser = CsvParser(data: logData.data(using: .utf8)!)
        
        var logStats: [String: Int] = [:]
        var errors: [String] = []
        
        // Process logs in real-time
        for (index, row) in parser.enumerated() {
            if index == 0 { continue } // Skip header
            
            guard row.count >= 4 else { continue }
            
            let level = row[1]
            let module = row[2]
            let message = row[3]
            
            // Count log levels
            logStats[level, default: 0] += 1
            
            // Collect errors for review
            if level == "ERROR" {
                errors.append("\(module): \(message)")
            }
            
            // Real-time alerting (simulation)
            if level == "ERROR" {
                print("🚨 ALERT: \(level) in \(module) - \(message)")
            }
        }
        
        print("\nLog Analysis Summary:")
        print("Level distribution:")
        for (level, count) in logStats.sorted(by: { $0.key < $1.key }) {
            print("  \(level): \(count)")
        }
        
        print("\nErrors found:")
        for error in errors {
            print("  • \(error)")
        }
        
    } catch {
        print("Error in streaming processing: \(error)")
    }
}

// MARK: - Run Advanced Examples

func runAdvancedExamples() {
    functionalProgrammingExample()
    dataTransformationExample()
    largeFileProcessingExample()
    customFormatExample()
    streamingProcessingExample()
}

// Uncomment to run advanced examples:
// runAdvancedExamples()