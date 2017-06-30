(ns math)

(def *pi* 3.14159265358979323846)

(def floor (function (x)
    (- x 1 (mod x 1))))

(def max (function (x y)
    (if (> x y) x y)))

(def min (function (x y)
    (if (< x y) x y)))

(defn even?
    (& args)
    (reduce
        #((val x) (if (! val) val (== (mod x 2) 0)))
        true
        args))

(defn odd? (& args) (! (apply math/even? args)))
