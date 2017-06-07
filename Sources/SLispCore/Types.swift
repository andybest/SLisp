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

typealias lFloat = Double

typealias BuiltinBody = ([LispType], Environment) throws -> LispType

indirect enum FunctionBody {
    case native(body: BuiltinBody)
    case lisp(argnames: [String], body: [LispType])
}

struct TCOInvocation {
    let function: FunctionBody
    let args:     [LispType]
}

enum LispType: CustomStringConvertible {
    case list([LispType])
    case symbol(String)
    case float(lFloat)
    case `string`(String)
    case boolean(Bool)
    case `nil`
    case function(FunctionBody)
    case tcoInvocation(TCOInvocation)
    case key(String)

    var description: String {
        switch self {
            case .symbol(let str):
                return str
            case .boolean(let bool):
                return String(bool)
            case .float(let f):
                return String(f)
            case .nil:
                return "nil"
            case .string(let str):
                return "\"\(str)\""
            case .list(let list):
                let elements = list.map {
                    String(describing: $0)
                }.joined(separator: " ")
                return "(\(elements))"
            case .function(_):
                return "#<function>"
            case .tcoInvocation(_):
                return "#<TCOInvocation>"
            case .key(let key):
            return ":\(key)"
        }
    }
}