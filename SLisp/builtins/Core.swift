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
    
    func loadImplementation() {
        // Load core library implemented in SLisp
        do {
            let path = "./data/core.sl"
            try env.evaluateFile(path: path)
        } catch {
            print("Core library implementation not found!")
        }
    }
    
    func evaluateOrReturnResult(val: LispType) -> LispType
    {
        var rv: LispType
        
        switch val {
            
        case .Atom(let a):
            if let r = self.env.getVariable(name: a) {
                rv = r
            } else {
                rv = val
            }
            break
            
        case .LPair(let p):
            rv = self.env.evaluate(p: p)
            break
            
        default:
            rv = val
        }
        
        return rv
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
            
            return pairFromValue(val: argList[0])!.value
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
            
            return p!.value
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
            
            
            
            let result = self.evaluateOrReturnResult(val: condition)
            
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
                return self.evaluateOrReturnResult(val: truePath!.value)
            } else {
                return self.evaluateOrReturnResult(val: falsePath!.value)
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
        
        addBuiltin(name: "let") { args in
            
            if(args == nil) {
                print("let requires 2 arguments")
                return LispType.Nil
            }
            
            if(!valueIsPair(val: args!.value)) {
                print("let requires the first argument to be a list")
                return LispType.Nil
            }
            
            if(args!.next == nil) {
                print("let requires a body")
                return LispType.Nil
            }
            
            var pairArgs = [LispType]()
            var p: Pair? = pairFromValue(val: args!.value)
            
            while(p != nil) {
                pairArgs.append(p!.value)
                p = p!.next
            }
            
            if(pairArgs.count % 2 != 0) {
                print("let requires an even number of values")
                return LispType.Nil
            }
            
            // Iterate through the pairs and put them into a dictionary, so they can be added to the environment stack
            var env = [String: LispType]()
            
            for startIdx in stride(from:0, to: pairArgs.count, by: 2) {
                let key = pairArgs[startIdx]
                
                if(!valueIsAtom(val: key)) {
                    print("let: value \(stringFromValue(val: key)) is not an atom")
                    return LispType.Nil
                }
                
                // Add the values to the local environment after evaluating them
                env[stringFromValue(val: key)!] = self.evaluateOrReturnResult(val: pairArgs[startIdx + 1])
            }
            
            self.env.pushEnvironment(environment: env)
            
            let body: Pair? =  args!.next!
            var pair = body
            var rv = LispType.Nil
            
            // Evaluate all of the expressions in the body
            while pair != nil {
                rv = self.evaluateOrReturnResult(val: pair!.value)
                pair = pair!.next
            }
            
            self.env.popEnvironment()
            
            return rv
        }
        
        addBuiltin(name: "nil?") { args in
            let argList = getArgList(args: args, env: self.env)
            
            if argList.count != 1 {
                print("nil? requires one argument")
                return LispType.Nil
            }
            
            if valueIsNil(val: argList[0]) {
                return LispType.LBoolean(true)
            }
            
            return LispType.LBoolean(false)
        }
        
        return builtins
    }
}