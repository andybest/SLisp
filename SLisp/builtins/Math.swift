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

typealias ArithmeticOperationBody = (Double, Double) -> Double
typealias ArithmeticBooleanOperationBody = (Double, Double) -> Bool
typealias BooleanOperationBody = (Bool, Bool) -> Bool
typealias SingleBooleanOperationBody = (Bool) -> Bool

class MathBuiltins : Builtins {
    
    override init(env:Environment) {
        super.init(env: env)
        self.initBuiltins()
    }
    
    // A generic function for arithmetic operations
    func doArithmeticOperation(_ args:Pair?, body:ArithmeticOperationBody) -> LispType {
        var x: Double = 0.0
        var firstArg = true
        var p: Pair? = checkArgs(args, env: env)
        
        while p != nil {
            switch p!.value {
            case .number(let num):
                if firstArg {
                    x = num
                    firstArg = false
                } else {
                    x = body(x, num)
                }
                break
                
            default:
                print("Invalid argument: \(p!.value)")
                return LispType.nil
            }
            
            p = p?.next
        }
        
        return LispType.number(x)
    }
    
    func doBooleanArithmeticOperation(_ args:Pair?, body:ArithmeticBooleanOperationBody) -> LispType {
        var result: Bool = false
        var lastValue: Double = 0.0
        var firstArg = true
        var p: Pair? = checkArgs(args, env: env)
        
        while p != nil {
            switch p!.value {
            case .number(let num):
                if firstArg {
                    lastValue = num
                    firstArg = false
                } else {
                    result = body(lastValue, num)
                    lastValue = num
                }
                break
                
            default:
                print("Invalid argument: \(p!.value)")
                return LispType.nil
            }
            
            p = p?.next
        }
        
        return LispType.lBoolean(result)
    }
    
    func doBooleanOperation(_ args:Pair?, body:BooleanOperationBody) -> LispType {
        var result: Bool = false
        var lastValue: Bool = false
        var firstArg = true
        var p: Pair? = checkArgs(args, env: env)
        
        while p != nil {
            switch p!.value {
            case .lBoolean(let b):
                if firstArg {
                    lastValue = b
                    firstArg = false
                } else {
                    result = body(lastValue, b)
                    lastValue = b
                }
                break
                
            default:
                print("Invalid argument: \(p!.value)")
                return LispType.nil
            }
            
            p = p?.next
        }
        
        return LispType.lBoolean(result)
    }
    
    func doSingleBooleanOperation(_ args:Pair?, body:SingleBooleanOperationBody) -> LispType {
        var result: Bool = false
        var p: Pair? = checkArgs(args, env: env)
        
        if p != nil {
            switch p!.value {
            case .lBoolean(let b):
                result = body(b)
                break
                
            default:
                print("Invalid argument: \(p!.value)")
                return LispType.nil
            }
            
            p = p?.next
        }
        
        return LispType.lBoolean(result)
    }
    
    func initBuiltins() {
        addBuiltin("+") { args in
            return self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x + y
            }
        }
        
        addBuiltin("-") { args in
            return self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x - y
            }
        }
        
        addBuiltin("*") { args in
            return self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x * y
            }
        }
        
        addBuiltin("/") { args in
            return self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x / y
            }
        }
        
        addBuiltin(">") { args in
            return self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x > y
            }
        }
        
        addBuiltin("<") { args in
            return self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x < y
            }
        }
        
        addBuiltin("==") { args in
            return self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x == y
            }
        }
        
        addBuiltin("and") { args in
            return self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x && y
            }
        }
        
        addBuiltin("or") { args in
            return self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x || y
            }
        }
        
        addBuiltin("not") { args in
            return self.doSingleBooleanOperation(args) { (x: Bool) -> Bool in
                return !x
            }
        }
        
        addBuiltin("sqrt") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count != 1 {
                print("sqrt requires 1 argument.")
                return LispType.nil
            }
            
            for (index, arg) in argList.enumerated() {
                if !valueIsNumber(arg) {
                    print("Argument to sqrt at position \(index) is not a number.")
                    return LispType.nil
                }
            }
            
            let x = numberFromValue(argList[0])
            return LispType.number(sqrt(x))
        }
    }
}
