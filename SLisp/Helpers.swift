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

func valueIsNil(_ val: LispType) -> Bool {
    switch val {
    case .nil:
        return true
        
    default:
        return false
    }
}


func valueIsString(_ val: LispType) -> Bool {
    switch val {
    case .lString(_):
        return true
        
    default:
        return false
    }
}

func valueIsAtom(_ val: LispType) -> Bool {
    switch val {
    case .atom(_):
        return true
        
    default:
        return false
    }
}

func valueIsPair(_ val: LispType) -> Bool {
    switch val {
    case .lPair(_):
        return true
        
    default:
        return false
    }
}

func valueIsNumber(_ val: LispType) -> Bool {
    switch val {
    case .number(_):
        return true
        
    default:
        return false
    }
}

func valueIsFunction(_ val: LispType) -> Bool {
    switch val {
    case .lFunction(_):
        return true

    default:
        return false
    }
}

func valueIsBoolean(_ val: LispType) -> Bool {
    switch val {
    case .lBoolean(_):
        return true
        
    default:
        return false
    }
}

func valueIsTCOResult(_ val: LispType) -> Bool {
    switch val {
    case .lTCOResult(_):
        return true
        
    default:
        return false
    }
}


func pairFromValue(_ val: LispType) -> Pair? {
    switch val {
    case .lPair(let p):
        return p
        
    default:
        return nil
    }
}

func numberFromValue(_ val: LispType) -> Double {
    switch val {
    case .number(let num):
        return num
        
    default:
        return 0
    }
}

func booleanFromValue(_ val: LispType) -> Bool {
    switch val {
    case .lBoolean(let b):
        return b
        
    default:
        return false
    }
}

func stringFromValue(_ val: LispType) -> String? {
    switch val {
    case .lString(let str):
        return str
        
    case .atom(let atom):
        return atom
        
    default:
        return nil
    }
}

func lispTypeToString(_ lt:LispType, env:Environment) -> String {
    switch lt {
    case .number(let num):
        return "\(num)"

    case .atom(let atom):
        return "\(atom)"

    case .lString(let str):
        return str

    case .nil:
        return "Nil"

    case .lPair(let argPair):
        return "( \(argPair)"

    case .lFunction(let metadata):
        return "FUNCTION:\(metadata.argNames)"

    case .lBoolean(let b):
        return "\(b)"
        
    case .lTCOResult(let tcoResult):
        return "TCO(\(tcoResult))"
    }
}

func copyType(_ type: LispType) -> LispType {
    switch type {
    case .number(let num):
        return LispType.number(num)
        
    case .atom(let atom):
        return LispType.atom(atom)
        
    case .lString(let str):
        return LispType.lString(str)
        
    case .nil:
        return LispType.nil
        
    case .lPair(let argPair):
        return LispType.lPair(copyList(argPair))
        
    case .lFunction(let metadata):
        return LispType.lFunction(metadata)
        
    case .lBoolean(let b):
        return LispType.lBoolean(b)
        
    case .lTCOResult(let tcoResult):
        return LispType.lTCOResult(tcoResult)
    }
}

func copyList(_ p:Pair) -> Pair {
    var currentPair: Pair? = p;
    var newPairRoot: Pair?
    var newPairTail: Pair?
    
    while currentPair != nil {
        if(newPairRoot == nil) {
            newPairRoot = Pair()
            newPairRoot!.value = copyType(currentPair!.value)
            newPairTail = newPairRoot
        } else {
            let newPair = Pair()
            newPair.value = copyType(currentPair!.value)
            newPairTail!.next = newPair
            newPairTail = newPair
        }
        currentPair = currentPair?.next
    }
    
    return newPairRoot!
}
