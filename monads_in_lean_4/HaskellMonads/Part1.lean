import HaskellMonads.Init

/-!
# Part 1: Functors

- <https://mmhaskell.com/monads/functors>
-/



namespace Hidden
-- ANCHOR: functor_class
class Functor (Fct : Type u → Type v) where
  --   v~v~~~~ given two (inferred) types,
  map {α β : Type u} (f : α → β) (a? : Fct α) : Fct β
  --  `f` goes from ~~^           ^^~~~ and `a?` is a `Fct`-wrapped `α`
  --  `α` to `β`
-- ANCHOR_END: functor_class
end Hidden



-- ANCHOR: opt_def
--- Either `non` or `som val`.
inductive Opt (α : Type u)
| non : Opt α
| som : α → Opt α
deriving Repr, BEq
--       ^^^^~~ class allowing Lean to `Repr`esent (display) values, which

-- Make `Opt.non` and `Opt.som` visible for everyone without the `Opt.` bit.
export Opt (non som)

--- String representation assuming `ToString α`.
def Opt.toString [ToString α] : Opt α → String
  | non => "non"
  | som a => s!"som {a}"
--           ^^~~~~~^^^~~~ string interpolation

--- Gives us string interpolation for `Opt` values.
instance instToStringOpt
  {α : Type u}
  [ToString α]
: ToString (Opt α) where
  toString := Opt.toString

-- string interpolation demo
#eval
  let val := som 5
  s!"an `Opt` value: `{val}`"
--> yields "an `Opt` value: `som 5`"
-- ANCHOR_END: opt_def

-- ANCHOR: opt_bad_map
def Opt.badMap (_f : α → β) : Opt α → Opt β
  | non => non
  | som _ => non
-- ANCHOR_END: opt_bad_map

-- ANCHOR: opt_map
def Opt.map (f : α → β) : Opt α → Opt β
  | non => non
  | som a => f a |> som

example : (som 2).map (fun n => n * 3) = som 6
:= rfl
example : non.map (· * 3) = non
:= rfl
-- ANCHOR_END: opt_map

-- ANCHOR: opt_functor
instance instFunctorOpt : Functor Opt where
  map := Opt.map
-- ANCHOR_END: opt_functor

-- ANCHOR: opt_examples
namespace Opt.Examples
  def opt₁ : Opt String :=
    som "cat"
  def opt₂ : Opt Nat :=
    som 11
  def opt₃ : Opt Bool :=
    non

  example : Functor.map String.length opt₁ = som 3
  := rfl
  example : Functor.map (· * 2) opt₂ = som 22
  := rfl
  example : Functor.map ToString.toString opt₃ = non
  := rfl

  -- Special notation for `Functor.map f val`: `f <$> val`, so the examples
  -- above can be rewritten as
  example : String.length <$> opt₁ = som 3
  := rfl
  example : (· * 2) <$> opt₂ = som 22
  := rfl
  example : ToString.toString <$> opt₃ = non
  := rfl

  -- Chaining `map`s.

  example :
    (
      som true
      |> Functor.map ToString.toString
      -- `som "true"`
      |> Functor.map String.length
      -- `som 4`
      |> Functor.map (· * 2)
      -- `som 8`
    )
    = som 8
  := rfl

  -- Same but with `<$>`:
  example :
    (
      -- `som 8`
      (· * 2)
      -- `som 4`
      <$> String.length
      -- `some "true"`
      <$> ToString.toString
      <$> som true
    )
    = som 8
  := rfl

  example :
    (
      (non : Opt Bool)
      |> Functor.map ToString.toString
      -- `non`
      |> Functor.map String.length
      -- `non`
      |> Functor.map (· * 2)
      -- `non`
    )
    = non
  := rfl
end Opt.Examples
-- ANCHOR_END: opt_examples



-- ANCHOR: list_defs
def list₁ : List String :=
  []
def list₂ : List Nat :=
  [1, 2, 3]
def list₃ : List Bool :=
  [true, false, true, false]

def stringLength : String → Nat :=
  String.length
def natMul2 : Nat → Nat :=
  (· * 2)  -- same as `fun n => n * 2`
