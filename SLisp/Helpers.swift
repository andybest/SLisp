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

func valueIsString(val: LispType) -> Bool {
    switch val {
    case .LString(_):
        return true
        
    default:
        return false
    }
}

func valueIsAtom(val: LispType) -> Bool {
    switch val {
    case .Atom(_):
        return true
        
    default:
        return false
    }
}

func valueIsPair(val: LispType) -> Bool {
    switch val {
    case .LPair(_):
        return true
        
    default:
        return false
    }
}

func valueIsNumber(val: LispType) -> Bool {
    switch val {
    case .Number(_):
        return true
        
    default:
        return false
    }
}

func valueIsFunction(val: LispType) -> Bool {
    switch val {
    case .LFunction(_):
        return true

    default:
        return false
    }
}

func valueIsBoolean(val: LispType) -> Bool {
    switch val {
    case .LBoolean(_):
        return true
        
    default:
        return false
    }
}


func pairFromValue(val: LispType) -> Pair? {
    switch val {
    case .LPair(let p):
        return p
        
    default:
        return nil
    }
}

func numberFromValue(val: LispType) -> Double {
    switch val {
    case .Number(let num):
        return num
        
    default:
        return 0
    }
}

func booleanFromValue(val: LispType) -> Bool {
    switch val {
    case .LBoolean(let b):
        return b
        
    default:
        return false
    }
}

func stringFromValue(val: LispType) -> String? {
    switch val {
    case .LString(let str):
        return str
        
    case .Atom(let atom):
        return atom
        
    default:
        return nil
    }
}

func lispTypeToString(lt:LispType, env:Environment) -> String {
    switch lt {
    case .Number(let num):
        return "\(num)"

    case .Atom(let atom):
        return "\(atom)"

    case .LString(let str):
        return str

    case .Nil:
        return "Nil"

    case .LPair(let argPair):
        return "( \(argPair)"

    case .LFunction(let metadata):
        return "FUNCTION:\(metadata.argNames)"

    case .LBoolean(let b):
        return "\(b)"
    }
}

func copyType(type: LispType) -> LispType {
    switch type {
    case .Number(let num):
        return LispType.Number(num)
        
    case .Atom(let atom):
        return LispType.Atom(atom)
        
    case .LString(let str):
        return LispType.LString(str)
        
    case .Nil:
        return LispType.Nil
        
    case .LPair(let argPair):
        return LispType.LPair(copyList(p: argPair))
        
    case .LFunction(let metadata):
        return LispType.LFunction(metadata)
        
    case .LBoolean(let b):
        return LispType.LBoolean(b)
    }

}

func copyList(p:Pair) -> Pair {
    var currentPair: Pair? = p;
    var newPairRoot: Pair?
    var newPairTail: Pair?
    
    while currentPair != nil {
        if(newPairRoot == nil) {
            newPairRoot = Pair()
            newPairRoot!.value = copyType(type: currentPair!.value)
            newPairTail = newPairRoot
        } else {
            let newPair = Pair()
            newPair.value = copyType(type: currentPair!.value)
            newPairTail!.next = newPair
            newPairTail = newPair
        }
        currentPair = currentPair?.next
    }
    
    return newPairRoot!
}
