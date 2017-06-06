/*

 MIT License

 Copyright (c) 2017 Andy Best

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

 */


import Foundation

class Reader {
    let tokens: [TokenType]
    var pos = 0

    init(tokens: [TokenType]) {
        self.tokens = tokens
    }

    func nextToken() -> TokenType? {
        defer {
            pos += 1
        }

        if pos < tokens.count {
            return tokens[pos]
        }

        return nil
    }

    func read_token(_ token: TokenType) throws -> LispType {
        switch token {
            case .lParen:
                return try read_list()
            case .symbol(let str):

                // Handle keys
                if str.hasPrefix(":") {
                    return .key(str.substring(from: str.index(after: str.startIndex)))
                }

                return .symbol(str)
            case .string(let str):
                return .string(str)
            case .float(let num):
                return .float(num)
            default:
                Swift.print("Error while reading token \(token) at index \(pos)")
                return .nil
        }
    }

    func read_list() throws -> LispType {
        var list: [LispType] = []
        var endOfList        = false

        while let token = nextToken() {
            switch token {
                case .rParen:
                    endOfList = true
                default:
                    list.append(try read_token(token))
            }

            if endOfList {
                break
            }
        }

        if !endOfList {
            throw LispError.readerNotEOF
        }

        return .list(list)
    }

    static func read(_ input: String) throws -> LispType {
        let tokenizer = Tokenizer(source: input)
        let tokens    = try tokenizer.tokenizeInput()

        let reader = Reader(tokens: tokens)
        return try reader.read_token(reader.nextToken()!)
    }
}
