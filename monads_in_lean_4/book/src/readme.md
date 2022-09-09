# Monads in Haskell in Lean 4

This book is a Haskell-to-[Lean-4][lean] port of the awesome **Monads (and other Functional
Structures)** by [James Bowen][bowen]:

- <https://mmhaskell.com/monads>

<br>


[Lean 4][lean] is a blend of [Coq][coq] and Haskell with extremely powerful syntax extensions. It
also borrows ideas from multiple other languages such as [Koka], C++, Rust... Lean 4's main focus is
on safety, expressivity, and conciseness but it should be noted that efficiency is a very important
concern too.


Lean 4 is a programming language and presents itself as such, but it is also an **I**nteractive
**T**heorem **P**rover (ITP), *a.k.a.* "proof assistant", like [Coq][coq]. This means it can be used
to write *proofs*, typically to prove mathematical theorems and/or for verifying that some Lean 4
function(s) respect some form of specification.

This book is not proof-heavy, in fact we will barely see any until [Chapter 7](part7/index.html).
(Make sure you read [Examples as Theorems](#examples-as-theorems) below though.) Even then we will
focus what the theorems we prove mean, not really on the details of the proving them. All proofs in
this book are pretty simple and are understandable if you have a background in [Coq][coq] or have
read (and understood *most* of) Lean 4's basics from the [official learning material][lean doc].



## About Lean 4

[Lean 4][lean] is a *purely functional* language. This means that all Lean 4 functions are *pure*,
which in turn means that they cannot perform any *side-effect*. More explicitely, this means Lean 4
functions cannot do anything beyond **reading** data and producing a result. Mutating (*in-place
modifying*) anything in any way is *impure* and thus banned. This includes mutating global
variables, changing the value of a field of an argument, printing/reading to/from `std***`...

While this sounds very constraining, only dealing with pure functions has a massive impact on how
the compiler can rewrite, reason, optimize... the code. (*"Reasonning"* about code is going to come
into play very soon.) But pure languages are not limiting in that they can represent side-effect
when they need to using *monads*, and in particular the *state monad* which we will discuss in
[Chapter 5][part5/readme.md].

<br>

Lean 4 has a *dependent type system*, which means that its types are extremely powerful. For
instance

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:intro_add_comm1 }}
```

declares `add_comm` as having type `∀ (n₁ n₂ : Nat), n₁ + n₂ = n₂ + n₁` which is a formula that
reads *"for all natural numbers `n₁` and `n₂`, `n₁ + n₂` is equal to `n₂ + n₁`"*. More consisely,
*"addition over natural numbers is commutative"*. The `:=` starts its definition which here is just
`Nat.add_comm`, a builtin Lean 4 definition for commutativity over `Nat`.

<br>

This book is not really an introduction to Lean 4. Ability to read/write even simple proofs is not
necessary, neither do you need to understand type universes. I will do my best to introduce
Lean-specific notions as they appear, but the book is more accessible with some understanding (even
basic) of Lean 4's main concepts:

- writing a simple program defining and using a few functions;
- defining and using structures and algebraic datatypes;
- typeclasses: definition, instantiation, and typeclass resolution.

The concepts above require an understanding of the basics of dependent type theory and *proposition
as types* (Curry-Howard), *e.g.* understanding why the signatures of these three functions are
equivalent:

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:intro_add_comm1 }}
{{ #include ../../HaskellMonads/Init/Examples.lean:intro_add_comm2 }}
{{ #include ../../HaskellMonads/Init/Examples.lean:intro_add_comm3 }}
```

<details>
<summary>Discussion on these three signature.</summary>

Probably the most natural version, for developers, is the third one (`add_comm₂`):
- *"if you give me two `Nat`s `n₁` and `n₂`, I can construct a proof of `n₁ + n₂ = n₂ + n₁`"*.

The second version `add_comm₁` is very similar. It does not directly takes parameters directly,
but instead produces a function that takes the same parameters as `add_comm₂`:
- *"here is a function, if you give it two `Nat`s it will produce a proof that adding is
  commutative"*.

