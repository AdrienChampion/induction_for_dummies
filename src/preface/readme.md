# Preface

- [TL;DR below](#tldr)

[Formal logics][logics] deals with reasoning in the context of a formal framework. For example, a
*type system* is a formal framework. [Strongly-typed][strong typing] programming languages rely on
type systems to (dis)prove that programs are well-typed. For example, consider the following Rust
function.

```rust
fn demo(n: usize) -> usize {
    let mut res = n;
    if n % 2 = 0 {
        res = 2*n;
    } else {
        res = 2*n + 1;
    }
    return res;
}
```

When the Rust compiler type-checks this function, it goes through its body and aggregates some
*constraints*. These constraints are an abstraction of the definition that the type system can
reason about to (dis)prove that the program respects some type-related properties. For instance,
`let mut res = n;` is abstracted as *"`res` has the same type as `n`"*. The fact that, at this
point, `res` is equal to `n` is not relevant for type-checking.

\
\

Rust's most peculiar feature is the notion of *ownership* and the associated
[*borrow-checker*][borrow checker]. Similar to type-checking, borrow-checking abstracts the actual
code to encode it in a framework it can reason about. Type-checking's core notion is that of types,
and the equivalent for borrow-checking is *lifetimes*. Consider the following Rust function.

```rust ,compile_fail
fn demo(n: &mut usize) -> &mut usize {
    let mut res = *n;
    res += 1;
    return &mut res;
}
```

Now, this code does not compile because of the notion of *ownership*. Here, the function's body
*owns* `res` and, since it does not transfer `res` itself to the caller (only `&mut res`), `res`
is freed when we exit the body of the function.

\
\


*logical fragment*. A logical
fragment is, roughly, *i)* some *symbols* one can use to construct *terms* and *ii)* some *rules*
for reasoning/deducing/inferring *"things"* about these terms. The symbols let us encode the
*things* we want to reason about as terms. The rules give semantics to these terms by formally
describing how to reason about them.

Structurally, terms can be seen as trees. Typically, their leaves are *constants* (`7`, `true`,
`"some string"`) or variables which we can think of as identifiers. Terms can be combined using
*operators*, forming the nodes of term trees. The most ubiquitous operator is equality `=`; in a
(logical) fragment supporting integer arithmetic, we could have `+`, `≤`, `mod`, *etc.* Terms
typically have some notion of *type* (often called *sort* in this context), and operators a notion
of *signature* specifying how to use them to construct well-formed terms.

*Formal verification* uses *formal* logics to assess whether something is *provable* in a given
proof system. As a consequence, the notion of *formula* (*"boolean term"*) is a central notion in
logics. We will use a few common operators over formulas in this series:

- `∧`: conjunction *"and"*, similar to `&&` in most programming languages

    `a ∧ (x ≥ 3) ∧ true`

- `∨`: disjunction *"or"*, similar to `||` in most programming languages

    `a ∧ ( (x ≥ 3) ∨ (x ≤ 0) )`

- `¬`: negation *"not"*, similar to `!` in most programming languages

    `a ∧ ¬(x ≥ 3)`

- `⇒`: implication

    `a ⇒ b`, which is equivalent to `¬a ∨ b`

    That is, *"if `a` is true then `b` must be true"*.


## Verification

A verification problem usually consists of a bunch of *constraints* over some variables. These are
formulas that describe the object we want to verify. In the context of program verification, the
constraints encode the program we want to check.

For instance,

```text
(n % 2 = 0) ⇒ (res = 2*n)
¬(n % 2 = 0) ⇒ (res = 2*n + 1)
```

could be an encoding of the following function.



## TL;DR


TL;DR: program verification takes two things as inputs: a program to verify, and some properties to
verify over that program. These properties can be implicit (*e.g.* no division by zero, no dangling
pointer) or explicit (*e.g.* output of the function is positive).

A verification tool **encodes** the program and the properties in some formal framework allowing
whatever kind of reasoning it wants to conduct. Hence, the tool really (dis)proves that the encoding
of the program verifies the encoding of the property. Different frameworks will work on different
aspects of the semantics of the actual programs.

Applying verification to some context requires a deep understanding of the shape of the programs we
want to verify, and the kind of properties we want to verify. Only then can we decide of the most
appropriate formal framework for the job. This is both an expressiveness problem (can we express and
reason about what we want) and a performance problem. Verification is quite expensive, and
**usually** the more a given tool can do the slower it is. Ideally, we want a logical framework that
does what we need and nothing more.

Also, because the verification is actually done on the encoding, the trustworthiness of the results
depends heavily on our trust in the quality of the encoding step.



[logics]: https://en.wikipedia.org/wiki/Mathematical_logic
[peano]: https://en.wikipedia.org/wiki/Peano_axioms
[presburger]: https://en.wikipedia.org/wiki/Presburger_arithmetic
[prop_ops]: https://en.wikipedia.org/wiki/Logical_connective
[strong typing]: https://en.wikipedia.org/wiki/Strong_and_weak_typing
[borrow checker]: https://doc.rust-lang.org/1.8.0/book/references-and-borrowing.html