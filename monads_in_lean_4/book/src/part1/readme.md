# Functors

> *Monads in Haskell* original post:
>
> - <https://mmhaskell.com/monads/functors>

<br>

A *Functor* is an abstract structure consisting of a single `map` function.
Functors are simple enough that they are quite easy to understand, at least
compared to monads. Feel free to skip this and move on to the [chapter on
applicatives](../part2/index.html) if you already have a **solid** grasp on
functors.



## Definition

As discussed in the [intro](../index.html#monads), monads deal with type
constructors `Mon : Type → Type`, or more generally `Mon : Type u → Type v`,
which we can see as *wrappers* or *containers* `Mon α` around some type `α`.
It's the same for functors, and if we decide to call the type constructor `Fct`
then we can define the notion of Functor as follows.

Note that [Lean 4's `Functor`][functor] is not defined *exactly* this way, we'll
discuss that [soon](#functor-in-lean-4) as it does not matter for now.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:functor_class }}
```

> Note that in Lean 4, characters `?` and `!` can appear in identifiers. So `a?`
> is just an identifier, like `a`, `a'`, `a!` or `myIdent`. It is not special
> notation for anything, nor are `?` and `!` operators.

Let's go over its arguments:

- two implicit types `α` and `β`, in `Type u` since they're used as inputs for
  `Fct`,
- a function from `α` to `β`, and
- a value of type `Fct α` (wrapped `α`).

Given these, `map` produces a `Fct β` (wrapped `β`).

<br>

The idea here is that `Functor.map` is a **struture-preserving** transformation.
Whatever the `Fct` wrapper might be, it has some structure. `Functor.map` must
preserve it and only modify the zero, one, or many `α` value(s) stored inside.

Let's see that in action on some examples.



## Examples

Some readers probably thought of [`List.map`] and/or [`Option.map`] as soon as
they saw `Functor.map`. And that's correct: both [`List`] and [`Option`] are
functors (they are monads too).


### `Opt`ion as a `Functor`

Let's define our own `Opt`ion type:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:opt_def }}
```

Now we define a function with the signature of `Functor.map` for `Opt`:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:opt_bad_map }}
```

This does not look right... `Functor.map` must be structure-preserving, and
`Opt.badMap` is not since it turns a `som _` in a `non`. The only
structure-preserving definition we can give is the normal `map` over options:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:opt_map }}
```

<details>
<summary>About the "·" in the second example...</summary>

When appearing in a term between parens, `·` means *"this term is a function
taking an argument and putting it here"*. So `(· * 3)` is really `fun n => n *
3`.

---
</details>

That's better, we can now instantiate `Functor`:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:opt_functor }}
```

Now we can mess around with `Functor.map`:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:opt_examples }}
```




### `List` as a `Functor`

Let's define some lists and a few functions:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:list_defs }}
```

<br>

A *map* of a function `f` over a list `l` creates a new list containing the
result of applying `f` to each element of `l`. [`List.map`] is the map function
over lists, let's use that as our `Functor.map`

```lean
{{ #include ../../../HaskellMonads/Part1.lean:list_functor }}
```

and check that it does what it's supposed to

```lean
{{ #include ../../../HaskellMonads/Part1.lean:list_examples }}
```

<details>
<summary>What's this "|>" operator?</summary>

`term1 |> term2` is syntax for `term2 (term1)`, it passes its left-hand side as an argument to its
right-hand side. You can read `someFn arg1 |> someFn' arg1' arg2' |> someFn'' arg1''` as

- compute `someFn arg1` and obtain `val`;
- compute `someFn' arg1' arg2' val` and obtain `val'`;
- compute `someFn'' arg1'' val'`.

---
</details>

<br>

Notice how the `List` structure is preserved. Whatever function `f` we *map* over some list `l`, the
result will have the same number of elements as `l`; also, each application of `f` appears in the
same order in the result as does its argument in `l`.



### `Option` as a `Functor`

Here are some `Option` values to play with:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:option_defs }}
```

A *map* of a function `f` over an option `opt`

- `none` if `opt` is `none`,
- `some (f a)` if `opt = some a`.

By its definition alone we can confirm that this *map* is structure-preserving for `Option`. Only
the internal value, if any, changes while the constructor (`some` or `none`) is preserved.

This echoes *map* over lists which only modify each value in the list while preserving the *chain
of constructors* `cons _ (cons _ (cons _ ...))` as *map* preserves length and order.

Let's see this in practice, using functions from the [previous `List` section](#list-as-a-functor).

```lean
{{ #include ../../../HaskellMonads/Part1.lean:option_examples }}
```



## Writing an Original Functor

Let's have fun with a structure representing measurements for some real estate. In the real world
everyone uses the metric system (don't **@me**), but let's pretend some still use some archaic,
medieval system measuring areas in square "feet". Then we would need our `Measurements` structure to
handle different units, turning the unit itself into a type parameter.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:measurements_def }}
```

We probably need some conversion function over `Measurements` to accomodate for medieval people.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:measurements_convert }}
```

Now this looks a lot like the signature of `Functor.map`. It's also consistent with what functors
do: changing stored value(s) while preserving the surrounding structure. Let's see if we can
actually instantiate `Functor` on `Measurements`.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:measurements_functor }}
```