The first version `add_comm` looks less like a function and more like a theorem starting with a
universal quantification (*forall*, `∀`) over two `Nat`s. It states that
- *"given any two `Nat`s `n₁` and `n₂` here is a proof of `n₁ + n₂ = n₂ + n₁`"*

which is really the same as `add_comm₂`.
---
</details>


If you have experience with [Coq][coq], you should be fine; Haskell probably works too. Otherwise
head to [Lean 4' Documentation][lean doc] and come back when you feel ready.



## Monads

Monads are deceiving. They belong to this frustrating class of concepts that simultaneously have a
very simple formal description, but represent a powerful abstraction over seemingly distinct, less
abstract notions. This makes grasping the full power of monads difficult, despite how simple their
description is.

So simple we could give a three line description. Actually let's do that:

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:monad_class }}
```

<details>
<summary>Typeclasses?</summary>

In Lean 4, `class` defines a *typeclass*. Here, `Monad` has a type parameter `Mon` which is a type
contructor (`Type → Type`). We can think of a (type)class as a structure definition with field
declarations. `Monad` has two fields, `pure` and `bind`. For instance, the former takes a type
`α`, a value of type `α`, and produces a `Mon α`.

The point of classes is to be *instantiated* (or *implemented*), which consists in providing
definitions for the fields of the class as we will see later.

---
</details>

<details>
<summary>Implicit parameters "{...}"?</summary>

*Implicit parameters* are written between braces (`{α : Type}`) and tell Lean 4 that these
parameters will not be provided, they must be inferred from the context. For example `pure`'s first
explicit parameter is a value of type `α`, meaning that Lean can infer what `α` is by looking up the
type of the value provided.

---
</details>

If you don't know about monads, that's pretty useless. It is worth noting that this `Monad` class
specifies functions over its parameter `Mon`, which is a `Type → Type`. This means `Mon` is a type
constructor, *i.e.* it's a function taking a `Type` and producing another `Type`.

So, our mindbrain can think of `Mon` as some kind of wrapper; `Option`, for instance:

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:option }}
```

<details>
<summary>Inductive datatypes?</summary>

Keyword `inductive` defines an *inductive datatype* which is basically an enumeration. Values of that type
are constructed by using variant constructors, `none` and `some` here. The first one takes no parameter and
builds an `Option α` for any `α`, while `some` takes an `α` as parameter to construct an `Option α`.

---
</details>

<details>
<summary>"#check"?</summary>

`#check <expr>` is a Lean query that outputs a result when the program is compiled (output also
appears directly in the IDE at location). The output of the `#check` query is the type of the
expression it was fed.

---
</details>

<details>
<summary>"@" notation?</summary>

Remember that parameters can be implicit, *e.g.* `{α : Type}`. When we `#check Option.some`, we
see this weird `?m.486` type pop up, which corresponds to an implicit parameter. By putting `@` in
front of a function/type, we turn all implicit parameter into explicit ones. This allows to
specify implicit parameters explicitely when needed, but it's also useful for `#check`ing them as
it makes implicit parameters more readable, *e.g.* implicit `?m.486` becomes an explicit `{α :
Type}` here.

---
</details>

Or maybe this `Log` type constructor, which stores messages in addition to the wrapped value:

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:log }}
```

<details>
<summary>Structures?</summary>

A `structure` is essentially a *record* or *struct* in most languages. Here `Log α` defines a
type, and to construct a value of that type you need to provide values corresponding to each field
of the structure. Note that structure are automatically equipped with a constructor `<type
name>.mk` (by default), *e.g.* `Log.mk` here.

---
</details>

Both these examples can be seen as monads, and in fact `Option` is often the first monad discussed
in tutorials.



## Examples as Theorems

Sometimes, in the examples, we will want to see the result of a computation. Usually this is done
by having the program print the result we want to see, running the program, copying the output and
adding it as a comment somewhere so that it's in the book.

We're not going do that, the copied output will be obsolete fast. Instead, let's use Lean 4's
ability to prove things (stay with me). Let's just build a term that's an equality between what we
want to compute and the result we expect. We can do so by using `example` (like `def` but
anonymous).

Using `add_comm` and `add_comm₁` from earlier as an example, it looks like this:

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:example_proof }}
```

