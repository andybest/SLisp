

(def map (function (l f)
   (let (mapInt (function (remaining processed f)
                   (if (nil? remaining)
                       processed
                       (mapInt (rest remaining) (cons (f (first remaining)) processed) f))))
       (mapInt l nil f))))

