# SMT Scripts: SMT-LIB 2

This section goes through interactions with SMT solvers through the SMT-LIB 2 standard. Now,
SMT-LIB 2 is a readable scripting language, but it is designed to be written and read by programs,
not humans. Keep reading if you are interested in learning about SMT-LIB 2, which you need to if
you plan to directly interact with SMT solvers.

If you just want to understand what SMT solvers do, ideally with a more user-friendly language,
head to [SMT Scripts: Mikino](mikino.html). It's pretty much the same as this section with more
friendly language.

\
\



## Basics

For simplicity's sake, let's only allow atoms to mention integers. Consider the following formula.

```text
(declare-const x Int)
(declare-const y Int)

   ┌───∧─────┐
   │         │
 x > 7    ┌──∨──────┐
          │         │
          │         │
        y = 2*x   x = 11
```

The first two lines declare *"constants"* `x` and `y`. As programmers, we can see them as
*"variables"* in the sense that they represent an unknown value of type `Int`. This syntax comes
from the [SMT-LIB 2 standard][smt lib], which is the standard language for interacting with SMT
solvers. Most, if not all, SMT solvers support SMT-LIB 2 input.

Of course, the ASCII art tree representing the formula is *not* legal SMT-LIB 2. An SMT-LIB 2 script
declares constants (and more) and uses these constants to *assert* formulas, *i.e.* specify to the
solver what the constraints are.

Also, SMT-LIB formulas are written using *prefix notation* (or *Polish notation*). For instance, `y
= 2*x` would be written `(= y (* 2 x))`. This is a compromise between ease of printing/parsing and
human readability. SMT-LIB is really meant to be used by programs to communicate, not for humans to
actually write by hand. Still, it is readable enough for pedagogic and debugging purposes.

> [VS Code] has an extension for SMT-LIB syntax highlighting (`.smt2` files). The pieces of SMT-LIB
> code I will show in this book will not have syntax highlighting, unfortunately. I apologize
> for this problem, and encourage readers to copy these pieces of code in an editor that supports
> SMT-LIB using the button at the top-right of the code blocks.

Anyway, an SMT-LIB assertion of our running example would look like this:

```text
{{ #include code/ex_1.smt2 }}
```

The `assert` command feeds a constraint to the solver. Next, we can ask the solver to check
the satisfiability of all the constraints (of which there is just one here) with `check-sat`.


## Playing with Z3: `sat`

Let's now run Z3 on this tiny example. Create a file `test.smt2` and copy the content of the
SMT-LIB script above. No special option is needed and you should get the following output.

```text
❯ z3 test.smt2
{{ #include code/ex_1.smt2.out }}
```

Z3 simply answered `sat`, indicating that the formula is *"satisfiable"*: there exists a model (a
valuation of the variables) that make our constraints `true`. This is nice, but it would be better
if Z3 could give us a model to make sure it is not lying to us (it's not). We can do so by adding a
`get-model` command after the `check-sat`. (Note that `get-model` is **only** legal after a
`check-sat` yielded `sat`.)

```text
{{ #include code/ex_2.smt2 }}
```

After updating `test.smt2`, running Z3 again will produce a model. You might not get exactly the
same model as the one reported here depending on the precise version of Z3 you are using and
possibly other factors (such as your operating system).

```text
❯ z3 test.smt2
{{ #include code/ex_2.smt2.out }}
```

The model is slightly cryptic. Z3 defines `x` and `y` as functions taking no arguments, which means
that they are constants. This is because all functions are *pure* in SMT-LIB, meaning they always
produce the same output when given the same inputs. Hence, a function with no arguments can only
produce one value, and is therefore the same as a constant. In fact, `(define-fun <ident> () <type>
<val>)` is the same as `(define-const <ident> <type> <val>)`, and the `(declare-const <ident>
<type>)` we used in the SMT-LIB script is equivalent to `(declare-fun <ident> () <type>)`. Again,
in SMT-LIB (and pure functional languages) a constant is just a function that takes no argument.

This valuation is a model because `(> x 7) ≡ (> 8 7)` holds and so does `(= y (* 2 x)) ≡ (= 16 (* 2
8))`.

\
\

Now, remember that we can assert more than one constraint, and that Z3 works on the conjunction of
all constraints. In our running example, our only constraint is a conjunction, meaning we could
write it as two constraints.

```text
{{ #include code/ex_3.smt2 }}
```

Let's now add the constraint that `y` is an odd number: `(= (mod y 2) 1)`. This should void the
previous model, and more generally any model that relies on making `(= y (* 2 x))` true to satisfy
the constraints. (Since `y` would need to be both even and odd.)

```text
{{ #include code/ex_4.smt2 }}
```

We now get

```text
❯ z3 test.smt2
{{ #include code/ex_4.smt2.out }}
```

As expected, Z3 now has to make the second constraint `true` through `(= x 11)`.


## Playing with Z3: `unsat`

Let's add another constraint to make these constraints unsatisfiable. In the latest version of our
example, Z3 has no choice but to have `x` be `11` since it is the only way to verify the second
constraint (because the third constraint prevents `y` from being even).

We can simply constrain `x` to be even (which prevents `x` from being `11`), which we will write as
"`x` cannot be odd".

```text
{{ #include code/ex_5.smt2 }}
```

Z3 knows exactly what we are doing and replies that the formula is unsatisfiable.

```text
❯ z3 test.smt2
{{ #include code/ex_5.smt2.out }}
```

We get an error though, because it does not make sense to ask for a model if the formula is
unsatisfiable. *"Unsatisfiable"*, or *unsat*, means *"has no model"* (*i.e.* no valuation of the
variables can make all constraints true).

\
\

Now, what does this unsatisfiability result tell us? One way to see it is to consider the first
three constraints as some form of context. That is, the first three constraints correspond to some
point in a program where there are two unknown values `x` and `y`, and the first three constraints
encode what we know to be true about these values.

The last constraint can be seen as a question. Say that at that point in the program, there is an
assertion that `x` must be odd. We want to verify that this assert can never fail. From this point
of view, then the latest version of our running example amounts to asking "given the context (first
three constraints), is it possible for `x` to **not** be odd?". In other words, we are asking Z3 to
find some values that both verify our context and **falsify** the program's assertion.

Z3 answers "no": in this context, it is not possible for `x` not to be odd. This means that Z3
proved for us that the program's assert statement can never fail (and can be compiled away).

What if, with different constraints, the negation of the program's assert statement was
satisfiable? Then, [as we saw in the previous section](index.html#playing-with-z3-sat), Z3 can give
us a *model*: a valuation of all the (relevant) variables involved in the check. this constitutes a
*counterexample*, which shows how it is possible to verify the whole context but still falsify the
program assertion (*i.e* satisfy the SMT-LIB-level `(assert (not <program_assertion>))`).

## Outro

SMT solvers are extremely powerful, flexible and expressive tools. *Powerful* because they are
highly optimized tools constantly improved by ongoing theoretical and practical research.
*Flexible* because many different theories are available, allowing to manipulate integers, strings,
arrays, algebraic data types, *etc.* And *expressive* because a great deal of verification problems
are amenable to SMT without too much trouble.

One such verification problem is *declarative transition system (induction-based) verification*, as
we will see in the following chapters.



[smt lib]: http://smtlib.cs.uiowa.edu (SMT-LIB homepage)
[VS Code]: https://code.visualstudio.com (VS Code homepage)