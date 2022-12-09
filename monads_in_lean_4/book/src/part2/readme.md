# Applicative Functors

> *Monads in Haskell* original post:
>
> - <https://mmhaskell.com/monads/applicatives>

<br>





### `List` as a `Functor`

Let's define some lists and a few functions:

```lean
{{ #include ../../../HaskellMonads/Part1.lean:list_defs }}
```

<br>

A *map* of a function `f` over a list `l` creates a new list containing the result of applying `f`
to each element of `l`. [`List.map`] is the map function over lists, let's use that as our
`Functor.map`

```lean
{{ #include ../../../HaskellMonads/Part1.lean:list_functor }}
```

and check that it does what it's supposed to

```lean
{{ #include ../../../HaskellMonads/Part1.lean:list_examples }}
```

<br>

Notice how the `List` structure is preserved. Whatever function `f` we *map* over some list `l`, the
result will have the same number of elements as `l`; also, each application of `f` appears in the
same order in the result as does its argument in `l`.