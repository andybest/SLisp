/*
 
 MIT License
 
 Copyright (c) 2016 Andy Best
 
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

class MathBuiltins : Builtins {
    
    override init(parser: Parser) {
        super.init(parser: parser)
    }

    override func namespaceName() -> String {
        return "math"
    }
    
    override func initBuiltins(environment: Environment) -> [String: BuiltinDef] {
        addBuiltin("range", docstring: """
        range
        (min max)
        Creates a list of numbers min < n < max
        """) { args, env throws in
            if args.count != 2 {
                throw LispError.runtime(msg: "'range' requires 2 arguments")
            }
            
            guard case let .number(minN) = args[0], case let .integer(min) = minN,
                case let .number(maxN) = args[1], case let .integer(max) = maxN else {
                throw LispError.runtime(msg: "'range' requires 2 integer arguments")
            }
            
            let rv: [LispType] = (min..<max).map { LispType.number(.integer($0)) }
            return .list(rv)
        }
        
        return builtins
    }
}
