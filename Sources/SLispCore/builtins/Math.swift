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

typealias ArithmeticOperationBody = (LispNumber, LispNumber) -> LispNumber
typealias SingleValueArithmeticOperationBody = (LispNumber) -> LispNumber
typealias ArithmeticBooleanOperationBody = (LispNumber, LispNumber) -> Bool
typealias SingleArithmeticBooleanOperationBody = (LispNumber) -> Bool
typealias BooleanOperationBody = (Bool, Bool) -> Bool
typealias SingleBooleanOperationBody = (Bool) -> Bool

class MathBuiltins : Builtins {
    
    override init(env:Environment) {
        super.init(env: env)
    }

    override func namespaceName() -> String {
        return "math"
    }

    override func loadImplementation() {
        // Load core library implemented in SLisp
        let path = "./Lib/math.sl"
        if env.evalFile(path: path) == nil {
            print("Math library implementation could not be loaded!")
        }
    }
    
    override func initBuiltins() -> [String: BuiltinDef] {
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
