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

typealias ArithmeticOperationBody = (Float, Float) -> Float
typealias ArithmeticBooleanOperationBody = (Float, Float) -> Bool

class MathBuiltins : Builtins {
    
    override init(env:Environment) {
        super.init(env: env)
        self.initBuiltins()
    }
    
    // A generic function for arithmetic operations
    func doArithmeticOperation(args:Pair?, body:ArithmeticOperationBody) -> LispType {
        var x: Float = 0.0
        var firstArg = true
        var p: Pair? = checkArgs(args: args, env: env)
        
        while p != nil {
            switch p!.value {
            case .Number(let num):
                if firstArg {
                    x = num
                    firstArg = false
                } else {
                    x = body(x, num)
                }
                break
                
            default:
                print("Invalid argument: \(p!.value)")
                return LispType.Nil
            }
            
            p = p?.next
        }
        
        return LispType.Number(x)
    }
    
    func doBooleanArithmeticOperation(args:Pair?, body:ArithmeticBooleanOperationBody) -> LispType {
        var result: Bool = false
        var lastValue: Float = 0.0
        var firstArg = true
        var p: Pair? = checkArgs(args: args, env: env)
        
        while p != nil {
            switch p!.value {
            case .Number(let num):
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
                return LispType.Nil
            }
            
            p = p?.next
        }
        
        return LispType.LBoolean(result)
    }
    
    func initBuiltins() {
        addBuiltin(name: "+") { args in
            return self.doArithmeticOperation(args: args) { (x: Float, y: Float) -> Float in
                return x + y
            }
        }
        
        addBuiltin(name: "-") { args in
            return self.doArithmeticOperation(args: args) { (x: Float, y: Float) -> Float in
                print("\(x) - \(y)")
                return x - y
            }
        }
        
        addBuiltin(name: "*") { args in
            return self.doArithmeticOperation(args: args) { (x: Float, y: Float) -> Float in
                return x * y
            }
        }
        
        addBuiltin(name: "/") { args in
            return self.doArithmeticOperation(args: args) { (x: Float, y: Float) -> Float in
                return x / y
            }
        }
        
        addBuiltin(name: ">") { args in
            return self.doBooleanArithmeticOperation(args: args) { (x: Float, y: Float) -> Bool in
                return x > y
            }
        }
        
        addBuiltin(name: "<") { args in
            return self.doBooleanArithmeticOperation(args: args) { (x: Float, y: Float) -> Bool in
                return x < y
            }
        }
        
        addBuiltin(name: "==") { args in
            return self.doBooleanArithmeticOperation(args: args) { (x: Float, y: Float) -> Bool in
                print("\(x) == \(y)")
                return x == y
            }
        }
        
        addBuiltin(name: "sqrt") { args in
            let argList = getArgList(args: args, env: self.env)
            
            if argList.count != 1 {
                print("sqrt requires 1 argument.")
                return LispType.Nil
            }
            
            for (index, arg) in argList.enumerated() {
                if !valueIsNumber(val: arg) {
                    print("Argument to sqrt at position \(index) is not a number.")
                    return LispType.Nil
                }
            }
            
            let x = numberFromValue(val: argList[0])
            return LispType.Number(sqrtf(x))
        }
    }
}