These equalities are simple enough that Lean 4 can prove they hold simply by invoking
**r**e**fl**exivity (`rfl`). This prompts the compiler to perform simple reductions in the hope
of ending up with exactly the same term on both sides of the equality.

Neat, now the compiler will complain if something breaks.

Sometimes proving the equality will involve slightly more work. In this case we might rely on the
usual, commented-print version. Even when a complex proof shows up, remember you don't need to
understand a proof in an `example` unless you want to, the point is just to show that the equality
does hold.



## Type universes

> We are going to speedrun this notion, explaining type universes in details would take the whole
> book. You do not need to master type universes for what comes next, but you do need an intuition
> of what they mean.
> 
> If this is your first time reading about type universes, read on but don't expect to get a firm
> grasp. Get a general picture, but you will need to actually see them in action and play around to
> really get it. A very good exercise is to always guess the type universe of your type/function
> definitions before looking at what Lean inferred.

The notion of *type universe* is a relatively challenging one. Lean 4 is a very powerful language,
for instance the fields of a structure are not restricted to storing only *values*, they can also
store *types*.

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_types }}
```

Now that's pretty powerful, `StoresAType` is similar to `HasTypeParam` but `α` has been *erased*:
it is not visible from the outside.


### Compile-time (meta-)data and (meta-)programs

Let's think in terms of what makes sense at *runtime*. Given an `α`, `HasTypeParam α` just stores a
function. If we have `s : HasTypeParam String` for example, we can call function `s.f` on a `String`
and get a `String` back. That is, we can use `s` (meaning `s.f` really) to *compute* things.

What about `s : StoresAType`? Well, at runtime, we cannot do anything with it: `s.α` can be
anything, so how do we provide a parameter to `s.f` if we don't know what goes *in* (or *out*) this
function?

The idea here is that `StoresAType` is not really a datatype in the same sense that `HasTypeParam α`
is. It is really a construct that only makes sense at *compile-time*. Say we create a `StoresAType`
with `α := Bool`, what is the runtime/computation-meaning of `Bool` as a value of type `Type`? What
can we do with this value if we access it at runtime?

Not much, but we can see `StoresAType` as a *specification* for generating actual *computable*
programs, such as

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_use_type1 }}
```

<details>
<summary>No ":=", matching right away?</summary>

The definition style above is just syntactic sugar. Whenever we are defining something of type
`someType → ...` where `someType` is an inductive datatype, we can directly `match` on the input
value by omitting the `:=` starting the definition.

This version is equivalent to

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_use_type1_alt2 }}
```

which is the same as this potentially more natural version

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_use_type1_alt1 }}
```

---

</details>

What's interesting is that we can see `mapStoresAType` as a *program generator* which, given a `s :
StoresAType`, generates an actual "computable" program. If we give it two different `StoresAType`s,
we obtain two different computable programs which, in general, will not even have the same
signature.

So, intuitively, `StoresAType` is quite different from "plain datatypes" like `String`, `Option Nat`
and such. So different that we could say it should live in a different universe, the universe of
*"things that can be used to generate actual programs"*, or *"things for program generation"*, or
*"meta-programs"* like `mapStoresAType`. Does Lean actually acknoledge this distinction? Let's
`#check` it out.

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_types_check }}
```

👀 `Type 1`? See, `Type` is actually a shorthand for `Type 0`. So types like `HasTypeParam`,
`String`, and `Bool` have type `Type 0`. Integer `n` in `Type n` is called a *type universe*, so
these types live in type universe `0`, which is essentially the type of computable *data* in the
normal programming sense of the word.

As we have seen already, `StoresAType` stores a type (!) in type universe `0` which means its
purpose is to generate programs working on *data* (from `Type 0`). That's the main way Lean decides
in which universe a given type lives. It sees that `StoresAType` stores a `Type 0`, meaning it
cannot live in `0` and must be in the universe *above*, which is `1` (`0 + 1`).



### Brief sanity detour

What does this mean in terms of *"traditional languages"*? Well `StoresAType` is really some kind of
*interface*, some kind of specification that can be realized/instantiated/implemented by some
type(s). Think of a function `f` that accepts as input any type `T` respecting some interface
`Interface`. If you see the actual realization/instance/implementation of the interface for `T` as a
parameter, then `f : Interface T → T → Output`.

`Interface` may itself contain some types, in which case this `Interface T` parameter is really in
`Type 1`. It does not have computational value by itself, it's just a means to specify how to write
the part of `f` corresponding to `T → Output`. In other words, `f` is a (`Type 1`)-meta-program that
generates different `T → Output` programs (in `Type 0`) depending on the value of its `Interface T`
parameter.




### One more type universe

You're probably wondering, can we keep going up type universes?

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_type1 }}
```

