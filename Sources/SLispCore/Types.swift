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

typealias BuiltinBody = ([LispType], Environment) throws -> LispType

indirect enum FunctionBody {
    case native(body: BuiltinBody)
    case lisp(argnames: [String], body: [LispType])
}

enum LispType: CustomStringConvertible, Equatable {
    case list([LispType])
    case symbol(String)
    case number(LispNumber)
    case `string`(String)
    case boolean(Bool)
    case `nil`
    case function(FunctionBody)
    case key(String)

    var description: String {
        switch self {
            case .symbol(let str):
                return str
            case .boolean(let bool):
                return String(bool)
            case .number(let n):
                return String(describing: n)
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
            case .key(let key):
            return ":\(key)"
        }
    }
}

func ==(a: LispType, b: LispType) -> Bool {
    switch (a, b) {
    case (.list(let a), .list(let b)) where a == b: return true
    case (.symbol(let a), .symbol(let b)) where a == b: return true
    case (.number(let a), .number(let b)) where a == b: return true
    case (.string(let a), .string(let b)) where a == b: return true
    case (.boolean(let a), .boolean(let b)) where a == b: return true
    case (.key(let a), .key(let b)) where a == b: return true
    default: return false
    }
}

enum LispNumber: CustomStringConvertible {
    case float(Double)
    case integer(Int)
    
    var description: String {
        switch self {
        case .float(let n): return String(n)
        case .integer(let n): return String(n)
        }
    }
    
    enum PromotionResult {
        case float(Double, Double)
        case integer(Int, Int)
    }
    
    var isFloat: Bool {
        if case .float(_) = self {
            return true
        }
        return false
    }
    
    var isInteger: Bool {
        if case .integer(_) = self {
            return true
        }
        return false
    }
}

extension LispNumber {
    func floatValue() -> Double {
        switch self {
        case .float(let n): return n
        case .integer(let n): return Double(n)
        }
    }
    
    func intValue() -> Int {
        switch self {
        case .float(let n): return Int(n)
        case .integer(let n): return n
        }
    }
}

extension LispNumber {
    static func promoteIfNecessary(_ lhs: LispNumber, _ rhs: LispNumber) -> PromotionResult {
        switch lhs {
        case .float(let l):
            switch rhs {
            case .integer(let r): return .float(l, Double(r))
            case .float(let r): return .float(l, r)
            }
        case .integer(let l):
            switch rhs {
            case .integer(let r): return .integer(l, r)
            case .float(let r): return .float(Double(l), r)
            }
        }
    }
    
    static func ==(_ lhs: LispNumber, _ rhs: LispNumber) -> Bool {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return l == r
        case .integer(let l, let r): return l == r
        }
    }
    
    static func add(_ lhs: LispNumber, _ rhs: LispNumber) -> LispNumber {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return .float(l + r)
        case .integer(let l, let r): return .integer(l.addingReportingOverflow(r).partialValue)
        }
    }
    
    static func subtract(_ lhs: LispNumber, _ rhs: LispNumber) -> LispNumber {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return .float(l - r)
        case .integer(let l, let r): return .integer(l.subtractingReportingOverflow(r).partialValue)
        }
    }
    
    static func multiply(_ lhs: LispNumber, _ rhs: LispNumber) -> LispNumber {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return .float(l * r)
        case .integer(let l, let r): return .integer(l.multipliedReportingOverflow(by: r).partialValue)
        }
    }
    
    static func divide(_ lhs: LispNumber, _ rhs: LispNumber) -> LispNumber {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return .float(l / r)
        case .integer(let l, let r): return .integer(l.dividedReportingOverflow(by:r).partialValue)
        }
    }
    
    static func mod(_ lhs: LispNumber, _ rhs: LispNumber) -> LispNumber {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return .float(l.truncatingRemainder(dividingBy: r) )
        case .integer(let l, let r): return .integer(l % r)
        }
    }
    
    static func lessThan(_ lhs: LispNumber, _ rhs: LispNumber) -> Bool {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return l < r
        case .integer(let l, let r): return l < r
        }
    }
    
    static func greaterThan(_ lhs: LispNumber, _ rhs: LispNumber) -> Bool {
        switch promoteIfNecessary(lhs, rhs) {
        case .float(let l, let r): return l > r
        case .integer(let l, let r): return l > r
        }
    }
}

