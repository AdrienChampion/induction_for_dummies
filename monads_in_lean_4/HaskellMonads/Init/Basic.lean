import Lean.Data.HashMap

/-!
# Useful Types and Helpers
-/



def String.mem (c : Char) (s : String) : Bool :=
  s.any (· == c)



def IO.readLine : IO String :=
  do
    (←IO.getStdin).getLine


def Option.unwrapOrTry (default : Unit → Option α) : Option α → Option α
| some a => a
| none => default ()



def String.tail (s : String) :=
  s.drop 1


--- Copied from mathlib 4.
@[simp]
theorem List.get_cons_succ
  {a : α}
  {as : List α}
  {h : i + 1 < (a :: as).length}
  : (a :: as).get ⟨i+1, h⟩
  = as.get ⟨i, Nat.lt_of_succ_lt_succ h⟩
:=
  rfl



abbrev HMap α [BEq α] [Hashable α] β :=
  Std.HashMap α β

namespace HMap
  def empty := @Std.HashMap.empty
  def ofList := @Std.HashMap.ofList

  def mapValues
    [BEq α] [Hashable α]
    (f : β → γ) (self : HMap α β)
    : HMap α γ
  :=
    let rec loop (acc : HMap α γ) : List (α × β) → HMap α γ
      | (key, val) :: tail =>
        let acc :=
          f val |> acc.insert key
        loop acc tail
      | [] => acc
    loop empty self.toList
end HMap



namespace Float
  def dotSplit (f : Float) : Nat × Nat :=
    match
      f.toString.splitOn "."
      |>.map String.toNat?
    with
    | [some nat, some dec] => (nat, dec)
    | [some nat, none] => (nat, 0)
    | _ => panic! s!"unreachable branch reached on input `{f}`"
  
  def toNat (f : Float) : Nat :=
    f.dotSplit.1
end Float



inductive Either (α : Type u) (β : Type v)
  | left : α → Either α β
  | right : β → Either α β
deriving Repr

def lfail : String → Either String β :=
  Either.left

def Either.lmap (f : α₁ → α₂) : Either α₁ β → Either α₂ β
  | left a => f a |> left
  | right b => right b
def Either.lbind (f : α₁ → Either α₂ β) : Either α₁ β → Either α₂ β
  | left a => f a
  | right b => right b

def Either.rmap (f : β₁ → β₂) : Either α β₁ → Either α β₂
  | left a => left a
  | right b => f b |> right
def Either.rbind (f : β₁ → Either α β₂) : Either α β₁ → Either α β₂
  | left a => left a
  | right b => f b

section EitherMonad
  instance : Pure (Either α) where
    pure := Either.right

  instance : Functor (Either α) where
    map := Either.rmap

  instance : Seq (Either α) where
    seq eitherFun getEither :=
      match eitherFun with
      | Either.right f => getEither () |>.rmap f
      | Either.left a => Either.left a

  instance : SeqLeft (Either α) where
    seqLeft either getOther :=
      match either with
      | Either.right res =>
        match getOther () with
        | Either.left a =>
          Either.left a
        | Either.right _ =>
          Either.right res
      | Either.left err =>
        Either.left err

  instance : SeqRight (Either α) where
    seqRight either getOther :=
      match either with
      | Either.right _ =>
        match getOther () with
        | Either.left a =>
          Either.left a
        | Either.right res =>
          Either.right res
      | Either.left err =>
        Either.left err

  instance : Applicative (Either α) := {}

  instance : Bind (Either α) where
    bind either f := Either.rbind f either
  
  instance : Monad (Either α) := {}
end EitherMonad



--- [Linear congruential generator][wiki] rng.
---
--- [wiki]: https://en.wikipedia.org/wiki/Linear_congruential_generator
structure Rng where
  seed : Nat

def Rng.next (rng : Rng) : Nat × Rng :=
  -- https://en.wikipedia.org/wiki/Linear_congruential_generator#Parameters_in_common_use
  let m := 2147483647
  let a := 2147483629
  let c := 2147483587
  let next := (a * rng.seed + c) % m
  (next, ⟨next⟩)

def Rng.fin
  (rng : Rng)
  (ubound : Nat)
  (legal : ubound > 0 := by simp [*])
  : Fin ubound × Rng
:=
  let (big, rng) := rng.next
  let fin := big % ubound
  (
    ⟨
      fin,
      by
        apply Nat.mod_lt
        apply legal
    ⟩,
    rng
  )
