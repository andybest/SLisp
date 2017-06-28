//
//  ReaderTests.swift
//  SLispCoreTests
//
//  Created by Andy Best on 08/06/2017.
//

import XCTest
@testable import SLispCore

class ReaderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testComplexSExpression() {
        // Test case adapted from Rosetta Code:
        // https://rosettacode.org/wiki/S-Expressions
        // ((data "quoted data" 123 4.5)
        //      (data (!@# (4.5) "(more" "data)")) :key)
        
        let r = Reader(tokens: [
            TokenType.lParen,           TokenType.lParen,
            TokenType.symbol("data"),   TokenType.string("quoted data"),
            TokenType.integer(123),     TokenType.float(4.5),
            TokenType.rParen,           TokenType.lParen,
            TokenType.symbol("data"),   TokenType.lParen,
            TokenType.symbol("!@#"),    TokenType.lParen,
            TokenType.float(4.5),       TokenType.rParen,
            TokenType.string("(more"),  TokenType.string("data)"),
            TokenType.rParen,           TokenType.rParen,
            TokenType.symbol(":key"),   TokenType.rParen
            ])
        
        let form: LispType
        do {
            form = try r.read_token(r.nextToken()!)
        } catch {
            XCTFail("Should not throw an exception")
            return
        }
        
        let expected: LispType = .list([
            .list([
                .symbol("data"), .string("quoted data"),
                .number(.integer(123)), .number(.float(4.5))]),
                .list([
                    .symbol("data"), .list([
                        .symbol("!@#"), .list([ .number(.float(4.5)) ]),
                        .string("(more"), .string("data)")
                        ])
                    ]),
                    .key("key")
            ])
        
        XCTAssertEqual(form, expected)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