def boolToStr : Bool → String :=
  toString -- from the `ToString` class
-- ANCHOR_END: list_defs

-- ANCHOR: list_functor
instance : Functor List where
  map := List.map
-- ANCHOR_END: list_functor

-- ANCHOR: list_examples
example : Functor.map stringLength list₁ = []
:= rfl
example : Functor.map natMul2 list₂ = [2, 4, 6]
:= rfl
example : Functor.map boolToStr list₃ = ["true", "false", "true", "false"]
:= rfl

example :
  (
    Functor.map boolToStr list₃
    -- ["true", "false", "true", "false"]
    |> Functor.map stringLength
    -- [4, 5, 4, 5]
    |> Functor.map natMul2
  )
  =
  [ 8, 10, 8, 10 ]
:= rfl
-- ANCHOR_END: list_examples


namespace part1



-- ANCHOR: measurements_def
--- Surface measured in `α`.
structure Measurements (α : Type u) where
  totalSize : α
  numBedrooms : Nat
  masterBedroomSize : α
  livingRoomSize : α
deriving Repr, BEq
-- ANCHOR_END: measurements_def

-- ANCHOR: measurements_convert
--- Converts between area units.
def Measurements.convert
  (conv : α → β)
  (m : Measurements α)
  : Measurements β
where
  totalSize :=
    conv m.totalSize
  numBedrooms :=
    m.numBedrooms
  masterBedroomSize :=
    conv m.masterBedroomSize
  livingRoomSize :=
    conv m.livingRoomSize
-- ANCHOR_END: measurements_convert

-- ANCHOR: measurements_functor
instance : Functor Measurements where
  map := Measurements.convert
-- ANCHOR_END: measurements_functor



-- ANCHOR: measurements_units_def
inductive Meter₂
| meter₂ : Nat → Meter₂
deriving Repr, BEq

-- make constructor `Meter₂.meter₂` accessible as `meter₂`
open Meter₂ (meter₂)
-- instantiate `OfNat` so that we can convert easily from `Nat`
instance : OfNat Meter₂ n where
  ofNat := meter₂ n



inductive Feet₂
| feet₂ : Nat → Feet₂
deriving Repr, BEq

-- make constructor `Feet₂.feet₂` accessible as `feet₂`
open Feet₂ (feet₂)
-- instantiate `OfNat` so that we can convert easily from `Nat`
instance : OfNat Feet₂ n where
  ofNat := feet₂ n
-- ANCHOR_END: measurements_units_def

-- ANCHOR: measurements_units_conv
def Feet₂.toMeter₂ : Feet₂ → Meter₂
| feet₂ ft =>
  ft * 1000 / 10764
  |> meter₂

def Meter₂.toFeet₂ : Meter₂ → Feet₂
| meter₂ m =>
  m * 10764 / 1000
  |> feet₂
-- ANCHOR_END: measurements_units_conv

-- ANCHOR: measurements_examples
def m₁ : Measurements Nat :=
  Measurements.mk 1200 3 200 700
def m₂ : Measurements Nat :=
  Functor.map (· + 10) m₁

example : m₂ = Measurements.mk (1200 + 10) 3 (200 + 10) (700 + 10)
:= rfl

def m₃ : Measurements Meter₂ :=
  Functor.map meter₂ m₂

def m₄ : Measurements Feet₂ :=
  -- same as `Functor.map Feet₂.toMeter₂ m₃`
  Meter₂.toFeet₂ <$> m₃

example : m₄ = Measurements.mk 13024 3 2260 7642
:= rfl

def m₅ : Measurements Meter₂ :=
  Feet₂.toMeter₂ <$> m₄

-- `m₅` is the same as `m₃` with all areas decreased by `1` due to rounding
--                                   vv~ take `m₂`
example : m₅ = (· - 1 |> meter₂) <$> m₂
--             ^^^^^^^^^^^^^^^^^~~~~~~~~ and remove `1` before contructing the `Meter₂`
:= rfl
-- ANCHOR_END: measurements_examples

-- ANCHOR: measurements_examples_alt
example : m₅ = meter₂ <$> (· - 1) <$> m₂
:= rfl
-- ANCHOR_END: measurements_examples_alt


