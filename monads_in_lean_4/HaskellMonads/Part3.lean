import HaskellMonads.Init

/-!
# Part 3: Monads
-/

def String.func₁ : String → Option Nat
  | "" => none
  | str => some str.length

def Nat.func₂ (n : Nat) : Option Float :=
  if n % 2 = 0
  then none
  else some (3.14159 * n.toFloat)

def Float.func₃ (f : Float) : Option (List Nat) :=
  if f > 15.0
  then none
  else
    let (num, dec) := f.dotSplit
    pure [num, dec]


def String.runFuncs (str : String) : Option (List Nat) :=
  match str.func₁ with
  | none => none
  | some i =>
    match i.func₂ with
    | none => none
    | some float =>
      float.func₃

def String.runFuncsBind₁ (str : String) : Option (List Nat) :=
  str.func₁
  >>= Nat.func₂
  >>= Float.func₃

def String.runFuncsDo₁ (str : String) : Option (List Nat) :=
  do
    let n ← str.func₁
    let f ← n.func₂
    f.func₃

def String.runFuncsDo₂ (str : String) : Option (List Nat) :=
  do
    let n ← str.func₁
    let f ← n + 2 |>.func₂
    f.func₃

def String.runFuncsBind₂ (str : String) : Option (List Nat) :=
  str.func₁
  >>= (· + 2 |>.func₂)
  -- -- Same as
  -- >>= (λ i => i + 2 |>.func₂)
  >>= Float.func₃



def String.eitherFunc₁ : String → Either String Nat
  | "" => lfail "[String.eitherFunc₁] string cannot be empty"
  | str => str.length |> Either.right

def Nat.eitherFunc₂ (n : Nat) : Either String Float :=
  if n % 2 = 0
  then lfail s!"[Nat.eitherFunc₂] input `{n}` cannot be even"
  else pure (3.14159 * n.toFloat)

def Float.eitherFunc₃ (f : Float) : Either String (List Nat) :=
  if f > 15.0
  then lfail s!"[Float.eitherFunc₃] float `{f}` is too large"
  else
    let (num, dec) := f.dotSplit
    pure [num, dec]

def String.runEitherFuncs (s : String) : Either String (List Nat) :=
  do
    let i ← s.eitherFunc₁
    let f ← i.eitherFunc₂
    f.eitherFunc₃


namespace Examples
  example :
    "".runEitherFuncs
    =
    lfail "[String.eitherFunc₁] string cannot be empty"
  :=
    rfl

  example :
    "hi".runEitherFuncs
    =
    lfail "[Nat.eitherFunc₂] input `2` cannot be even"
  :=
    rfl

  example :
    "this is too long".runEitherFuncs
    =
    lfail "[Nat.eitherFunc₂] input `16` cannot be even"
  :=
    rfl

  #eval "hit".runEitherFuncs
end Examples


/-
# IO Monad
-/

namespace NotMain
  def main : IO Unit :=
    do
      let stdin ← IO.getStdin
      IO.println "please write something:"
      let line ← stdin.getLine
      let lineUpper := line.toUpper
      IO.println s!"upper case version: `{lineUpper}`"
end NotMain