namespace book_examples

-- ANCHOR: intro_add_comm1
def add_comm : ∀ (n₁ n₂ : Nat), n₁ + n₂ = n₂ + n₁ :=
  Nat.add_comm
-- ANCHOR_END: intro_add_comm1

-- ANCHOR: intro_add_comm2
def add_comm₁ : (n₁ n₂ : Nat) → n₁ + n₂ = n₂ + n₁ :=
  Nat.add_comm
-- ANCHOR_END: intro_add_comm2

-- ANCHOR: intro_add_comm3
def add_comm₂ (n₁ n₂ : Nat) : n₁ + n₂ = n₂ + n₁ :=
  Nat.add_comm n₁ n₂
-- ANCHOR_END: intro_add_comm3

-- ANCHOR: monad_class
class Monad (Mon : Type → Type) where
  pure : {α : Type} → α → Mon α
  bind : {α : Type} → Mon α → (α → Mon β) → Mon β
-- ANCHOR_END: monad_class

-- ANCHOR: option
inductive Option (α : Type) : Type
| none
| some : α → Option α

#check Option
-- Option : Type → Type
#check @Option.none
-- @Option.none : {α : Type} → Option α
#check Option.some
-- Option.some : ?m.486 → Option ?m.486
#check @Option.some
-- @Option.some : {α : Type} → α → Option α
-- ANCHOR_END: option

-- ANCHOR: log
structure Log (α : Type) : Type where
  inner : α
  log : List String

#check @Log.mk
-- @Log.mk : {α : Type} → α → List String → Log α
-- ANCHOR_END: log

-- ANCHOR: example_proof
example : 7 + 5 = 12
:= rfl
example : add_comm = add_comm₁
:= rfl
example : add_comm 5 7 = add_comm₁ 5 7
:= rfl
example : add_comm 5 7 = add_comm₁ 7 5
:= rfl
-- ANCHOR_END: example_proof


-- ANCHOR: type_univ_storing_types
-- regular `structure` storing a function `: α → α`
structure HasTypeParam (α : Type) where
  f : α → α
-- stores a type `α` and a function `: α → α`
structure StoresAType where
  α : Type
  f : α → α
-- ANCHOR_END: type_univ_storing_types

-- ANCHOR: type_univ_use_type1
def mapStoresAType
  (s : StoresAType)
: Option s.α → Option s.α
| Option.none   => Option.none
| Option.some a => Option.some (s.f a)

#check mapStoresAType
-- mapStoresAType : (s : StoresAType) → Option s.α → Option s.α
-- ANCHOR_END: type_univ_use_type1

-- ANCHOR: type_univ_use_type1_alt1
def mapStoresAType'
  (s : StoresAType)
  (opt : Option s.α)
: Option s.α :=
  match opt with
  | Option.none   => Option.none
  | Option.some a => Option.some (s.f a)
-- ANCHOR_END: type_univ_use_type1_alt1

-- ANCHOR: type_univ_use_type1_alt2
def mapStoresAType''
  (s : StoresAType)
: Option s.α → Option s.α :=
  fun opt =>
    match opt with
    | Option.none   => Option.none
    | Option.some a => Option.some (s.f a)
-- ANCHOR_END: type_univ_use_type1_alt2

-- ANCHOR: type_univ_storing_types_check
#check HasTypeParam
-- String : Type
#check StoresAType
-- StoresAType : Type 1
-- ANCHOR_END: type_univ_storing_types_check

-- ANCHOR: type_univ_storing_type1
structure StoresAType1 where
  α : Type 1
  f : α → α
-- ANCHOR_END: type_univ_storing_type1

-- ANCHOR: type_univ_storing_type1_check_lol
#eval 1 + 1
-- 2
-- ANCHOR_END: type_univ_storing_type1_check_lol
-- ANCHOR: type_univ_storing_type1_check
#check StoresAType1
-- StoresAType1 : Type 2
-- ANCHOR_END: type_univ_storing_type1_check

-- ANCHOR: type_univ_storing_typeu
structure StoresATypeU where
  α : Type u
  f : α → α

#check StoresATypeU
-- StoresATypeU : Type (u_1 + 1)
-- ANCHOR_END: type_univ_storing_typeu

namespace Scope
-- ANCHOR: type_univ_storing_typeu_expl
structure StoresATypeU.{u} where
  α : Type u
  f : α → α

#check StoresATypeU
-- StoresATypeU : Type (u_1 + 1)
-- ANCHOR_END: type_univ_storing_typeu_expl
end Scope

-- ANCHOR: type_univ_storing_typeuv
structure StoresTypesUV.{u, v} where
  α : Type u
  β : Type v
  f : α → β

-- ANCHOR: type_univ_storing_typeuv_check
#check StoresTypesUV
-- ANCHOR_END: type_univ_storing_typeuv
-- StoresTypesUV : Type (max (u_1 + 1) (u_2 + 1))
-- ANCHOR_END: type_univ_storing_typeuv_check

namespace Scope
-- ANCHOR: type_univ_storing_typeuv_expl
structure StoresTypesUVToo.{u, v} : Type (max u v + 1) where
  α : Type u
  β : Type v
  f : α → β

#check StoresTypesUVToo
-- StoresTypesUVToo : Type ((max u_1 u_2) + 1)
-- ANCHOR_END: type_univ_storing_typeuv_expl
end Scope

end book_examples