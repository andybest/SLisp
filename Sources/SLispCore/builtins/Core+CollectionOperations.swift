/*
 
 MIT License
 
 Copyright (c) 2017 Andy Best
 
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

extension Core {
    func initCoreCollectionBuiltins() {
        
        // MARK: list
        addBuiltin("list", docstring: """
        list
        (items)
            Constructs a new list containing the items
        """) { args, parser, env throws in
            return .list(args)
        }
        
        
        // MARK: hash-map
        addBuiltin("hash-map", docstring: """
        hash-map
        (key value ...)
            Constructs a new dictionary with the given key/value pairs
        """) { args, parser, env in
            if args.count == 0 {
                return .dictionary([:])
            }
            
            if args.count % 2 != 0 {
                throw LispError.runtime(msg: "No value supplied for key \(args.last!)")
            }
            
            var dict = Dictionary<LispType, LispType>(minimumCapacity: args.count / 2)
            
            for i in stride(from: 0, to: args.count, by: 2) {
                let key = args[i]
                let value = args[i + 1]
                
                if value == .nil {
                    dict[key] = nil
                    continue
                }
                
                if !key.canBeKey {
                    throw LispError.runtime(msg: "Type \(key.typeName) with value \(String(describing: key)) cannot be a key in a dictionary.")
                }
                
                dict[key] = value
            }
            
            return .dictionary(dict)
        }
        
        
        // MARK: assoc
        addBuiltin("assoc", docstring: """
        assoc
        (dict key value key2 value2 ...) or (list index value ...)
        Associate value(s) with key(s) in dictionary or replace index in list with provided value
        """) { args, parser, env in
            if args.count < 3 {
                throw LispError.runtime(msg: "'assoc' requires at least 3 arguments")
            }
            
            if args.count % 2 != 1 {
                throw LispError.runtime(msg: "'assoc': key \(String(describing: args.last!)) has no corresponding value")
            }
            
            if case let .dictionary(dict) = args[0] {
                var retDict = dict
                
                for i in stride(from: 1, to: args.count, by: 2) {
                    let key = args[i]
                    let value = args[i + 1]
                    
                    if !key.canBeKey {
                        throw LispError.runtime(msg: "Type \(key.typeName) with value \(String(describing: key)) cannot be a key in a dictionary.")
                    }
                    
                    if value == .nil {
                        retDict[key] = nil
                        continue
                    }
                    
                    retDict[key] = value
                }
                
                return .dictionary(retDict)
            } else if case let .list(list) = args[0] {
                var retList = list
                
                for i in stride(from: 1, to: args.count, by: 2) {
                    guard case let .number(.integer(index)) = args[i] else {
                        throw LispError.runtime(msg: "'assoc', when used with a list, expects indicies to be integers.")
                    }
                    
                    let value = args[i + 1]
                    retList[index] = value
                }
                
                return .list(retList)
            }
            
            throw LispError.runtime(msg: "'assoc' requires the first argument to be a dictionary")
        }
        
        
        // MARK: cons
        addBuiltin("cons", docstring: """
        cons
        (i l)
            Constructs a new list where i is the first element, and l is the rest
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "cons", args: args, expectedNumArgs: 2)
            
            var secondValue: [LispType] = []
            
            switch args[1] {
            case .list(let listVal):
                secondValue = listVal
                break
            case .nil:
                break
            default:
                throw LispError.general(msg: "'cons' requires the second argument to be a list or 'nil'")
            }
            
            secondValue.insert(args[0], at: 0)
            
            return .list(secondValue)
        }
        
        
        // MARK: concat
        addBuiltin("concat", docstring: """
        concat
        (x y)
            Concatenates 2 lists
        """) { args, parser, env throws in
            let transformed: [LispType] = args.flatMap { input -> [LispType] in
                if case let .list(list) = input {
                    return list
                }
                return [input]
            }
            
            return .list(transformed)
        }
        
        
        // MARK: first
        addBuiltin("first", docstring: """
        first
        (x)
            Returns the first item in the collection x
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "first", args: args, expectedNumArgs: 1)
            
            if case let .list(list) = args[0] {
                return list.first ?? .nil
            } else if case let .string(str) = args[0] {
                let f = str.characters.first
                return f != nil ? .string(String(f!)) : .nil
            } else if case let .dictionary(dict) = args[0] {
                if dict.count == 0 {
                    return .nil
                }
                
                let pair = dict[dict.startIndex]
                return .list([pair.key, pair.value])
            }
            
            throw LispError.general(msg: "'first' expects an argument that is a list or a string")
        }
        
        
        // MARK: rest
        addBuiltin("rest", docstring: """
        rest
        (x)
            Returns all but the first item in the collection x
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "rest", args: args, expectedNumArgs: 1)
            
            if case let .list(list) = args[0] {
                return .list(Array(list.dropFirst(1)))
            } else if case let .string(str) = args[0] {
                let r = str.characters.dropFirst()
                return .string(String(r))
            } else if case let .dictionary(dict) = args[0] {
                if dict.count == 0 {
                    return .nil
                }
                
                return .list(dict.dropFirst().map { pair in
                    return .list([pair.key, pair.value])
                })
            }
            throw LispError.general(msg: "'rest' expects an argument that is a list or a string")
        }
        
        
        // MARK: last
        addBuiltin("last", docstring: """
        last
        (x)
            Returns the last item in the collection x
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "last", args: args, expectedNumArgs: 1)
            
            if case let .list(list) = args[0] {
                return list.last ?? .nil
            } else if case let .string(str) = args[0] {
                let l = str.characters.last
                return l != nil ? .string(String(l!)) : .nil
            } else if case let .dictionary(dict) = args[0] {
                if dict.count == 0 {
                    return .nil
                }
                
                let pair = dict[dict.index(dict.startIndex, offsetBy: dict.count - 1)]
                return .list([pair.key, pair.value])
            }
            
            throw LispError.general(msg: "'last' expects an argument that is a list or a string")
        }
        
        
        // MARK: at
        addBuiltin("at", docstring: """
        at
        (x i)
            Returns the item at index i from collection x
        """) { args, parser, env in
            if args.count != 2 {
                throw LispError.runtime(msg: "'at' requires 2 arguments.")
            }
            
            guard case let .number(num) = args[1], case let .integer(index) = num else {
                throw LispError.runtime(msg: "'at' requires the second argument to be an integer.")
            }
            
            switch args[0] {
            case .list(let list):
                if index >= list.count || index < 0 {
                    throw LispError.runtime(msg: "Index out of range: \(index)")
                }
                return list[index]
                
            case .string(let str):
                if index >= str.characters.count || index < 0 {
                    throw LispError.runtime(msg: "Index out of range: \(index)")
                }
                return .string(String(str.characters[str.index(str.startIndex, offsetBy: index)]))
                
            case .dictionary(let dict):
                if index >= dict.count || index < 0 {
                    throw LispError.runtime(msg: "Dictionary index out of range: \(index)")
                }
                
                let pair = dict[dict.index(dict.startIndex, offsetBy: index)]
                return .list([pair.key, pair.value])
            
            default:
                throw LispError.runtime(msg: "'at' requires the first argument to be a list or a string.")
            }
        }
        
        
        // MARK: count
        addBuiltin("count", docstring: """
        count
        (x)
            Returns the count/length of the collection or string x
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'count' expects 1 argument")
            }
            
            for arg in args {
                if case .list(let l) = arg {
                    return .number(.integer(l.count))
                } else if case .string(let s) = arg {
                    return .number(.integer(s.count))
                } else if case .dictionary(let d) = arg {
                    return .number(.integer(d.count))
                }
            }
            
            throw LispError.runtime(msg: "'count' expects an argument that is a list or a string")
        }
        
        
        // MARK: empty?
        addBuiltin("empty?", docstring: """
        empty?
        (x)
            Returns a boolean indicating whether the string/collection is empty
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "empty?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                if case .list(let l) = arg {
                    return .boolean(l.count == 0)
                } else if case .string(let s) = arg {
                    return .boolean(s.count == 0)
                } else if case .dictionary(let d) = arg {
                    return .boolean(d.count == 0)
                }
            }
            
            return .boolean(false)
        }
        
        
        // MARK: keys
        addBuiltin("keys", docstring: "") { args, parser, env in
            if args.count != 1 {
                throw LispError.runtime(msg: "'keys' expects 1 argument")
            }
            
            guard case let .dictionary(dict) = args[0] else {
                throw LispError.runtime(msg: "'keys' expects the argument to be a dictionary")
            }
            
            return .list(Array(dict.keys))
        }
        
        
        // MARK: values
        addBuiltin("values", docstring: "") { args, parser, env in
            if args.count != 1 {
                throw LispError.runtime(msg: "'values' expects 1 argument")
            }
            
            guard case let .dictionary(dict) = args[0] else {
                throw LispError.runtime(msg: "'values' expects the argument to be a dictionary")
            }
            
            return .list(Array(dict.values))
        }
    }
}
