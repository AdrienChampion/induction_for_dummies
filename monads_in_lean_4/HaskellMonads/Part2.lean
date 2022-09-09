import HaskellMonads.Init

/-!
# Part 2: Applicative Functors

- <https://mmhaskell.com/monads/applicatives>
-/



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


instance : Pure List where
  pure a := [a]
instance : Seq List where
  seq {α β} (funs : List (α → β)) (getList : Unit → List α) :=
    let list := getList ()
    let rec loop acc : List (α → β) → List β
      | f :: funs =>
        let acc := acc ++ list.map f
        loop acc funs
      | [] =>
        acc
    loop [] funs

#check pure (4 * ·) <*> [1, 2, 3]
#eval [(1 + ·), (5 * ·), (10 * ·)] <*> [1, 2, 3]



structure List.AppZip (α : Type u) :=
  data : List α
deriving Repr

def List.toAppZip : List α → AppZip α :=
  AppZip.mk

instance : Coe (List α) (List.AppZip α) where
  coe := List.AppZip.mk

instance : Pure List.AppZip where
  pure a := ⟨[a]⟩
instance : Seq List.AppZip where
  seq {α β} (funs : List.AppZip (α → β)) (getList : Unit → List.AppZip α) :=
    let rec loop
      | f :: funs, head :: tail => (f head) :: loop funs tail
      | [], _ | _, [] => []
    getList ()
    |>.data
    |> loop funs.data
    |> List.AppZip.mk


#eval [(1 + ·), (5 * ·), (10 * ·)] <*> [1, 2, 3]
#eval [(1 + ·), (5 * ·), (10 * ·)].toAppZip <*> [5, 10, 15]
