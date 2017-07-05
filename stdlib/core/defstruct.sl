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

; Structure format:
; ({:type :structure :name [name] :slots [:slot1 :slot2 ...]}

(defmacro defstruct
  (function "defstruct"
    (name slots)
    `(do
        ; make-[structname]
        (defn ~(symbol (str "make-" name)) ~slots
            ~(let (metadata {:type :structure
                            :name name
                            :slots (map #((s) (keyword s)) slots)})
                  (cons 'list (concat metadata (map #((slot) (list (keyword slot) slot)) slots)))))
        
        ; [structname]-[slotname]
        ~(concat 'do (map 
          (function (slotnum)
            (let (slotname (at slots slotnum))
               `((defn ~(symbol (str name "-" slotname)) (struct)
                   (at struct ~(+ (* slotnum 2) 2))))))
          (math/range 0 (count slots))))

        ; [structname]-[slotname]-assoc
        ~(concat 'do (map
            (function (slotnum) (let (slotname (at slots slotnum))
                `((defn ~(symbol (str name "-" slotname "-assoc")) (struct newVal)
                    (assoc struct ~(+ (* slotnum 2) 2) newVal)))))
            (math/range 0 (count slots))))
        )))
