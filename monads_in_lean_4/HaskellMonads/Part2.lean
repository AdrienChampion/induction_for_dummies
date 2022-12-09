import HaskellMonads.Init

import HaskellMonads.Part1

/-!
# Part 2: Applicative Functors

- <https://mmhaskell.com/monads/applicatives>
-/



namespace Part2Applicative
-- ANCHOR: applicative
/-- An applicative (functor), somewhat similar to Lean's definition.

This is only illustrative, in the following we use Lean's definition directly.
-/
class Applicative (App : Type u → Type v) where
  pure : α → App α
  seq (f? : App (α → β)) (getA? : Unit → App α) : App β
-- ANCHOR_END: applicative

-- ANCHOR: applicative_map
--- Defining a functor-`map` from an `Applicative`.
def Applicative.map
  {App : Type u → Type v}
  [Applicative App]
  (f : α → β)
  (a? : App α)
: App β :=
  let f? := pure f
  let getA? _ := a?
  seq f? getA?
-- ANCHOR_END: applicative_map
end Part2Applicative



--! # `Opt`
section Opt

-- ANCHOR: opt_applicative
instance instApplicativeOpt : Applicative Opt where
  pure a :=
    som a
  seq f? getA? :=
    if let som f := f?
    then f <$> getA? () -- same as `Functor.map f (getA? ())`
    else non

-- `seq` has an associated infix operator: `<*>`
example : som (· + 1) <*> som 3 = som 4
:= rfl
-- ANCHOR_END: opt_applicative

-- ANCHOR: opt_examples
example : non <*> som 7 = (non : Opt Nat)
:= rfl
example : som (· + 1) <*> non = (non : Opt Nat)
:= rfl
example : som (· + 1) <*> som 7 = som 8
:= rfl
-- ANCHOR_END: opt_examples

end Opt



--! # `Lst`
section Lst

-- ANCHOR: lst_def
--- A plain ol' list.
inductive Lst (α : Type u)
--- Empty list.
| leaf : Lst α
--- An `α` and a tail of `α`-s.
| node : α → Lst α → Lst α
deriving Repr, BEq

-- Fancy notation for [`Lst`] construction.
infixr:68 " ::: " => Lst.node
-- Fancy notation for an empty [`Lst`].
notation "[]" => Lst.leaf

--- String representation assuming `ToString α`.
def Lst.toString [ToString α] (self : Lst α) : String :=
  s!"[{inner true self}]"
where
  inner (first : Bool) : Lst α → String
    | leaf => ""
    | head ::: tail =>
      let sep :=
        if first then "" else ", "
      s!"{sep}{head}{inner false tail}"

instance instToStringLst [ToString α] : ToString (Lst α) where
  toString := Lst.toString

#eval
  let val := "I" ::: "<heart>" ::: "catz" ::: []
  s!"an Lst value: {val}"
--> yields `"an Lst value: [I, <heart>, catz]"`

--- Concatenation of two lists.
def Lst.append : Lst α → Lst α → Lst α
  | [], lft =>
    lft
  | head:::tail, lft =>
    let tail := tail.append lft
    head:::tail

--- Gives access to `lft ++ rgt` notation.
instance instHAppendLst : HAppend (Lst α) (Lst α) (Lst α) where
--                                ^^lft^^ ^^rgt^^ ^^out^^
  hAppend := Lst.append

example :
  let lft := "I":::[]
  let rgt := "<heart>":::"catz":::[]
  lft ++ rgt = "I":::"<heart>":::"catz":::[]
:= rfl
-- ANCHOR_END: lst_def

-- ANCHOR: lst_map
def Lst.map (f : α → β) : Lst α → Lst β
  | leaf => leaf
  | head ::: tail =>
    let head := f head     -- `map` head
    let tail := tail.map f -- recursively `map` the tail
    head ::: tail

example : (0:::1:::2:::3:::[]).map (· * 2) = (0:::2:::4:::6:::[])
:= rfl
-- ANCHOR_END: lst_map

--ANCHOR: lst_pure_seq
def Lst.pure : α → Lst α :=
  (· ::: [])
def Lst.seq : Lst (α → β) → (Unit → Lst α) → Lst β
  | [], _ => []
  | f ::: fs, getAs =>
    -- apply `f` to all elements of `as`
    let mapped := getAs () |>.map f
    let mapped_tail := fs.seq getAs
    mapped ++ mapped_tail
--ANCHOR_END: lst_pure_seq

-- ANCHOR: lst_applicative
instance instApplicativeLst : Applicative Lst where
  pure := Lst.pure
  seq := Lst.seq

example :
--vv `id`entity: `fun input => input` a.k.a. `(·)`
  id:::(· + 1):::(· + 2):::[]
    <*> 0:::[]
  =
  0:::1:::2:::[]
:= rfl

example :
  (s!"f₀ {·}"):::(s!"f₁ {·}"):::(s!"f₂ {·}"):::[]
    <*> 0:::1:::[]
  =
  "f₀ 0":::"f₀ 1":::"f₁ 0":::"f₁ 1":::"f₂ 0":::"f₂ 1":::[]
:= rfl
-- ANCHOR_END: lst_applicative

end Lst



example : (4 * ·) <$> some 5 = some 20 :=
  rfl
example : (4 * ·) <$> none = none :=
  rfl

example : pure (4 * ·) <*> some 5 = some 20 :=
  rfl
example : pure (4 * ·) <*> none = none :=
  rfl

example : pure Nat.mul <*> some 4 <*> some 5 = some 20 :=
  rfl
example : pure Nat.mul <*> none <*> some 5 = none :=
  rfl
example : pure Nat.mul <*> some 4 <*> none = none :=
  rfl


-- instance : Pure List where
--   pure a := [a]
-- instance : Seq List where
--   seq {α β} (funs : List (α → β)) (getList : Unit → List α) :=
--     let list := getList ()
--     let rec loop acc : List (α → β) → List β
--       | f :: funs =>
--         let acc := acc ++ list.map f
--         loop acc funs
--       | [] =>
--         acc
--     loop [] funs

-- #check pure (4 * ·) <*> [1, 2, 3]
-- #eval [(1 + ·), (5 * ·), (10 * ·)] <*> [1, 2, 3]



-- structure List.AppZip (α : Type u) :=
--   data : List α
-- deriving Repr

-- def List.toAppZip : List α → AppZip α :=
--   AppZip.mk

-- instance : Coe (List α) (List.AppZip α) where
--   coe := List.AppZip.mk

-- instance : Pure List.AppZip where
--   pure a := ⟨[a]⟩
-- instance : Seq List.AppZip where
--   seq {α β} (funs : List.AppZip (α → β)) (getList : Unit → List.AppZip α) :=
--     let rec loop
--       | f :: funs, head :: tail => (f head) :: loop funs tail
--       | [], _ | _, [] => []
--     getList ()
--     |>.data
--     |> loop funs.data
--     |> List.AppZip.mk


-- #eval [(1 + ·), (5 * ·), (10 * ·)] <*> [1, 2, 3]
-- #eval [(1 + ·), (5 * ·), (10 * ·)].toAppZip <*> [5, 10, 15]
