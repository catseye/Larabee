;
; test.scm - test suite for the Larabee reference interpreter
; $Id: test.scm 15 2008-01-09 06:09:13Z catseye $
;

(load "larabee.scm")

; ----------------------------------------------------------------------------

(define test1
  (lambda ()
    (eval-larabee '(label foo (goto foo)))
  ))

(define test2
  (lambda ()
    (eval-larabee '(output (op + (input) (input))))
  ))

(define test3
  (lambda ()
    (eval-larabee
     '(store (input) (input)
        (store (input) (input)
          (label loop
            (store (input) (op * (fetch (input)) (fetch (input)))
              (store (input) (op - (fetch (input)) (input))
                (test (op > (fetch (input)) (input))
                  (goto loop) (print (fetch (input)))))))))
    )))
