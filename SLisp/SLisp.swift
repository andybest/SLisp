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


class Pair : CustomStringConvertible {
    var value: LispType = LispType.nil
    var next: Pair? = nil
    
    var description : String {
        var val = ""
        
        switch value {
        case .nil:
            val = "NIL"
            
        case .atom(let a):
            val = "\(a)"
            
        case .number(let n):
            val = "\(n)"
            
        case .lString(let s):
            val = "\"\(s)\""
            
        case .lPair(let p):
            val = "( \(p)"
        
        case .lFunction(let metadata):
            val = "Function:\(metadata.argNames)"

        case .lBoolean(let b):
            val = "\(b)"
            
        case .lTCOResult(let tcoResult):
            val = "TCO(\(tcoResult))"
        }
        
        var nextVal = ")"
        
        if(next != nil) {
            nextVal = "\(next!)"
        }
        
        return "\(val) \(nextVal)"
    }
}

struct LFunctionMetadata {
    var argNames: [String]
    var body: Pair
}

indirect enum LispType {
    case `nil`
    case lPair(Pair)
    case lString(String)
    case number(Double)
    case atom(String)
    case lFunction(LFunctionMetadata)
    case lBoolean(Bool)
    case lTCOResult(LispType)
}

enum EnvironmentErrors : Error {
    case fileNotFoundError(String)
}

class Environment {
    var env: Dictionary<String, LispType> = [:]
    var envStack: [Dictionary<String, LispType>] = []
    
    var builtins = [String:BuiltinBody]()
    
    init() {
        print("Loading builtins")
        builtins = getBuiltins(self)
        print("Loading implementations")
        loadSLispImplemetations(self)
    }

    func evaluateFile(_ path:String) throws {
        do {
            let fileContents = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
            let tokens = getTokens(fileContents as String)
            print("Parsing file: \(path)")
            parseTokenList(tokens)
        } catch {
            throw EnvironmentErrors.fileNotFoundError(path)
        }
    }

    func evaluateString(_ str:String) {
        let tokens = getTokens(str)
        parseTokenList(tokens)
    }

    func getTokens(_ source:String) -> [TokenType] {
        let tokenizer = Tokenizer(source: source)
        let tokens = tokenizer.tokenizeInput()
        return tokens
    }

    func parseTokenList(_ tokens:[TokenType]) {
        let rootPairs = self.parseTokens(tokens)

        for p in rootPairs {
            let _ = self.evaluate(p)
        }
    }
    
    func parseTokens(_ tokens: [TokenType]) -> [Pair] {
        var output = [Pair]()
        
        var rootPair: Pair? = nil
        var currentTail: Pair? = nil
        var pairStack: [Pair] = []

        
        for token in tokens {
            switch token {
                
            case .lParen:
                if rootPair == nil {
                    rootPair = Pair()
                    currentTail = rootPair
                } else {
                    currentTail = appendIfNotNil(currentTail!)
                    
                    let p = Pair()
                    currentTail!.value = LispType.lPair(p)
                    pairStack.append(currentTail!)
                    currentTail = p
                }
                break
                
            case .rParen:
                if pairStack.count == 0 {
                    output.append(rootPair!)
                    rootPair = nil
                    currentTail = nil
                } else {
                    currentTail = pairStack.popLast()
                }
                break
                
            case .atom(let atomString):
                currentTail = appendIfNotNil(currentTail!)
                
                if currentTail == nil {
                    print("Fatal parsing error, tried to insert atom outside of list")
                    return []
                } else {
                    currentTail!.value = LispType.atom(atomString)
                }
                break
                
            case .number(let num):
                currentTail = appendIfNotNil(currentTail!)
                
                if currentTail == nil {
                    print("Fatal parsing error, tried to insert number outside of list")
                    return []
                } else {
                    currentTail!.value = LispType.number(num)
                }
                break
                
            case .lString(let str):
                currentTail = appendIfNotNil(currentTail!)
                
                if currentTail == nil {
                    print("Fatal parsing error, tried to insert string outside of list")
                    return []
                } else {
                    currentTail!.value = LispType.lString(str)
                }
                break
            }
            
        }
        
        return output
    }
    
