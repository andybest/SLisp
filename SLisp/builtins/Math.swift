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

typealias ArithmeticOperationBody = (lFloat, lFloat) -> lFloat
typealias ArithmeticBooleanOperationBody = (lFloat, lFloat) -> Bool
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
        let path = "./data/math.sl"
        if env.evalFile(path: path, toNamespace: env.createOrGetNamespace(self.namespaceName())) == nil {
            print("Math library implementation could not be loaded!")
        }
    }
    
    override func initBuiltins() -> [String: BuiltinBody] {
        
        addBuiltin("sqrt") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'sqrt' requires one argument")
            }
            
            let evaluated = try args.map { try env.eval($0, env: env) }
            
            guard case let .float(num) = evaluated[0] else {
                throw LispError.general(msg: "'sqrt' requires a float argument.")
            }
            
            return .float(sqrt(num))
        }
        
        addBuiltin("random") { args, env throws in
            try self.checkArgCount(funcName: "random", args: args, expectedNumArgs: 2)
            
            let evaluated = try args.map { try env.eval($0, env: env) }
            
            guard case let .float(lowerBound) = evaluated[0], case let .float(upperBound) = evaluated[1] else {
                throw LispError.general(msg: "'random' requires two float arguments")
            }
            
            let r = (Double(arc4random()) / Double(UInt32.max) * (upperBound - lowerBound)) + lowerBound
            
            return .float(r)
        }
        
        return builtins
    }
}
