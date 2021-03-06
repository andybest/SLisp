(ns rps)

(def rps-name (function (index)
    (if (== index 0) "Rock"
        (if (== index 1) "Paper"
            (if (== index 2) "Scissors"
                nil)))))

(def truth-table (list
                    (list false true false)
                    (list false false true)
                    (list false true false)))

(def outcome (function (p-choice c-choice)
    (at (at truth-table p-choice) c-choice)))

(def rock-paper-scissors (function ()
    (let (choice (input "(R)ock, (P)aper or (S)cissors? ")
          computer-choice (math/random 0 2)
          player-choice (if (|| (string= choice "R") (string= choice "r")) 0
                            (if (|| (string= choice "P") (string= choice "p")) 1
                                (if (|| (string= choice "S") (string= choice "s")) 2
                                    3))))
        (if (== 3 player-choice)
            (print "Invalid input: " choice)
            (do
                (print (str "You chose " (rps-name player-choice) "."))
                (print (str "The computer chose " (rps-name computer-choice) ".") )
                (if (== player-choice computer-choice)
                    (print "You drew.")
                        (if (outcome player-choice computer-choice)
                            (print "You win")
                            (print "The computer won"))))))))

(rock-paper-scissors)