    func appendIfNotNil(_ p: Pair) -> Pair {
        if pairIsNil(p) {
            return p
        }
        
        return appendPair(p)
    }
    
    func appendPair(_ p: Pair) -> Pair {
        let newPair = Pair()
        p.next = newPair
        return newPair
    }
    
    func pairIsNil(_ p: Pair) -> Bool {
        switch(p.value) {
        case .nil: return true
        default: return false
        }
    }
    
    func evaluate(_ p: Pair) -> LispType {
        var rVal:LispType? = nil
        var currentPair = p
        
        while rVal == nil || valueIsTCOResult(rVal!)
        {
            if rVal == nil {
                rVal = currentPair.value
            }
            
            switch rVal! {
            case .atom(let a):
                // Check if atom exists in builtins
                
                if let builtin = self.builtins[a] {
                    rVal = builtin(currentPair.next)
                } else if let variable = getVariable(a) {
                    switch variable {
                    case .lFunction(let f):
                        rVal = callFunction(f, arguments:currentPair.next)
                        
                    default:
                        rVal = variable
                    }
                }
                
            case .lTCOResult(let tcoResult):
                if valueIsPair(tcoResult) {
                    rVal = nil
                    currentPair = pairFromValue(tcoResult)!
                } else {
                    rVal = tcoResult
                }
            
            case .lFunction(let f):
                rVal = callFunction(f, arguments: currentPair.next)
                
            default:
                rVal = p.value
            }
        }
        return rVal!
    }
    
    func addVariable(_ name: String, value: LispType) {
        env[name] = value
    }
    
    func addLocalVariable(_ name: String, value: LispType) {
        if(envStack.count > 0) {
            self.envStack[self.envStack.count - 1][name] = value
        } else {
            self.addVariable(name, value: value)
        }
    }
    
    func getVariable(_ name: String) -> LispType? {
        if name == "true" {
            return LispType.lBoolean(true)
        }

        if name == "false" {
            return LispType.lBoolean(false)
        }
        
        if name == "nil" {
            return LispType.nil
        }

        // Check the environment stack first, since these hold function arguments
        for e in envStack.reversed() {
            if let v = e[name] {
                return v
            }
        }
        
        return env[name]
    }
    
    func pushEnvironment(_ environment:Dictionary<String, LispType>){
        envStack.append(environment)
    }
    
    func popEnvironment() {
        let _ = envStack.popLast()
    }
    
    func callFunction(_ function:LFunctionMetadata, arguments:Pair?) -> LispType {
        var arg = arguments
        
        var args = [LispType]()
        
        while arg != nil {
            if(valueIsPair(arg!.value)) {
                args.append(evaluate(pairFromValue(arg!.value)!))
            } else {
                if(valueIsAtom(arg!.value)){
                    let a = stringFromValue(arg!.value)
                    let v = getVariable(a!)
                    if(v != nil) {
                        args.append(v!)
                    } else {
                        args.append(arg!.value)
                    }
                } else {
                    args.append(arg!.value)
                }
            }
            arg = arg!.next
        }
        
        // Check that the correct number of parameters has been passed
        if args.count != function.argNames.count {
            print("Mismatching number of arguments to function- expected \(function.argNames.count), got \(args.count).")
            return LispType.nil
        }
        
        var newEnv: [String: LispType] = [:]
        
        for (index, argname) in function.argNames.enumerated()
        {
            newEnv[argname] = args[index]
        }

        pushEnvironment(newEnv)
       
        var result = LispType.nil
        
        // A function body should be a list.
        if let body = pairFromValue(function.body.value) {
            let bodyCopy = copyList(body)
            
            result = evaluate(bodyCopy)
        } else {
            print("Error, function body was not a list.")
        }
        
        popEnvironment()
        
        return result
    }
}
