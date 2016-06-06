(def fib (function (a b count) 
    (cond (== 0 count)
        b
        (fib b (+ a b) (- count 1)))))
    
(print (fib 1 1 100000))