(def recurse (function (count)
    (cond (== 0 count)
    "Hooray!"
    (recurse (- count 1)))))

(print (recurse 5))