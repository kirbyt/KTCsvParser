//
//  KTCsvParserTestCases.h
//  MacTests
//
//  Created by Kirby Turner on 1/22/11.
//  Copyright 2011 White Peak Software Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface KTCsvParserTestCases : SenTestCase 
{

}

- (void)testSimpleLineParse;
- (void)testEmbeddedQuotes;
- (void)testExcelEllipsisBug;

@end