That was easy.

<br>

To have even more fun than we already are, we need to give ourselves some units

```lean
{{ #include ../../../HaskellMonads/Part1.lean:measurements_units_def }}
```

and some functions to convert between units.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:measurements_units_conv }}
```

<br>

Sweet, now to use all of this on concrete values.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:measurements_examples }}
```

<br>

As introduced in `m₄`'s definition, the infix operator `lft <$> rgt` is the same as `Functor.map lft
rgt`. With practice, `<$>` is significantly less cumbersome than the alternative and makes chaining
*maps* easier. For instance, the very last `example` could be rewritten as follows.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:measurements_examples_alt }}
```

That's enough fun, let's get serious.



## Functor Laws

> This section discusses the logical properties of functors. There will be a few trivial proofs in
> there. Feel free to skim through, especially as we will go over all of this again in the [last
> chapter](../part7/index.html).

So far we have only seen the programmatic aspects of functors: they require a `map` function that's
used to compute stuff. However functors, as concepts from category theory, have to verify some
properties.

<br>

In less expressive programming languages, we would have to write these properties in the
documentation and have tests/assertions trying to check whether these properties are respected.
Lean 4 has dependent type theory so let's just write a class with these properties.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:laws }}
```

So there are two properties. The first one, called *identity*, states that mapping the identity
function `id` over any `Fct` value yields the same value, unchanged. This is consistent with the
idea that `map` does not change the structure of the wrapper around the value(s), it can only change
the value(s). Since `id` does not change anything, then `map id` does not change anything.

The second property is called *composition* and says that mapping some function `f`, and then some
other function `g` should be equivalent to mapping `f ∘ g`.

If you're not sneaky about your `Functor` instantiation, you should verify these laws by default.
You **would** falsify them if `map f` did anything else than applying `f` to the `α`-s.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:laws_cex }}
```

This breaks both *identity* and *composition*.


<br>

It is easy, maybe, to see these properties has having very little practical impact. "So what if my
functor does not respect *composition*?"

Well, so what if you functor **does** respect *composition*? So the compiler can perform
optimizations relying on this property. Maybe you call some function performing a single *map*, and
then you perform your own *map* on the result. Then the compiler can, if it wants, optimize both
*maps* as a single one. If you are working on a complex structure, a tree for instance, this means
one traversal instead of two.

Also, since functor are expected to respect these properties, users might rely on them which would
break their code and cause them to complain profusely.

<br>

So, whenever possible we want to prove these properties actually do hold. Let's do so with our
`Measurements` example:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:laws_proof }}
```

We encouter `rfl` again. As discussed [earlier](../index.html#examples-as-theorems), our `example`s
rely on `rfl` to make Lean 4 prove equalities between some term and an expected (*evaluated*) value.
Here, `rfl` is powerful enough to conduct both proofs completely for us.



## `Functor` in Lean 4

Earlier, we gave the following definition for the `Functor` class.

```lean
{{ #include ../../../HaskellMonads/Part1.lean:functor_class }}
```

As mentioned back then, Lean 4's `Functor` is slightly different. Here it is:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:lean_functor }}
```

So what's going on here? The new `mapConst` function is almost the same as `map` but takes a
"constant" `β` instead of a function `α → β`. It also has a *default definition* which can be
overriden when instantiating `Functor`. Looking at the definition, we see that `mapConst b` is the
same as `map (fun _ => b)`.

So `mapConst` is really about *replacing* `α`(-s) rather than *mapping*, *i.e.* looking at the `α`
value(s) and generate something from that. We can see `mapConst` as a more specific `map` operation
for which you might be able to write a faster implementation.

You don't have to since `mapConst` has a default definition relying on `map`. In fact, all `Functor`
instances shown in this section used Lean 4's `Functor`, not the simplified version we gave at the
beginning, and we never had to define `mapConst` because of the default definition.



## Outro

You're now a functor master, congratz. You're still a monad noob 😿 but we're working on it. Next we
will discuss *applicatives*, which build on functors, and right after that we'll finally get into
*monads*. Hopefully this will be easy thanks to the solid practice and intuition on functor and
applicatives.



[functor]: https://leanprover-community.github.io/mathlib4_docs/Init/Prelude.html#Functor
[`List`]: https://leanprover-community.github.io/mathlib4_docs/Init/Prelude.html#List
[`Option`]: https://leanprover-community.github.io/mathlib4_docs/Init/Prelude.html#Option
[`List.map`]: https://leanprover-community.github.io/mathlib4_docs/Init/Data/List/Basic.html#List.map
[`Option.map`]: https://leanprover-community.github.io/mathlib4_docs/Init/Data/Option/Basic.html#Option.map