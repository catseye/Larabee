The Larabee Programming Language
================================

Introduction
------------

The Larabee programming language, named after everybody's favourite
assistant to the Chief of CONTROL, is not a happy-go-lucky language.
Indeed no, it has plumbed the very depths of the bottomless pit of its
own soul, only to have its true nature revealed to it too quickly, the
utter shock of this *denoument* leaving it scarred and reeling.

You see, Larabee has borrowed the notion of *branch prediction* from the
realm of computer processor architecture, and has chosen to abuse it in
one simple but rather nasty way: the interpretation of each branch
instruction is not just *optimized* by the history of branches
previously taken, it is semantically *determined* in part by the history
of branches previously taken. Each branch taken (or not taken)
increments (or decrements) a value called the branch prediction register
(or BPR.) The BPR begins the program at zero; when the BPR is positive,
tests are interpreted in the usual way, but when the BPR is negative,
the interpretation changes: the "then" and "else" branches are swapped.

What's more, to prevent (or rather, to *stymie*) working around this by,
say, coding up a lot of branches dependent on constant data to "doctor"
the BPR to some extremely (high or) low value, no constant data is
allowed in a Larabee program. This has the effect of making programs
highly dependent on their input.

But enough of this insipidly sentimental dada. We must move on to
insipidly sentimental dada frought with errors and inconsistencies. Woe!

Syntax
------

Larabee programs are notated as S-Expressions, familiar from LISP or
Scheme. This is not solely because I am too lazy to write a parser. It
is also very fitting for a language which has all of the abstraction and
finesse of assembly code *sans* immediate mode.

Larabee forms are as follows:

-   `(op op expr1 expr2)`

    Evaluate expr1, then evaluate expr2, then perform the operation op
    on the results. Valid ops are `+`, `-`, `*`, and `/`, with their
    usual integer meanings, and `>`, `<`, and `=` with their usual
    comparison meanings, with a result of 0 on false and 1 on true.
    Division by zero is not defined.

-   `(test cond-expr expr1 expr2)`

    `test` evaluates the cond-expr to get either true (non-zero) or
    false (zero). What happens next depends on the value of the BPR.

    If the BPR is greater than or equal to 0:

    -   If cond-expr evaluated to true, evaluate expr1 and decrement the
        BPR.
    -   If cond-expr evaluated to false, evaluate expr2 and increment
        the BPR.

    On the other hand, if the BPR is less than 0:

    -   If cond-expr evaluated to true, evaluate expr2 and increment the
        BPR.
    -   If cond-expr evaluated to false, evaluate expr1 and decrement
        the BPR.

    `test` is the lynchpin upon which Larabee's entire notableness, if
    any, rests.

-   `(input)`

    Waits for an integer to arrive on the input channel, and evaluates
    to that integer.

-   `(output expr)`

    Evaluates expr to an integer value and produces that integer value
    on the output channel.

-   `(store addr-expr value-expr next-expr)`

    Evaluates addr-expr to obtain an address, and value-expr to obtain a
    value, then places that value in storage at that address,
    overwriting whatever happened to be stored at that address
    previously. After all that is said and done, evaluates to next-expr.

-   `(fetch addr-expr)`

    Evaluates addr-expr to obtain an address, then evaluates to whatever
    value is in storage at that address. Not defined when the currently
    running Larabee program has never previously `store`d any value at
    that address.

-   `(label label expr)`

    Indicates that this expr is labelled label. Serves only as a way to
    reference a program location from another location (with a `goto`;)
    when executed directly, has no effect over and above simply
    evaluating expr.

-   `(goto label)`

    Diverts control to the expression in the leftmost, outermost
    occurrence of a label named label.

Discussion
----------

Ah, the burning question: is Larabee Turing-complete? The burning answer
is, I think, a technical and somewhat subtle "no".

But first we must address our subject's special way of dealing with the
world. As you've no doubt noticed, Larabee has "issues" with input.
(Somewhat interestingly, this emotional baggage was not a direct design
goal; it was an unintended consequence of abusing branch prediction and
trying to prevent it from going unabused.) These issues will, it turns
out, haunt the language unceasingly, day in and day out, with despair
and turmoil forever just around the corner.

A specific hullabaloo induced by Larabee's obdurately retrograde (not to
mention completely stupid) input regime is that it's simply not possible
to write a program in Larabee which is independent of its input. This
alone may make it fail to be Turing-complete, for surely there are many
Turing machine programs which are input-invariant, and these programs
Larabee cannot legitimately aspire to one day become, or alas, even
emulate.

For example, input invariance is the underlying idea used in converting
the usual proof of the uniform halting problem into a (less obvious)
proof of the standard halting problem — you say, for any given input,
that we can find a machine that erases whatever input it was given,
writes the desired input on its tape, and proceeds to perform a
computation that we can't decide will halt or not.

The idea is also embodied in a traditional quine program, which produces
a copy of itself on its output, while talking no input. That is, it
doesn't matter what input is given to it (and this is often trivial to
prove since the quine is generally witten in the subset of the language
which does not contain any input instructions.)

But Larabee can't do either of these things. There is no Larabee program
that can replace its arbitrary input with some fixed, constant choice of
input. And while you can write a quine, it will require a certain input
to produce itself — there will always be other inputs which make it
produce something different.

"So what!" you say, being of bold philosophical bent, "it's mere
mereology. Whether we consider the input to be part of the program or
not is simply not relevant. Stop trying to confuse me with details and
definitions when I already know perfectly well what you're talking
about."

