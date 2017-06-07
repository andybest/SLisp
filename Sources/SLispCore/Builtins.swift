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

extension Dictionary {
    mutating func merge(_ dict: Dictionary<Key,Value>) {
        for (key, value) in dict {
            // If both dictionaries have a value for same key, the value of the other dictionary is used.
           self[key] = value
        }
    }
}

class Builtins {
    let env: Environment
    var builtins = [String : BuiltinBody]()
    
    init(env:Environment) {
        self.env = env
    }

    func namespaceName() -> String {
        return "user"
    }

    func loadImplementation() {
    }

    func bindToNamespace() {
        
    }
    
    func addBuiltin(_ name: String, _ body: @escaping BuiltinBody) {
        builtins[name] = body
    }
    
    func getBuiltins() -> [String: BuiltinBody] {
        return builtins
    }
    
    func loadBuiltinsFromFile(_ path:String) {
        
    }
    
    func checkArgCount(funcName: String, args: [LispType], expectedNumArgs: Int) throws {
        if args.count < expectedNumArgs {
            throw LispError.general(msg: "'\(funcName)' expects \(expectedNumArgs) arguments.")
        }
    }

    func initBuiltins() -> [String: BuiltinBody] {
        return [:]
    }

    // A generic function for arithmetic operations
    func doArithmeticOperation(_ args: [LispType], body:ArithmeticOperationBody) throws -> LispType {
        var x: lFloat = 0.0
        var firstArg = true

        let evaluated = try args.map { try env.eval($0) }

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
        let evaluated = try args.map { try env.eval($0) }

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
        let evaluated = try args.map { try env.eval($0) }

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
        let evaluated = try args.map { try env.eval($0) }

        guard case let .boolean(b) = evaluated[0] else {
            throw LispError.general(msg: "Invalid argument type: \(String(describing: evaluated[0]))")
        }

        return .boolean(body(b))
    }
}
