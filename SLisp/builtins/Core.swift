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
            try env.evaluateFile(path)
        } catch {
            print("Core library implementation not found!")
        }
    }
    
    func evaluateOrReturnResult(_ val: LispType) -> LispType
    {
        var rv: LispType
        
        switch val {
            
        case .atom(let a):
            if let r = self.env.getVariable(a) {
                rv = r
            } else {
                rv = val
            }
            break
            
        case .lPair(let p):
            rv = self.env.evaluate(copyList(p))
            break
            
        default:
            rv = val
        }
        
        return rv
    }
    
    func initBuiltins() -> [String: BuiltinBody] {
        addBuiltin("def") { args in
            if args != nil && valueIsAtom(args!.value) {
                let name = stringFromValue(args!.value)
                
                if args?.next != nil {
                    if valueIsPair(args!.next!.value) {
                        let p = pairFromValue(args!.next!.value)
                        self.env.addVariable(name!, value: self.env.evaluate(p!))
                    } else {
                        self.env.addVariable(name!, value: args!.next!.value)
                    }
                    
                }
            }
            return LispType.nil
        }

        addBuiltin("list") { args in
            if args != nil {
                return LispType.lPair(checkArgs(args!, env:self.env))
            }
            
            let p = Pair()
            p.value = LispType.nil
            return LispType.nil
        }
        
        addBuiltin("cons") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count < 2 {
                print("cons requires 2 arguments")
                return LispType.nil
            }
            
            if !valueIsPair(argList[1]) && !valueIsNil(argList[1]) {
                print("cons requires the second argument to be a list or nil")
                return LispType.nil
            }
            
            let p = Pair()
            p.value = argList[0]
            
            if !valueIsNil(argList[1]) {
                p.next = pairFromValue(argList[1])
            }
            
            return LispType.lPair(p)
        }
        
        addBuiltin("first") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count < 1 {
                print("first requires an argument")
                return LispType.nil
            }
            
            if !valueIsPair(argList[0]) {
                print("first requires an argument that is a list")
                return LispType.nil
            }
            
            return pairFromValue(argList[0])!.value
        }

        addBuiltin("rest") { args in
            let argList = getArgList(args, env: self.env)

            if argList.count < 1 {
                print("rest requires an argument")
                return LispType.nil
            }

            if !valueIsPair(argList[0]) {
                print("rest requires an argument that is a list")
                return LispType.nil
            }

            var p = pairFromValue(argList[0])

            p = p!.next

            if p != nil {
                return LispType.lPair(p!)
            }

            return LispType.nil
        }
        
        addBuiltin("last") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count < 1 {
                print("last requires an argument")
                return LispType.nil
            }
            
            if !valueIsPair(argList[0]) {
                print("last requires an argument that is a list")
                return LispType.nil
            }
            
            var p = pairFromValue(argList[0])
            
            while true {
                if p!.next == nil {
                    break
                }
                
                p = p!.next
            }
            
            return p!.value
        }
        
        addBuiltin("function") { args in
            if args != nil && valueIsPair(args!.value) {
                
                // Check arguments
                if valueIsPair(args!.value) {
                    var arg:Pair? = pairFromValue(args!.value)
                    
                    var arguments = [String]()
                    if !valueIsNil(arg!.value) {
                        while arg != nil {
                            if valueIsAtom(arg!.value) {
                                arguments.append(stringFromValue(arg!.value)!)
                            } else {
                                return LispType.nil
                            }
                            
                            arg = arg!.next
                        }
                    }
                    
                    // Extract function body
                    if let functionBody = args!.next {
                        let f = LFunctionMetadata(argNames: arguments, body: functionBody)
                        return LispType.lFunction(f)
                    }
                    
                }
            }
            
            return LispType.nil
        }
        
        addBuiltin("cond") { args in
            let condition: LispType = args!.value
            
            let result = self.evaluateOrReturnResult(condition)
            
            if !valueIsBoolean(result) {
                print("cond requires the first argument to be a boolean.")
                return LispType.nil
            }
            
            // Get execution paths.
            
            var truePath:Pair?
            var falsePath:Pair?
            
            truePath = args!.next
            
            if truePath == nil {
                print("cond requires a true path.")
                return LispType.nil
            }
            
            falsePath = truePath!.next
            
            if falsePath == nil {
                print("cond requires a false path.")
                return LispType.nil
            }
            
            if booleanFromValue(result) {
                return self.evaluateOrReturnResult(truePath!.value)
            } else {
                return self.evaluateOrReturnResult(falsePath!.value)
            }
        }
        
        addBuiltin("while") { args in
            var body:Pair?
            body = args!.next
            
            if body == nil {
                print("while requires a body.")
                return LispType.nil
            }
            
            let condition = args!.value
            
            let getResult: ()->Bool = {
                let result = self.evaluateOrReturnResult(condition)
                if !valueIsBoolean(result) {
                    print("while requires the first argument to be a boolean.")
                    return false
                }
                return booleanFromValue(result)
            }
            
            var rv = LispType.nil
            while(getResult()) {
                rv = self.evaluateOrReturnResult(body!.value)
            }
            
            return rv
        }
        
        addBuiltin("print") { args in
            var p: Pair? = checkArgs(args, env: self.env)
            var output = [String]()
            
            while p != nil {
                output.append(lispTypeToString(p!.value, env: self.env))
                
                p = p!.next
            }
            
            print(output.joined(separator: ""))
            
            return LispType.nil
        }

        addBuiltin("list?") { args in
            let argList = getArgList(args, env: self.env)

            if argList.count != 1 {
                print("list? requires one argument")
                return LispType.nil
            }

            if valueIsPair(argList[0]) {
                return LispType.lBoolean(true)
            }

            return LispType.lBoolean(false)
        }

        addBuiltin("atom?") { args in
            let argList = getArgList(args, env: self.env)

            if argList.count != 1 {
                print("atom? requires one argument")
                return LispType.nil
            }

            if valueIsAtom(argList[0]) {
                return LispType.lBoolean(true)
            }

            return LispType.lBoolean(false)
        }

        addBuiltin("string?") { args in
            let argList = getArgList(args, env: self.env)

            if argList.count != 1 {
                print("string? requires one argument")
                return LispType.nil
            }

            if valueIsString(argList[0]) {
                return LispType.lBoolean(true)
            }

            return LispType.lBoolean(false)
        }

        addBuiltin("number?") { args in
            let argList = getArgList(args, env: self.env)

            if argList.count != 1 {
                print("number? requires one argument")
                return LispType.nil
            }

            if valueIsNumber(argList[0]) {
                return LispType.lBoolean(true)
            }

            return LispType.lBoolean(false)
        }

        addBuiltin("function?") { args in
            let argList = getArgList(args, env: self.env)

            if argList.count != 1 {
                print("function? requires one argument")
                return LispType.nil
            }

            if valueIsFunction(argList[0]) {
                return LispType.lBoolean(true)
            }

            return LispType.lBoolean(false)
        }
        
        addBuiltin("let") { args in
            
            if(args == nil) {
                print("let requires 2 arguments")
                return LispType.nil
            }
            
            if(!valueIsPair(args!.value)) {
                print("let requires the first argument to be a list")
                return LispType.nil
            }
            
            if(args!.next == nil) {
                print("let requires a body")
                return LispType.nil
            }
            
            var pairArgs = [LispType]()
            var p: Pair? = pairFromValue(args!.value)
            
            while(p != nil) {
                pairArgs.append(p!.value)
                p = p!.next
            }
            
            if(pairArgs.count % 2 != 0) {
                print("let requires an even number of values")
                return LispType.nil
            }
            
            // Iterate through the pairs and put them into a dictionary, so they can be added to the environment stack
            self.env.pushEnvironment([String: LispType]())
            
            for startIdx in stride(from:0, to: pairArgs.count, by: 2) {
                let key = pairArgs[startIdx]
                
                if(!valueIsAtom(key)) {
                    print("let: value \(stringFromValue(key)) is not an atom")
                    return LispType.nil
                }
                
                // Add the values to the local environment after evaluating them
                self.env.addLocalVariable(stringFromValue(key)!, value: self.evaluateOrReturnResult(pairArgs[startIdx + 1]))
            }
            
            let body: Pair? =  args!.next!
            var pair = body
            var rv = LispType.nil
            
            // Evaluate all of the expressions in the body
            while pair != nil {
                rv = self.evaluateOrReturnResult(pair!.value)
                pair = pair!.next
            }
            
            self.env.popEnvironment()
            
            return rv
        }
        
        addBuiltin("do") { args in
            var pair = args
            var rv = LispType.nil
            
            // Evaluate all of the expressions in the body
            while pair != nil {
                rv = self.evaluateOrReturnResult(pair!.value)
                pair = pair!.next
            }
            
            return rv
        }
        
        addBuiltin("nil?") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count != 1 {
                print("nil? requires one argument")
                return LispType.nil
            }
            
            if valueIsNil(argList[0]) {
                return LispType.lBoolean(true)
            }
            
            return LispType.lBoolean(false)
        }
        
        /* Get input from stdin */
        addBuiltin("input") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count > 0 {
                if valueIsString(argList[0]) {
                    let prompt = stringFromValue(argList[0])
                    print(prompt!, terminator: "")
                } else {
                    print("Input requires the first argument to be a string")
                    return LispType.nil
                }
            }
            
            let keyboard = FileHandle.standardInput()
            let inputData = keyboard.availableData
            let input = NSString(data: inputData, encoding: String.Encoding.utf8.rawValue)!
                .trimmingCharacters(in: CharacterSet.newlines)
            return LispType.lString(input as String)
        }
        
        addBuiltin("string=") { args in
            var result: Bool = false
            var lastValue: String = ""
            var firstArg = true
            var p: Pair? = checkArgs(args, env: self.env)
            
            while p != nil {
                switch p!.value {
                case .lString(let s):
                    if firstArg {
                        lastValue = s
                        firstArg = false
                    } else {
                        result = s == lastValue
                        lastValue = s
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
        
        addBuiltin("at") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count != 2 {
                print("at requires 2 arguments")
                return LispType.nil
            }
            
            if !valueIsPair(argList[0]) {
                print("at requires the first argument to be a list")
                return LispType.nil
            }
            
            if !valueIsNumber(argList[1]) {
                print("at requires the second argument to be a number")
                return LispType.nil
            }
            
            let list = pairFromValue(argList[0])
            let index = Int(numberFromValue(argList[1]))
            var count = 0
            
            var p: Pair? = list
            
            while count < index && p != nil {
                count += 1
                p = p!.next
            }
            
            if p == nil {
                print("Index '\(index)' is out of range")
                return LispType.nil
            }
            
            return p!.value
        }
        
        return builtins
    }
}
