(def powInt (function (val original count)
    (cond (== 0 count)
        val
        (powInt (* val original) original (- count 1) ))))

(def pow (function (x p)
    (powInt x x (- p 1))))

(print (pow 2 4))


(def fib (function (a b n)
    (cond (> (- n 1) 0)
        (fib b (+ a b) (- n 1))
        a)))

(print (fib 1 1 1000))