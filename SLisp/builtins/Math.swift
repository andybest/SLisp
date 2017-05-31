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
    
    func loadImplementation() {
        // Load core library implemented in SLisp
        let path = "./data/math.sl"
        if env.evalFile(path: path) == nil {
            print("Math library implementation could not be loaded!")
        }
    }
    
    // A generic function for arithmetic operations
    func doArithmeticOperation(_ args: [LispType], body:ArithmeticOperationBody) throws -> LispType {
        var x: lFloat = 0.0
        var firstArg = true
        
        let evaluated = try args.map { try env.eval($0, env: env) }
        
        for arg in evaluated {
            guard case let .float(num) = arg else {
                throw LispError.general(msg: "Invalid argument type: \(String(describing: arg))")
            }
            
            if firstArg {
                x = num
                firstArg = false
            } else {
                x = body(x, num)
            }
        }
        
        return .float(x)
    }
    
    func doBooleanArithmeticOperation(_ args: [LispType], body: ArithmeticBooleanOperationBody) throws -> LispType {
        var result: Bool = false
        var lastValue: lFloat = 0.0
        var firstArg = true
        let evaluated = try args.map { try env.eval($0, env: env) }
        
        for arg in evaluated {
            guard case let .float(num) = arg else {
                throw LispError.general(msg: "Invalid argument type: \(String(describing: arg))")
            }
            
            if firstArg {
                lastValue = num
                firstArg = false
            } else {
                result = body(lastValue, num)
            }
        }
        
        return .boolean(result)
    }
    
    func doBooleanOperation(_ args: [LispType], body:BooleanOperationBody) throws -> LispType {
        var result: Bool = false
        var lastValue: Bool = false
        var firstArg = true
        let evaluated = try args.map { try env.eval($0, env: env) }
        
        for arg in evaluated {
            guard case let .boolean(b) = arg else {
                throw LispError.general(msg: "Invalid argument type: \(String(describing: arg))")
            }
            
            if firstArg {
                lastValue = b
                firstArg = false
            } else {
                result = body(lastValue, b)
            }
        }
        
        return .boolean(result)
    }
    
    func doSingleBooleanOperation(_ args: [LispType], body:SingleBooleanOperationBody) throws -> LispType {
        let evaluated = try args.map { try env.eval($0, env: env) }
        
        guard case let .boolean(b) = evaluated[0] else {
            throw LispError.general(msg: "Invalid argument type: \(String(describing: evaluated[0]))")
        }
        
        return .boolean(body(b))
    }
    
    func initBuiltins() -> [String: BuiltinBody] {
        addBuiltin("+") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x + y
            }
        }
        
        addBuiltin("-") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x - y
            }
        }
        
        addBuiltin("*") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x * y
            }
        }
        
        addBuiltin("/") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x / y
            }
        }
        
        addBuiltin("mod") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return remainder(x, y)
            }
        }
        
        addBuiltin(">") { args, env throws in
            return try self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x > y
            }
        }
        
        addBuiltin("<") { args, env throws in
            return try self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x < y
            }
        }
        
        addBuiltin("==") { args, env throws in
            return try self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x == y
            }
        }
        
        addBuiltin("and") { args, env throws in
            return try self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x && y
            }
        }
        
        addBuiltin("or") { args, env throws in
            return try self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x || y
            }
        }
        
        addBuiltin("not") { args, env throws in
            return try self.doSingleBooleanOperation(args) { (x: Bool) -> Bool in
                return !x
            }
        }
        
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
