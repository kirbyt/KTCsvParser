# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KTCsvParser is an Objective-C library for parsing CSV (comma-separated value) data. It's a read-only parser that uses NSInputStream for efficient streaming parsing of CSV data from strings, files, or URLs.

## Key Components

- **KTCsvParser**: Main parser class that handles CSV parsing with configurable separators and quote characters
- **KTBufferedStreamReader**: Helper class that provides buffered reading from NSInputStream for efficient parsing

## Architecture

The parser uses a state machine approach with four main states:
- `STATE_UNKNOWN`: Initial state
- `STATE_CONTINUE_WITH_REGULAR_FIELD`: Processing normal fields
- `STATE_CONTINUE_WITH_EMBEDDED_QUOTES_OR_COMMAS`: Handling fields with embedded quotes/commas
- `STATE_BEGINNING_OF_EMBEDDED_QUOTES`: Start of quoted field

Key features:
- Configurable value separator (default: comma)
- Configurable quote character for embedded separators/quotes
- Option to ignore leading whitespaces
- Support for multiple input sources (NSData, file path, NSInputStream, NSURL)
- Static utility methods for parsing single CSV lines

## Development Commands

### Building and Testing
- Open `KTCsvParserTests/KTCsvParserTests.xcodeproj` in Xcode
- Build: Cmd+B or Product → Build
- Run tests: Cmd+U or Product → Test
- Tests use SenTestingKit framework (legacy OCUnit)

### Project Structure
```
KTCsvParser/                 # Main library source files
├── KTCsvParser.h/.m         # Main parser implementation
└── KTBufferedStreamReader.h/.m  # Buffered stream reader

KTCsvParserTests/            # Test project
├── KTCsvParserTests.xcodeproj/  # Xcode project for tests
└── KTCsvParserTests/        # Test source files
```

## Usage Patterns

The parser supports both streaming (line-by-line) and static parsing:

**Streaming parsing:**
```objc
KTCsvParser *parser = [[KTCsvParser alloc] initWithFileAtPath:path];
while ([parser readLine]) {
    NSArray *values = [parser values];
    // Process values
}
```

**Static parsing:**
```objc
NSArray *values = [KTCsvParser valuesFromCsvLine:csvString 
                                withValueSeparator:@"," 
                                   quoteCharacter:@"\"" 
                           ignoreLeadingWhitespaces:YES];
```

## Testing

Tests are located in `KTCsvParserTests/KTCsvParserTests/KTCsvParserTests.m` and cover:
- Simple line parsing
- Whitespace handling
- Quote character processing
- Various separator configurations

Use Xcode's built-in test runner to execute the test suite.