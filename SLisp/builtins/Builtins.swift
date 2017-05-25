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

typealias BuiltinBody = (Pair?) -> LispType

extension Dictionary {
    mutating func merge(_ dict: Dictionary<Key,Value>) {
        for (key, value) in dict {
            // If both dictionaries have a value for same key, the value of the other dictionary is used.
           self[key] = value
        }
    }
}

/* Global function to get all standard built-in functions */
func getBuiltins(_ env: Environment) -> [String: BuiltinBody] {
    var builtins = [String: BuiltinBody]()
    
    let core = Core(env: env)
    let math = MathBuiltins(env: env)
    
    builtins.merge(core.getBuiltins())
    builtins.merge(math.getBuiltins())
    
    return builtins
}

/* Load library implementations that are implemented in SLisp */
func loadSLispImplemetations(_ env: Environment) {
    let core = Core(env: env)
    core.loadImplementation()
    
    let math = MathBuiltins(env:env)
    math.loadImplementation()
}

class Builtins {
    let env:Environment
    var builtins = [String : BuiltinBody]()
    
    init(env:Environment) {
        self.env = env
    }
    
    func addBuiltin(_ name: String, _ body: @escaping BuiltinBody) {
        builtins[name] = body
    }
    
    func getBuiltins() -> [String: BuiltinBody] {
        return builtins
    }

    func loadBuiltinsFromFile(_ path:String) {

    }
}

func checkArgs(_ args:Pair?, env:Environment) -> Pair {
    var p: Pair? = args
    
    // Recursively evaluate any arguments that are lists.
    while p != nil {
        switch p!.value {
        case .lPair(let argPair):
            let output = env.evaluate(argPair)
            p?.value = output
            break
            
        case .atom(let atom):
            // Check the environment for variables
            let value = env.getVariable(atom)
            
            if value != nil {
                p?.value = value!
            }
            break
            
        default:
            break
        }
        
        p = p!.next
    }
    
    return args!
}

func getArgList(_ args:Pair?, env:Environment) -> [LispType] {
    var arg = checkArgs(args, env:env) as Pair?
    
    var result = [LispType]()
    
    while arg != nil {
        result.append(arg!.value)
        arg = arg!.next
    }
    
    return result
}
