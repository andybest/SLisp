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

class Core: Builtins {
    
    override init(env: Environment) {
        super.init(env: env)
        let _ = initBuiltins()
    }
    
    func initBuiltins() -> [String: BuiltinBody] {
        addBuiltin(name: "def") { args in
            if args != nil && valueIsAtom(val: args!.value) {
                let name = stringFromValue(val: args!.value)
                
                if args?.next != nil {
                    if valueIsPair(val: args!.next!.value) {
                        let p = pairFromValue(val: args!.next!.value)
                        self.env.addVariable(name: name!, value: self.env.evaluate(p: p!))
                    } else {
                        self.env.addVariable(name: name!, value: args!.next!.value)
                    }
                    
                }
            }
            return LispType.Nil
        }

        addBuiltin(name: "list") { args in
            if args != nil {
                return LispType.LPair(args!)
            }

            return LispType.Nil
        }
        
        addBuiltin(name: "first") { args in
            let argList = getArgList(args: args, env: self.env)
            
            if argList.count < 1 {
                print("first requires an argument")
                return LispType.Nil
            }
            
            if !valueIsPair(val: argList[0]) {
                print("first requires an argument that is a list")
                return LispType.Nil
            }
            
            let p = Pair()
            p.value = pairFromValue(val: argList[0])!.value
            return LispType.LPair(p)
        }

        addBuiltin(name: "rest") { args in
            let argList = getArgList(args: args, env: self.env)

            if argList.count < 1 {
                print("rest requires an argument")
                return LispType.Nil
            }

            if !valueIsPair(val: argList[0]) {
                print("rest requires an argument that is a list")
                return LispType.Nil
            }

            var p = pairFromValue(val: argList[0])

            p = p!.next

            if p != nil {
                return LispType.LPair(p!)
            }

            return LispType.Nil
        }
        
        addBuiltin(name: "last") { args in
            let argList = getArgList(args: args, env: self.env)
            
            if argList.count < 1 {
                print("last requires an argument")
                return LispType.Nil
            }
            
            if !valueIsPair(val: argList[0]) {
                print("last requires an argument that is a list")
                return LispType.Nil
            }
            
            var p = pairFromValue(val: argList[0])
            
            while true {
                if p!.next == nil {
                    break
                }
                
                p = p!.next
            }
            
            let returnVal = Pair()
            returnVal.value = p!.value
            return LispType.LPair(returnVal)
        }
        
        addBuiltin(name: "function") { args in
            if args != nil && valueIsPair(val: args!.value) {
                
                // Check arguments
                if valueIsPair(val: args!.value) {
                    var arg:Pair? = pairFromValue(val: args!.value)
                    
                    var arguments = [String]()
                    
                    while arg != nil {
                        if valueIsAtom(val: arg!.value) {
                            arguments.append(stringFromValue(val: arg!.value)!)
                        } else {
                            return LispType.Nil
                        }
                        
                        arg = arg!.next
                    }
                    
                    // Extract function body
                    if let functionBody = args!.next {
                        let f = LFunctionMetadata(argNames: arguments, body: functionBody)
                        return LispType.LFunction(f)
                    }
                    
                }
            }
            
            return LispType.Nil
        }
        
        addBuiltin(name: "cond") { args in
            let condition: LispType = args!.value
            
            func evaluateOrReturnResult(val: LispType) -> LispType
            {
                var rv: LispType
                switch val {
                    
                case .Atom(let a):
                    if let r = self.env.getVariable(name: a) {
                        rv = r
                    } else {
                        rv = condition
                    }
                    break
                    
                case .LPair(let p):
                    rv = self.env.evaluate(p: p)
                    break
                    
                default:
                    rv = condition
                }
                
                return rv
            }
            
            let result = evaluateOrReturnResult(val: condition)
            
            if !valueIsBoolean(val: result) {
                print("cond requires the first argument to be a boolean.")
                return LispType.Nil
            }
            
            // Get execution paths.
            
            var truePath:Pair?
            var falsePath:Pair?
            
            truePath = args!.next
            
            if truePath == nil {
                print("cond requires a true path.")
                return LispType.Nil
            }
            
            falsePath = truePath!.next
            
            if falsePath == nil {
                print("cond requires a false path.")
                return LispType.Nil
            }
            
            if booleanFromValue(val: result) {
                return evaluateOrReturnResult(val: truePath!.value)
            } else {
                return evaluateOrReturnResult(val: falsePath!.value)
            }
        }
        
        addBuiltin(name: "print") { args in
            var p: Pair? = checkArgs(args: args, env: self.env)
            var output = [String]()
            
            while p != nil {
                output.append(lispTypeToString(lt: p!.value, env: self.env))
                
                p = p!.next
            }
            
            print(output.joined(separator: " "))
            
            return LispType.Nil
        }

        addBuiltin(name: "list?") { args in
            let argList = getArgList(args: args, env: self.env)

            if argList.count != 1 {
                print("list? requires one argument")
                return LispType.Nil
            }

            if valueIsPair(val: argList[0]) {
                return LispType.LBoolean(true)
            }

            return LispType.LBoolean(false)
        }

        addBuiltin(name: "atom?") { args in
            let argList = getArgList(args: args, env: self.env)

            if argList.count != 1 {
                print("atom? requires one argument")
                return LispType.Nil
            }

            if valueIsAtom(val: argList[0]) {
                return LispType.LBoolean(true)
            }

            return LispType.LBoolean(false)
        }

        addBuiltin(name: "string?") { args in
            let argList = getArgList(args: args, env: self.env)

            if argList.count != 1 {
                print("string? requires one argument")
                return LispType.Nil
            }

            if valueIsString(val: argList[0]) {
                return LispType.LBoolean(true)
            }

            return LispType.LBoolean(false)
        }

        addBuiltin(name: "number?") { args in
            let argList = getArgList(args: args, env: self.env)

            if argList.count != 1 {
                print("number? requires one argument")
                return LispType.Nil
            }

            if valueIsNumber(val: argList[0]) {
                return LispType.LBoolean(true)
            }

            return LispType.LBoolean(false)
        }

        addBuiltin(name: "function?") { args in
            let argList = getArgList(args: args, env: self.env)

            if argList.count != 1 {
                print("function? requires one argument")
                return LispType.Nil
            }

            if valueIsFunction(val: argList[0]) {
                return LispType.LBoolean(true)
            }

            return LispType.LBoolean(false)
        }
        
        return builtins
    }
}