Seems like we can. Because it stores a `Type 1`, `StoresAType1` should live in `Type (1 + 1)`. Let's
not leave anything to chance here.

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_type1_check_lol }}
```

Right so according to Lean's trusted kernel's evaluation we are expecting `Type 2`.

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_type1_check }}
```

Sweet.



### Infinitely more type universes

But what if we don't know the actual universe of `α`? Are we allowed to use variables for universes?
Let's just replace `Type 1` by `Type u` and see what happens.

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_typeu }}
```

Lean seems to replace our `u` with a `u_1`, but other than that everything works fine. Note that `u`
is a universe parameter of `StoresATypeU`, which we could make visible by using the following
equivalent, explicit syntax.

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_typeu_expl }}
```

<br>

So, `Type 0` is where *data* and programs over data live. `Type 1` contains meta-data ("interfaces"
over `Type 0`) and meta-programs, *i.e.* programs that take some input and generate `Type
0`-programs. `Type 2` contains meta-meta-data ("interfaces" over `Type 1`) and
meta-meta-programs, *i.e.* programs that take some input and generate `Type 1` programs.

More generally, `Type (u + 1)` contrains `u+1`-meta-data ("interfaces" over `Type u`) and
`u+1`-meta-programs, *i.e.* programs that take some input and generate `Type u` programs.

<br>

Here's a fun question, what if our structure stored some `Type u` and some `Type v`? For instance,
in

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_typeuv }}
```

<details>
<summary>what does the `#check` output?</summary>

If we stored only `Type u`, we would be in `Type (u + 1)`. For `Type v`, `Type (v + 1)`. Since type
universes define a hierarchy, if we knew whichever of `u` and `v` was the greatest, then the smallest
universe in which we can be can to talk about `Type u` and `Type v` is `(max u v) + 1`.

