; MIT License
;
; Copyright (c) 2016 Andy Best
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

(in-ns 'core)

(defmacro ns
    (function
        (ns-name)
        `(in-ns (quote ~ns-name))))

; Macro for shorthand function declarations
(defmacro defn
    (function
        (str
            "defn\n"
            "(name [docstring] args body)\n"
            "Defines a function with the given name. Accepts an optional docstring.")
        (fName & body)
            `(def ~fName ~(concat '(function) body))))

(defn load-file (path)
    (eval (read-string (str "(do\n" (slurp path) ")"))))

(defn map 
    (str "map\n"
        "(f coll)\n"
        "Returns a collection made up of applying function f to collection coll")
    (f coll)
    (let (mapInt #((f1 processed remaining)
                        (if (|| (empty? remaining) (nil? remaining))
                            processed
                            (mapInt f1 (concat processed (f1 (first remaining))) (rest remaining)))))
        (mapInt f '() coll)))

(defn reduce (f val l)
    (if (|| (nil? l) (nil? (first l)))
        val
        (reduce f (f val (first l)) (rest l))))

(defn filter
    (str "filter"
        "(f coll)"
        "Filters collection with function f")
    (f coll)
    (let (processed '() collidx 0)
        (while (< collidx (count coll))
            (let (item (at coll collidx))
                (if (f item)
                    (set! processed (concat processed item))))
            (set! collidx (+ collidx 1)))
        processed))




;; Collection operations
(defn second
    "second
    (x)
    Gets the second item from the list x"
    (l)
    (at l 1))

(defn reverse
    "reverse\n\t(x)\nReverses the items in list x"
    (l)
    (let (x 0
         result '())
        (while (< x (count l))
            (set! result (cons (at l x) result))
            (set! x (+ x 1)))
        result))

(defn <=
    (x y)
    (|| (< x y) (== x y)))

(defn >=
    (x y)
    (|| (> x y) (== x y)))

(defmacro when
    #((pred & body)
    `(if (! (|| (nil? ~pred) (empty? ~pred)))
        ~(concat 'do body))))

(defmacro cond
    #((& clauses)
    (when clauses
        `(if (== :else ~(first clauses))
            ~(list 'do (at clauses 1))
            (if (|| (== :else ~(first clauses)) ~(first clauses))
                ~(list 'do (at clauses 1))
                ~(let (remaining (rest (rest clauses)))
                    (when remaining
                        (concat '(cond) (rest (rest clauses))))))))))


(defmacro case
    #((pred & clauses)
    (when clauses
        `(if (== :else ~(first clauses))
            ~(list 'do (at clauses 1))
            (if (== ~pred ~(first clauses))
                ~(list 'do (at clauses 1))
                ~(let (remaining (rest (rest clauses)))
                    (when remaining
                        (concat '(case) pred remaining))))))))



; Load additional core ns files
(load-file "core/defstruct.sl")
(load-file "core/file.sl")
