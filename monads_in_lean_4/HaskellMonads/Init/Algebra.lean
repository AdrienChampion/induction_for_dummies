/-!
# Algebra Stuff

- <https://leanprover-community.github.io/mathlib4_docs/Mathlib/Algebra/Group/Defs.html#Monoid>
-/

class Magma (α : Type u)
where
  law : α → α → α

infixl:75 " +ₘ " => Magma.law
infixl:75 " *ₘ " => Magma.law

class Neutral (α : Type u)
where
  neutral : α

notation:60 " 0ₘ " => Neutral.neutral
notation:60 " 1ₘ " => Neutral.neutral

class Semigroup (α : Type u)
extends
  Magma α
where
  law_assoc : ∀ (a b c : α), a +ₘ b +ₘ c = a +ₘ (b +ₘ c)

class Monoid (α : Type u)
extends
  Semigroup α,
  Neutral α
where
  law_neutral : ∀ (a : α), a +ₘ neutral = a
  neutral_law : ∀ (a : α), neutral +ₘ a = a



instance instAddNeutralNat : Neutral Nat where
  neutral := 0
instance instAddSemigroupNat : Semigroup Nat where
  law_assoc :=
    Nat.add_assoc
instance instAddMonoidNat : Monoid Nat where
  law_neutral :=
    Nat.add_zero
  neutral_law :=
    Nat.zero_add

instance instAppNeutralList : Neutral (List α) where
  neutral := []
instance instAppSemigroupList : Semigroup (List α) where
  law_assoc :=
    List.append_assoc
instance instAppMonoidList : Monoid (List α) where
  law_neutral :=
    List.append_nil
  neutral_law :=
    List.nil_append