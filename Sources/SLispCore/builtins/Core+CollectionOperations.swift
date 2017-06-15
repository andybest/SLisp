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
        """) { args, env throws in
            return .list(args)
        }
        
        
        // MARK: cons
        addBuiltin("cons", docstring: """
        cons
        (i l)
            Constructs a new list where i is the first element, and l is the rest
        """) { args, env throws in
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
        """) { args, env throws in
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
        """) { args, env throws in
            try self.checkArgCount(funcName: "first", args: args, expectedNumArgs: 1)
            
            if case let .list(list) = args[0] {
                return list.first ?? .nil
            }
            
            throw LispError.general(msg: "'first' expects an argument that is a list")
        }
        
        
        // MARK: rest
        addBuiltin("rest", docstring: """
        rest
        (x)
            Returns all but the first item in the collection x
        """) { args, env throws in
            try self.checkArgCount(funcName: "rest", args: args, expectedNumArgs: 1)
            
            if case let .list(list) = args[0] {
                return .list(Array(list.dropFirst(1)))
            }
            
            throw LispError.general(msg: "'rest' expects an argument that is a list")
        }
        
        
        // MARK: last
        addBuiltin("last", docstring: """
        last
        (x)
            Returns the last item in the collection x
        """) { args, env throws in
            try self.checkArgCount(funcName: "last", args: args, expectedNumArgs: 1)
            
            if case let .list(list) = args[0] {
                return list.last ?? .nil
            }
            
            throw LispError.general(msg: "'last' expects an argument that is a list")
        }
        
        
        // MARK: at
        addBuiltin("at", docstring: """
        at
        (x i)
            Returns the item at index i from collection x
        """) { args, env in
            if args.count != 2 {
                throw LispError.runtime(msg: "'at' requires 2 arguments.")
            }
            
            guard case let .list(list) = args[0] else {
                throw LispError.runtime(msg: "'at' requires the first argument to be a list.")
            }
            
            guard case let .number(num) = args[1], case let .integer(index) = num else {
                throw LispError.runtime(msg: "'at' requires the second argument to be an integer.")
            }
            
            if index >= list.count || index < 0 {
                throw LispError.runtime(msg: "Index out of range: \(index)")
            }
            
            return list[index]
        }
        
        addBuiltin("count", docstring: """
        count
        (x)
            Returns the count/length of the collection or string x
        """) { args, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'count' expects 1 argument")
            }
            
            for arg in args {
                if case .list(let l) = arg {
                    return .number(.integer(l.count))
                } else if case .string(let s) = arg {
                    return .number(.integer(s.count))
                }
            }
            
            throw LispError.runtime(msg: "'count' expects an argument that is a list or a string")
        }
        
        addBuiltin("empty?", docstring: """
        empty?
        (x)
            Returns a boolean indicating whether the string/collection is empty
        """) { args, env throws in
            try self.checkArgCount(funcName: "empty?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                if case .list(let l) = arg {
                    return .boolean(l.count == 0)
                } else if case .string(let s) = arg {
                    return .boolean(s.count == 0)
                }
            }
            
            return .boolean(false)
        }
    }
}
