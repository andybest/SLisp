;(defmacro defn (function (fName args & body) `(def ~fName (function ~args ~(cons 'do body)))))

(defmacro defn
    (function (fName args & body)
        `(def ~fName ~(concat `(function ~args) body)))))

(def reduce (function (l f val)
    (if (nil? l)
        val
        (reduce (rest l) f (f val (first l))))))

(def map (function (l f)
   (let (mapInt (function (remaining processed f)
                   (if (nil? remaining)
                       processed
                       (mapInt (rest remaining) (cons (f (first remaining)) processed) f))))
       (mapInt l nil f))))

