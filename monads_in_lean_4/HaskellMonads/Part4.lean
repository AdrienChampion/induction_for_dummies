import HaskellMonads.Init



/-!
# Part 4: Reader and Writer Monads
-/

structure Env where
  param₁ : String
  param₂ : String
  param₃ : String

def Env.load : IO Env :=
  pure ⟨"one", "two", "three"⟩



/-
## Simulating Global Variables
-/

def Env.func₁₁ (env : Env) : Float :=
  env.param₁.length
  + env.param₂.length * 2
  + env.param₃.length * 3
  |>.toFloat
  |>.mul 2.1

def Env.func₁₂ (env : Env) : Nat :=
  2 + env.func₁₁.toNat

def Env.func₁₃ (env : Env) : String :=
  s! "Result: `{env.func₁₂}`"

def main₁ : IO Unit :=
  do
    let env ← Env.load
    IO.println s!"{env.func₁₃}"



/-
## Reader Monad
-/


def Env.func₂₁ : Env → Float :=
  Env.func₁₁

def Env.func₂₂ : ReaderM Env Nat :=
  do
    let env ← ReaderT.read
    2 + env.func₂₁.toNat
    |> pure

def Env.func₂₃ : ReaderM Env String :=
  do
    pure s! "Result: `{← Env.func₂₂}`"

def main₂ : IO Unit :=
  do
    let env ← Env.load
    IO.println s!"{env.func₂₃}"



/-
## Accumulating Values
-/

def func₁₁ (pair : Int × String) : Int × String :=
  let (prev, input) := pair
  if input.length < 10
  then (prev + input.length, input ++ input)
  else (prev + 5, input.take 5)

def func₁₂ (pair : Int × String) : Int × String :=
  let (prev, input) := pair
  if input.length > 10
  then func₁₁ (prev + 1, input.take 9)
  else (10, input)

def func₁₃ (pair : Int × String) : Int × String :=
  let (prev, input) := pair
  if input.length % 3 = 0
  then
    let (subPrev, subInput) := func₁₂ (prev, input ++ "ab")
    (prev + subPrev, subInput)
  else
    (prev + 1, input.tail)

def func₁₄ (input : String) : Int × String :=
  if input.length % 2 = 0
  then func₁₃ (0, input)
  else
    let (i₁, str₁) := func₁₃ (0, input.tail)
    let (i₂, str₂) := func₁₁ (0, input.take 1)
    (i₁ + i₂, str₁ ++ str₂)



/-
## Tracking the Accumulator with `Writer`

- <https://leanprover-community.github.io/mathlib4_docs/Mathlib/Control/Writer.html#WriterT>

acc3' :: String -> Writer Int String
acc3' input = if (length input) `mod` 3 == 0
  then do
    tell 3
    acc2' (input ++ "ab")
  else do
    tell 1
    return $ tail input
-/

def func₂₁ (input : String) : Writer Nat String :=
  do
    if input.length < 10
    then
      tell input.length
      return (input ++ input)
    else
      tell 5
      return (input.take 5)

def func₂₂ (input : String) : Writer Nat String :=
  do
    if input.length > 10
    then
      tell 1
      input.take 9 |> func₂₁
    else
      tell 10
      return input

def func₂₃ (input : String) : Writer Nat String :=
  do
    if input.length % 3 = 0
    then
      tell 3
      func₂₂ (input ++ "ab")
    else
      tell 1
      return input.tail
-- acc1' input = if length input `mod` 2 == 0
--   then runWriter (acc2' input)
--   else runWriter $ do
--     str1 <- acc3' (tail input)
--     str2 <- acc4' (take 1 input)
--     return (str1 ++ str2)
def func₂₄ (input : String) : String × Nat :=
  if input.length % 2 = 0
  then
    func₂₂ input
    |>.run.run
  else
    Id.run
    $ Writer.run
    $ do
        let str₁ ← func₂₃ input.tail
        let str₂ ← func₂₁ (input.take 1)
        return (str₁ ++ str₂)
