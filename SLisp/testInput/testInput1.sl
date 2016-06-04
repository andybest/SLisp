(def powInt (function (val original count)
    (cond (== 0 count)
        val
        (powInt (* val original) original (- count 1) ))))

(def pow (function (x p)
    (powInt x x (- p 1))))

(def fib (function (a b n)
    (cond (> (- n 1) 0)
        (fib b (+ a b) (- n 1))
        a)))

(def hello (function (x)
    (let (test "Hello, world!") (
        (print "test")
        (print test)))))

(hello x)


(def reduce (function (l f val)
    (cond (nil? l)
        val
        (reduce (rest l) f (f val (first l))))))

(reduce (1 2 3) (function (a b)
    (print "+" a b)
        (+ a b)) 0)