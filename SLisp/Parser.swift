//
//  Parser.swift
//  SLisp
//
//  Created by Andy Best on 25/05/2017.
//  Copyright © 2017 Andy Best. All rights reserved.
//

import Foundation


typealias lFloat = Double

enum LispType: CustomStringConvertible {
    case list([LispType])
    case atom(String)
    case float(lFloat)
    case `string`(String)
    case boolean(Bool)
    case `nil`
    
    var description: String {
        switch self {
        case .atom(let str):
            return str
        case .boolean(let bool):
            return String(bool)
        case .float(let f):
            return String(f)
        case .nil:
            return "nil"
        case .string(let str):
            return "\"\(str)\""
        case .list(let list):
            let elements = list.map { String(describing: $0) }.joined(separator: " ")
            return "(\(elements))"
        }
    }
    
}

class Reader {
    let tokens: [TokenType]
    var pos = 0
    
    init(tokens: [TokenType]) {
        self.tokens = tokens
    }
    
    func nextToken() -> TokenType? {
        defer { pos += 1 }
        return tokens[pos]
    }
}

class Repl {
    
    func mainLoop() {
        while true {
            Swift.print("user> ", terminator: "")
            
            if let input = readLine(strippingNewline: true) {
                Swift.print(rep(input))
            }
        }
    }
    
    func read_token(_ token: TokenType, reader: Reader) -> LispType {
        switch token {
        case .lParen:
            return read_list(reader)
        case .atom(let str):
            return .atom(str)
        case .lString(let str):
            return .string(str)
        case .number(let num):
            return .float(num)
        default:
            Swift.print("Error while reading token \(token) at index \(reader.pos)")
            return .nil
        }
    }
    
    func read_list(_ reader: Reader) -> LispType {
        var list: [LispType] = []
        
        while let token = reader.nextToken() {
            switch token {
            case .rParen:
                return LispType.list(list)
            default:
                list.append(read_token(token, reader: reader))
            }
        }
        
        return .list(list)
    }
    
    func read(_ input: String) -> LispType {
        let tokenizer = Tokenizer(source: input)
        let tokens = tokenizer.tokenizeInput()
        
        let reader = Reader(tokens: tokens)
        return read_token(reader.nextToken()!, reader: reader)
    }

    func eval() {
        
    }

    func print() {
        
    }

    func rep(_ input: String) -> LispType {
        return read(input)
    }
}
