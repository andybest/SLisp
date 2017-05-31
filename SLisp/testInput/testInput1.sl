
(def fib (function (n i1 i2)
    (if (== n 0)
        i2
        (fib (- n 1) i2 (+ i1 i2)))))
