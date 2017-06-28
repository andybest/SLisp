(ns core)

; Macro for shorthand function declarations
(defmacro defn
    (function
        (str
            "defn"
            "(name [docstring] args body)"
            "Defines a function with the given name. Accepts an optional docstring.")
        (fName & body)
            `(def ~fName ~(concat '(function) body))))

                
(defn map "Test" (f coll)
    (let (mapInt #((f1 processed remaining)
                        (if (|| (empty? remaining) (nil? remaining))
                            processed
                            (mapInt f1 (concat processed (f1 (first remaining))) (rest remaining)))))
        (mapInt f '() coll)))

(defn reduce (f val l)
    (if (|| (nil? l) (nil? (first l)))
        val
        (reduce f (f val (first l)) (rest l))))

(defmacro defstruct
  (function "defstruct"
    (name slots)
    `(do
        ; make-[structname]
        (defn ~(symbol (str "make-" name)) ~slots
          ~(cons 'list (concat (map #((slot) (list (keyword slot) slot)) slots))))
        
        ; [structname]-[slotname]
        ~(concat 'do (map 
          (function (slotnum)
            (let (slotname (at slots slotnum))
               `((defn ~(symbol (str name "-" slotname)) (struct)
                   (at struct ~(+ (* slotnum 2) 1))))))
          (math/range 0 (count slots)))))))


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
