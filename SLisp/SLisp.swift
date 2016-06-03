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
    var value: LispType = LispType.Nil
    var next: Pair? = nil
    
    var description : String {
        var val = ""
        
        switch value {
        case .Nil:
            val = "NIL"
            break
            
        case .Atom(let a):
            val = "\(a)"
            break
            
        case .Number(let n):
            val = "\(n)"
            break
            
        case .LString(let s):
            val = "\"\(s)\""
            break
            
        case .LPair(let p):
            val = "( \(p)"
            break
        
        case .LFunction(let metadata):
            val = "Function:\(metadata.argNames)"
            break

        case .LBoolean(let b):
            val = "\(b)"
            break
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

enum LispType {
    case Nil
    case LPair(Pair)
    case LString(String)
    case Number(Double)
    case Atom(String)
    case LFunction(LFunctionMetadata)
    case LBoolean(Bool)
}

enum EnvironmentErrors : ErrorProtocol {
    case FileNotFoundError(String)
}

class Environment {
    var env: Dictionary<String, LispType> = [:]
    var envStack: [Dictionary<String, LispType>] = []
    
    var builtins = [String:BuiltinBody]()
    
    init() {
        builtins = getBuiltins(env: self)
    }

    func evaluateFile(path:String) throws {
        do {
            let fileContents = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            let tokens = getTokens(source: fileContents as String)
            parseTokenList(tokens: tokens)
        } catch {
            throw EnvironmentErrors.FileNotFoundError(path)
        }
    }

    func evaluateString(str:String) {
        let tokens = getTokens(source: str)
        parseTokenList(tokens: tokens)
    }

    func getTokens(source:String) -> [TokenType] {
        let tokenizer = Tokenizer(source: source)
        let tokens = tokenizer.tokenizeInput()
        return tokens
    }

    func parseTokenList(tokens:[TokenType]) {
        let rootPairs = self.parseTokens(tokens: tokens)

        for p in rootPairs {
            let _ = self.evaluate(p: p)
        }
    }
    
    func parseTokens(tokens: [TokenType]) -> [Pair] {
        var output = [Pair]()
        
        var rootPair: Pair? = nil
        var currentTail: Pair? = nil
        var pairStack: [Pair] = []

        
        for token in tokens {
            switch token {
                
            case .LParen:
                if rootPair == nil {
                    rootPair = Pair()
                    currentTail = rootPair
                } else {
                    currentTail = appendIfNotNil(p: currentTail!)
                    
                    let p = Pair()
                    currentTail!.value = LispType.LPair(p)
                    pairStack.append(currentTail!)
                    currentTail = p
                }
                break
                
            case .RParen:
                if pairStack.count == 0 {
                    output.append(rootPair!)
                    rootPair = nil
                    currentTail = nil
                } else {
                    currentTail = pairStack.popLast()
                }
                break
                
            case .Atom(let atomString):
                currentTail = appendIfNotNil(p: currentTail!)
                
                if currentTail == nil {
                    print("Fatal parsing error, tried to insert atom outside of list")
                    return []
                } else {
                    currentTail!.value = LispType.Atom(atomString)
                }
                break
                
            case .Number(let num):
                currentTail = appendIfNotNil(p: currentTail!)
                
                if currentTail == nil {
                    print("Fatal parsing error, tried to insert number outside of list")
                    return []
                } else {
                    currentTail!.value = LispType.Number(num)
                }
                break
                
            case .LString(let str):
                currentTail = appendIfNotNil(p: currentTail!)
                
                if currentTail == nil {
                    print("Fatal parsing error, tried to insert string outside of list")
                    return []
                } else {
                    currentTail!.value = LispType.LString(str)
                }
                break
            }
            
        }
        
        return output
    }
    
    func appendIfNotNil(p: Pair) -> Pair {
        if pairIsNil(p: p) {
            return p
        }
        
        return appendPair(p: p)
    }
    
    func appendPair(p: Pair) -> Pair {
        let newPair = Pair()
        p.next = newPair
        return newPair
    }
    
    func pairIsNil(p: Pair) -> Bool {
        switch(p.value) {
        case .Nil: return true
        default: return false
        }
    }
    
    func evaluate(p: Pair) -> LispType {
        switch p.value {
        case .Atom(let a):
            // Check if atom exists in builtins
            
            if let builtin = self.builtins[a] {
                return builtin(p.next)
            } else if let variable = getVariable(name: a) {
                switch variable {
                case .LFunction(let f):
                    return callFunction(function: f, arguments:p.next)
                    
                default:
                    return variable
                }
            }
            
            return p.value
            
        default:
            break
        }
        
        return p.value
    }
    
    func addVariable(name: String, value: LispType) {
        env[name] = value
    }
    
    func getVariable(name: String) -> LispType? {
        if name == "true" {
            return LispType.LBoolean(true)
        }

        if name == "false" {
            return LispType.LBoolean(false)
        }

        // Check the environment stack first, since these hold function arguments
        for e in envStack.reversed() {
            if let v = e[name] {
                return v
            }
        }
        
        return env[name]
    }
    
    func pushEnvironment(environment:Dictionary<String, LispType>){
        envStack.append(environment)
    }
    
    func popEnvironment() {
        let _ = envStack.popLast()
    }
    
    func callFunction(function:LFunctionMetadata, arguments:Pair?) -> LispType {
        var arg = arguments
        
        var args = [LispType]()
        
        while arg != nil {
            if(valueIsPair(val: arg!.value)) {
                args.append(evaluate(p: pairFromValue(val: arg!.value)!))
            } else {
                if(valueIsAtom(val: arg!.value)){
                    let a = stringFromValue(val: arg!.value)
                    let v = getVariable(name: a!)
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
            return LispType.Nil
        }
        
        var newEnv: [String: LispType] = [:]
        
        for (index, argname) in function.argNames.enumerated()
        {
            newEnv[argname] = args[index]
        }

        pushEnvironment(environment: newEnv)
       
        var result = LispType.Nil
        
        // A function body should be a list.
        if let body = pairFromValue(val: function.body.value) {
            let bodyCopy = copyList(p: body)
            
            result = evaluate(p: bodyCopy)
        } else {
            print("Error, function body was not a list.")
        }
        
        popEnvironment()
        
        return result
    }
}