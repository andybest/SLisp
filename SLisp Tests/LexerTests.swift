//
//  SLisp_Tests.swift
//  SLisp Tests
//
//  Created by Andy Best on 01/06/2016.
//  Copyright © 2016 Andy Best. All rights reserved.
//

import XCTest

class LexerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /*func tokensForString(_ str:String) -> [TokenType] {
        let tokenizer = Tokenizer(source: str)
        return tokenizer.tokenizeInput()
    }

    
    func testAtom() {
        let tokens = tokensForString("symbol")
        
        XCTAssertEqual(tokens.count, 1)
        //XCTAssertEqual(tokens.first!, TokenType.Atom("atom"))
    }
    
    func testNumber() {
        let integerTokens = tokensForString("12")
        XCTAssertEqual(integerTokens.count, 1)
        //XCTAssertEqual(integerTokens.first!, TokenType.Number(12))
        
        let floatTokens = tokensForString("12.34")
        XCTAssertEqual(floatTokens.count, 1)
        //XCTAssertEqual(floatTokens.first!, TokenType.Number(12.34))
    }*/
    
}
