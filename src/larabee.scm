;
; larabee.scm - reference implementation of the Larabee programming language
; $Id: larabee.scm 15 2008-01-09 06:09:13Z catseye $
;

;
; Copyright (c)2006 Cat's Eye Technologies.  All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
;
; 1. Redistributions of source code must retain the above copyright
;    notices, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notices, this list of conditions, and the following disclaimer in
;    the documentation and/or other materials provided with the
;    distribution.
; 3. Neither the names of the copyright holders nor the names of their
;    contributors may be used to endorse or promote products derived
;    from this software without specific prior written permission. 
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
; FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
; COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
; BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
; ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.

; ----------------------------------------------------------------------------

;
; Updatable store ADT (implemented in pure Scheme.)
;

(define make-empty-store
  (lambda ()
    (make-vector 10 0)))

(define store-update
  (lambda (store addr value)
    (let*
      ((new-vector (expand-store store addr))
       (foo        (vector-set! new-vector addr value)))
      new-vector)))

(define expand-store
  (lambda (store addr)
    (let*
      ((extent (if (>= addr (vector-length store))
                 (vector->list (make-vector (- addr (vector-length store) -1) 0))
                 '()))
       (base   (vector->list store))
       (full   (append extent base)))
      (list->vector full))))

(define store-retrieve
  (lambda (store addr)
    (vector-ref store addr)))

; ----------------------------------------------------------------------------

;
; Larabee program state ADT.
;
; A state includes a "current value" (like an accumulator,) a store, and
; a special unbounded integer value called the "branch predicition register,"
; although it might be better called the "right bastard register."
;

(define make-state
  (lambda (value bpr store)
    (vector value bpr store)))

(define get-value
  (lambda (state)
    (vector-ref state 0)))

(define get-bpr
  (lambda (state)
    (vector-ref state 1)))

(define get-store
  (lambda (state)
    (vector-ref state 2)))

(define initial-state
  (make-state 0 0 (make-empty-store)))

(define bad-program
  (make-state #f 0 (make-empty-store)))

(define alter-bpr
  (lambda (state bpr-delta)
    (make-state (get-value state) (+ (get-bpr state) bpr-delta) (get-store state))))

(define set-value
  (lambda (state new-value)
    (make-state new-value (get-bpr state) (get-store state))))

(define state-store
  (lambda (state addr value)
    (let*
      ((old-store (get-store state))
       (new-store (store-update old-store addr value)))
      (make-state (get-value state) (get-bpr state) new-store))))

(define state-fetch
  (lambda (state addr)
    (let*
      ((store (get-store state))
       (value (store-retrieve store addr)))
      (make-state value (get-bpr state) store))))

; ----------------------------------------------------------------------------

;
; A function which can be uncommented to produce debugging output.
;

(define debug
  (lambda (str data)
;    (display str) (display ": ") (display data) (newline)
    data
  ))

; ----------------------------------------------------------------------------

;
; Evaluate a Larabee expression.  Returns a Larabee state.
;

(define eval-expr
  (lambda (expr prog state)
    (debug "eval-expr" expr)
    (cond
      ((null? expr)
        bad-program)
      ((list? expr)
        (let
          ((command (car expr)))
          (cond
            ((eq? command 'label)
              (let
                ((body (caddr expr)))
                (eval-expr body prog state)))
            ((eq? command 'test)
              (let
                ((condo  (cadr expr))
                 (expr-a (caddr expr))
                 (expr-b (cadddr expr)))
                (eval-test condo expr-a expr-b prog state)))
            ((eq? command 'goto)
              (let
                ((label (cadr expr)))
                (eval-goto label prog state)))
            ((eq? command 'op)
              (let
                ((operator (cadr expr))
                 (expr-a   (caddr expr))
                 (expr-b   (cadddr expr)))
                (eval-op operator expr-a expr-b prog state)))
            ((eq? command 'input)
              (eval-input prog state))
            ((eq? command 'output)
              (let
                ((msg-expr (cadr expr)))
                (eval-output msg-expr prog state)))
            ((eq? command 'store)
              (let
                ((addr-expr  (cadr expr))
                 (value-expr (caddr expr))
                 (next-expr  (cadddr expr)))
                (eval-store addr-expr value-expr next-expr prog state)))
            ((eq? command 'fetch)
              (let
                ((addr-expr (cadr expr)))
                (eval-fetch addr-expr prog state)))
            (else
              bad-program))))
      (else
        bad-program))))

;
; Evaluate a 'test' expression.
;

(define eval-test
  (lambda (condo expr-a expr-b prog state)
    (debug "eval-test" condo)
    (let*
      ((condo-state (eval-expr condo prog state))
       (bool        (get-value condo-state))
       (bpr         (get-bpr condo-state)))
      (if (>= bpr 0)
        (if bool
          (eval-expr expr-a prog (alter-bpr condo-state -1))
          (eval-expr expr-b prog (alter-bpr condo-state +1)))
        (if bool
          (eval-expr expr-b prog (alter-bpr condo-state +1)
          (eval-expr expr-a prog (alter-bpr condo-state -1))))))))

;
; Evaluate a 'goto' expression.
;

(define eval-goto
  (lambda (label prog state)
    (debug "eval-goto" label)
    (let
      ((targets (find-labels prog label)))
      (if (null? targets)
        (begin
          (display "No such target") (newline)
          bad-program)
        (begin
          (debug "found-targets" targets)
          (eval-expr (car targets) prog state))))))

;
; Helper function for eval-goto.
;

(define find-labels
  (lambda (expr label)
    (debug "find-labels" expr)
    (cond
      ((list? expr)
        (let
          ((command (car expr)))
          (cond
            ((eq? command 'label)
              (let
                ((putative-label (cadr expr))
                 (body-expr (caddr expr)))
                (if (eq? putative-label label)
                  (list body-expr)
                  (find-labels body label))))
            ((eq? (car expr) 'test)
              (let
                ((condo  (cadr expr))
                 (expr-a (caddr expr))
                 (expr-b (cadddr expr)))
                (append
                  (find-labels condo label)
                  (find-labels expr-a label)
                  (find-labels expr-b label))))
            ((eq? command 'op)
              (let
                ((expr-a   (caddr expr))
                 (expr-b   (cadddr expr)))
                (append
                  (find-labels expr-a label)
                  (find-labels expr-b label))))
            ((eq? command 'output)
              (let
                ((msg-expr (cadr expr)))
                (find-labels msg-expr label)))
            ((eq? command 'store)
              (let
                ((addr-expr  (cadr expr))
                 (value-expr (caddr expr)))
                (append
                  (find-labels addr-expr label)
                  (find-labels value-expr label))))
            ((eq? command 'fetch)
              (let
                ((addr-expr (cadr expr)))
                (find-labels addr-expr label)))
            (else
              '()))))
      (else
        '()))))

(define eval-op
  (lambda (operator expr-a expr-b prog state)
    (let*
      ((state-a  (eval-expr expr-a prog state))
       (value-a  (get-value state-a))
       (state-b  (eval-expr expr-b prog state-a))
       (value-b  (get-value state-b))
       (value-c  (enact-op operator value-a value-b)))
      (set-value state-b value-c))))

(define enact-op
  (lambda (operator value-a value-b)
    (cond
      ((eq? operator '+)
        (+ value-a value-b))
      ((eq? operator '-)
        (- value-a value-b))
      ((eq? operator '*)
        (* value-a value-b))
      ((eq? operator '/)
        (/ value-a value-b))
      ((eq? operator '>)
        (> value-a value-b))
      ((eq? operator '<)
        (< value-a value-b))
      ((eq? operator '=)
        (eq? value-a value-b))
      (else
        value-a))))

(define eval-input
  (lambda (prog state)
    (let
      ((value (read)))
      (if (number? value)
        (set-value state value)
        (begin (display "?REDO") (newline) (eval-input prog store))))))

(define eval-output
  (lambda (msg-expr prog state)
    (let
      ((new-state (eval-expr msg-expr prog state)))
      (begin
        (display (get-value new-state)) (newline)
        new-state))))

(define eval-store
  (lambda (addr-expr value-expr next-expr prog state)
    (let*
      ((addr-state  (eval-expr addr-expr prog state))
       (addr        (get-value addr-state))
       (value-state (eval-expr value-expr prog addr-state))
       (value       (get-value value-state))
       (new-state   (state-store value-state addr value)))
      (eval-expr next-expr prog new-state))))

(define eval-fetch
  (lambda (addr-expr prog state)
    (let*
      ((addr-state  (eval-expr addr-expr prog state))
       (addr        (get-value addr-state)))
      (state-fetch state addr-state))))

; ----------------------------------------------------------------------------

;
; Evaluate (run) a Larabee program.
;

(define eval-larabee
  (lambda (prog)
    (begin
      (eval-expr prog prog initial-state)
      (display "OK")
      (newline))))
