(def powInt (function (val original count)
    (cond (== 0 count)
        val
        (powInt (* val original) original (- count 1) ))))

(def pow (function (x p)
    (powInt x x (- p 1))))

(print (pow 2 4))