-- ANCHOR: laws
class Functor.Laws
  (Fct : Type u → Type v)
extends
  Functor Fct
where
  functor_identity :
    ∀ (a : Fct α),
      id <$> a = a
  functor_composition :
    ∀ (f : α → β) (g : β → γ),
      map g ∘ map f = map (g ∘ f)
-- ANCHOR_END: laws

-- ANCHOR: laws_proof
instance : Functor.Laws Measurements where
  functor_identity _ :=
    rfl
  functor_composition _ _ :=
    rfl
-- ANCHOR_END: laws_proof


-- ANCHOR: lean_functor
class Functor (f : Type u → Type v) where
  -- same as our simple definition
  map :
    {α β : Type u} → (α → β) → f α → f β
  -- this is new
  mapConst :
    {α β : Type u} → β → f α → f β
  :=
    fun b =>
      map (fun _a => b)
-- ANCHOR_END: lean_functor

namespace laws_cex
-- ANCHOR: laws_cex
instance : Functor Measurements where
  map conv m := {
    totalSize :=
      conv m.totalSize
    numBedrooms :=
      -- OMG 🙀
      m.numBedrooms + 1
    masterBedroomSize :=
      conv m.masterBedroomSize
    livingRoomSize :=
      conv m.livingRoomSize
  }
-- ANCHOR_END: laws_cex
end laws_cex

end part1






def String.words (s : String) : List String :=
  s.splitOn
  |>.filter fun s => !s.isEmpty

def TInfo := String × String × Nat
def TInfo? := Option TInfo

--- If `s` is composed of three whitespace-separated tokens, and the last one is a natural, returns
--- the first two tokens and the last one as a `Nat`.
def String.tuplify
  (s : String)
  : TInfo?
:=
  let words := s.words
  if words.length ≠ 3 then
    none
  else
    match
      words.get? 2
      |>.bind String.toNat?
    with
    | none => none
    | some age =>
      words.get? 0
      |>.bind
        fun fst => words.get? 1 |>.map ((fst, ·, age))


namespace Examples
  def myCat4 := "My Cat 4"
  
  #eval myCat4.tuplify
end Examples

structure Person where
  firstName : String
  lastName : String
  age : Nat
deriving Repr

def Person? := Option Person

def Person.ofTuple (t : TInfo) : Person where
  firstName := t.1
  lastName := t.2.1
  age := t.2.2

def Person.ofTuple? (t : TInfo?) : Person? :=
  t.map Person.ofTuple



def Char.isNewline : Char → Bool
  | '\n' | '\r' => true
  | _ => false

def String.lines (s : String) : List String :=
  s.split Char.isNewline
  |>.filter String.isEmpty

def String.tuplifyLines (s : String) : List TInfo :=
  s.lines
  |>.filterMap String.tuplify



--- Functor version of `Person.ofTuple?`.
def Person.ofTupleFunctor
  [Fun : Functor F]
  : F TInfo → F Person
:=
  Fun.map Person.ofTuple


namespace Examples
  #eval myCat4.tuplify |> Person.ofTupleFunctor
end Examples



structure GovDirectory (α : Type u) where
  mayor : α
  interimMayor : Option α
  cabinet : HMap String α
  councilMembers : List α

instance instFunctorGovDirectory
  : Functor GovDirectory
where
  map f self :=
    ⟨
      f self.mayor,
      self.interimMayor.map f,
      self.cabinet.mapValues f,
      self.councilMembers.map f
    ⟩

namespace Examples
  def oldDirectory : GovDirectory TInfo where
    mayor := ("John", "Doe", 46)
    interimMayor := none
    cabinet := HMap.ofList [
      ("Treasurer", ("Timothy", "Houston", 51)),
      ("Historian", ("Bill", "Jefferson", 42)),
      ("Sheriff", ("Susan", "Harrison", 49))
    ]
    councilMembers := [
      ("Sharon", "Stevens", 38),
      ("Christine", "Washington", 47)
    ]
  
  def newDirectory : GovDirectory Person :=
    Person.ofTupleFunctor oldDirectory
end Examples