Fine, let's say that. The customer is always right, after all...

The problem, Wendy, is that Larabee is *still* not Turing-complete. But
there are subtler reasons for this. Needle-fine, almost gossamer
reasons. Ephemeral reasons with a substantial bouquet; fruity, with
notes of chocolate and creosote. I doubt that I can do them justice in
prose. However, it still strikes me as a more promising medium than
modern dance, I mean at least nominally anyway.

The reason is basically that you need to know a lower bound on how many
tests and variable accesses a Larabee program will make in advance of
running it, so you can supply that many values in the input to ensure
that the `test`s in the program go where you want them to go.

(It should be noted that it was rougly at this point that Pressey
reached one of the peaks of his so-called "referential" period, in which
he was apt to provide "commentary" on his own work, in the form of
interjections or asides, as if from the perspective of a historian from
a much later era. Such pretentious interruptions were generally not well
received, except perhaps by the occasional loser such as yourself.)

To illustrate, let's try walking through an attempt to have Larabee make
a computation. Factorial, say. In pseudocode, it might look like

    a := input
    b := 1
    while a > 0 {
      b := b * a
      a := a - 1
    }
    print b

Translating this one step toward Larabee, we find the following misty
wreck on our doorstep:

    (begin
      (store a (input))
      (store b 1)
      (label loop
        (begin
          (store b (op * b a))
          (store a (op - a 1))
          (if (op > a 0)
            (goto loop) (nop))))
      (print b))

Now, we can't use names, so we say that a lives at location 1 and b
lives at location 2 and we have

    (begin
      (store 1 (input))
      (store 2 1)
      (label loop
        (begin
          (store 2 (op * (fetch 2) (fetch 1)))
          (store 1 (op - (fetch 1) 1))
          (if (op > (fetch 1) 0)
            (goto loop) (nop))))
      (print (fetch 2)))

Now, we can't have constants either, so we hold our breath and grope
around in the dark to obtain

    (begin
      (store (input) (input))
      (store (input) (input))
      (label loop
        (begin
          (store (input) (op * (fetch (input)) (fetch (input))))
          (store (input) (op - (fetch (input)) (input)))
          (if (op > (fetch (input)) (input))
            (goto loop) (nop))))
      (print (fetch (input))))

...with the understanding that the appropriate inputs for this program
are ones that have 0, 1, and 2 in the right places. Naturally, sadly,
magnificently, other kinds of inputs will produce other, most likely
non-factorial programs.

Lastly, we have to give up hope of ever seeing the familiar shores of
our homeland again, bite the bullet and kick the `if` habit:

    (begin
      (store (input) (input))
      (store (input) (input))
      (label loop
        (begin
          (store (input) (op * (fetch (input)) (fetch (input))))
          (store (input) (op - (fetch (input)) (input)))
          (test (op > (fetch (input)) (input))
            (goto loop) (nop))))
      (print (fetch (input))))

And, oh, actually, we don't have `begin` — nor `nop`, neither. Hooray!

    (store (input) (input)
      (store (input) (input)
        (label loop
          (store (input) (op * (fetch (input)) (fetch (input)))
            (store (input) (op - (fetch (input)) (input))
              (test (op > (fetch (input)) (input))
                (goto loop) (print (fetch (input)))))))))

Now, if you've been following that, and if you can imagine in the
slightest how the input will need to look for any given integer, to
produce the correct factorial result on the output — even *assuming* you
added a bunch of `test`s somewhere in the program and fed them all the
right numbers so that the important `test` turned out the way you wanted
— then I needn't go to the extra trouble of a rigourous proof to
convince you that Larabee is not Turing-complete.

If, on the other hand, you decide to be stubborn and you say well that
might be a very involved encoding you're forcing on the input but it's
just an encoding and every language is going to force *some* encoding on
the input so *duh* you haven't shown me anything *really*, I'd have to
pull out the dreaded ARGUMENT BY ACKERMANN'S FUNCTION. However, I'd
really rather not, as it's late, and I'm tired. Maybe later.

*(later)* OK, it goes something like this. Ackermann's function — which
we know we need at least something that can do better than
primitive-recursive, to compute — has a lower-bound complexity on the
order of, well, Ackermann's function. (This in itself seems to be one of
those mathematical oddities that seems wiggy when you first hear about
it, then self-evident after you've thought about it for a few months...
and, if you are lucky, no less wiggy.) So anyway, what does that imply
about how many items would need to be input to a Larabee program that
computes Ackermann's function? And what does *that* imply about what
you'd need to obtain that input in the first place? Hmm? Hmm?

Trivia
------

There is an implementation of Larabee written in a relatively pure
subset of Scheme. I hesitate to call it a reference implementation, but
it seems I have no choice in these matters.

Conclusion
----------

It has come time to say goodbye to our subject, our illustrious
monstrosity, our glorious bottom-feeder, our feel-good cripple of the
year. With such a distressing burden to bear, what's a programming
language to do? Who could begrudge it seeking comfort in the arms of an
understanding mistress, a bottle of bourbon, the Cone of Silence? But
even so, saving such wretched constructions from their own
self-annihilation, so we may all learn from its example — this is one of
the very reasons we run this Home for Wayward Calculi, is it not?

Indeed.

This is the place where ordinarily where I would wish you a happy
something or other. But I shall graciously decline this time; it is all
too clear that there is simply no happiness left.

-Chris Pressey  
January 10, 2008  
Chicago, Illinois  
RICHARD M. DALEY, MAYOR