We can try this ourselves by adding an explicit type annotation to `StoresTypesUV`:

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_typeuv_expl }}
```

What about the original version, without explicit type annotation?

```lean
{{ #include ../../HaskellMonads/Init/Examples.lean:type_univ_storing_typeuv_check }}
```

Well, that works too.
</details>



### Brief sanity stop on the way out

If, in traditional languages, `Type 0` is data and programs, and `Type 1` is interfaces and
polymorphic/generic functions, then what is the counterpart for `Type u`? The counterpart would need
to be able to generate programs that generate programs that generate programs...

Well one would usually rely on macros for that. In many languages, macros allow to generate
functions and type definitions, or even new macros which in turn can generate function and type
definitions. Now obviously macros are not equivalent to type universes. Macros are pre-processors,
they work on syntactic tokens (the AST) and expand before type-checking.

Type universes on the other hand are fully integrated into Lean's type system. So when we write/use
them, we can express constraints using, for instance, typeclasses. Lean checks that everything is
legit (type-checks) and we benefit *heavily* from Lean's type inference during the whole process.



### And That's Enough ...

That's enough type universes. This is all just so that the `Type u`-s and `Type v`-s that are going
to appear pretty soon are not too obscure. When you see one, it basically means *"any type at all"*,
in any universe. That's just how powerful monads and similar constructs are, they don't even care
whether we're talking about programs, programs that can generate programs, data, interfaces...

We still need to name universes (`u`, `v`...) and Lean still needs to track them internally to know
what universe a given type is in. But we will not do anything fancy with them, type universes will
just appear in the code and *be there*.



### ... To Dive Deeper

> You do not need to understand the following to read this book's **actual** content, or most of it
> anyway.

We actually saw the simple, more intuitive version of type universes. Lean 4 is an Interactive
Theorem Prover, and as such you can write *propositions*, which you can think of as theorems.

These propositions do not live in `Type u` for any `u`. They are neither computable data/programs,
nor meta-data/meta-programs. They're just logics, and they live in a world appropriately called
`Prop`.

Going back to type universes for a bit, we had this idea that universes build on each other. We use
things from `Type 0` to build things in `Type 1` and so on. But is `Type 0` itself built on
something? What do we use to construct computable data and programs?

Logics, we use logics. So it turns out that `Prop` itself is just an abbreviation for `Sort 0`. Much
like `Type`, `Sort` is parameterized by a universe (an integer). Now, if `Type 0` is based on
logics, and the world of logics is `Prop` which is really `Sort 0`, it means that `Type 0` should
really be... `Sort 1`?

Yes, it does. In fact `Type u` is really `Sort (u + 1)` 🤯. So the big-picture is:


|     intuition     |     Lean `Type u` |     | Lean `Sort`       | traditional languages |
| :---------------: | ----------------: | --- | :---------------- | :-------------------: |
| logics and proofs |                   |     | `Sort 0` (`Prop`) |          no           |
|   data/programs   | (`Type`) `Type 0` | `=` | `Sort 1`          |  types and functions  |
|       meta-       |          `Type 1` | `=` | `Sort 2`          | interfaces, generics  |
|    meta-meta-     |          `Type 2` | `=` | `Sort 3`          |    macros, if that    |
|        ...        |               ... | `=` | ...               |          ...          |
|     meta`^u`-     |          `Type u` | `=` | `Sort (u+1)`      |    macros, if that    |
|        ...        |               ... | `=` | ...               |          ...          |



## Content

The rest of the book is organized as follows.

- [Chapter 1: Functors](part1/index.html) introduces the relatively simple abstract concept of
  *functors* as a first step towards monads.

- [Chapter 2: Applicative Functors](part2/index.html) builds on the (vanilla) functors from Chapter
  1 to produce an abstraction that's closer to monads: *applicative functors* or just
  *applicatives*.

- [Chapter 3: Monads](part3/index.html) leverages previous chapters about functors and applicatives
  both in the sense that monads build on these concepts, and because our abstract-structures muscles
  will be quite pumped at that point.

- [Chapter 4: Reader and Writer Monads](part4/index.html) is still going despite the previous
  chapter covering monads. This is because monads in their pure, abstract form are not directly
  useful to actually *do stuff*. To *do stuff* (and *understand stuff*), we must see how this
  abstraction is used in practice, the *monadic idioms*. These first monadic idioms deal with
  reading and writing state.

- [Chapter 5: State Monad](part5/index.html) discusses a third, major monadic idiom: the state
  monad. If you're angry because purely functional programming cannot do something your favorite
  imperative language can, purely functional languages actually can do that and the answer to
  *"how?"* is most likely *"with a state monad"*.

- [Chapter 6: Monad Transformers](part6/index.html) is ~~a cartoon selling toys to young children~~
  where we start combining monads, and abstracting a combination of monads as a monad. It's straight
  fire.

- [Chapter 7: Monad Laws](part7/index.html) departs from defining/using monads and presents the laws
  that (functors, applicatives, and) monads are expected to verify. Lean 4 allows us to write
  proofs, so we will write these laws as actual Lean 4 properties and (logically) *prove* that the
  monads we have seen previously verify these laws.

That's it.



[lean]: https://leanprover.github.io
[bowen]: https://github.com/jhb563
[coq]: https://coq.inria.fr
[koka]: https://koka-lang.github.io/koka/doc/book.html
[lean doc]: https://leanprover.github.io/documentation
[Russel's paradox]: https://en.wikipedia.org/wiki/Russell%27s_paradox