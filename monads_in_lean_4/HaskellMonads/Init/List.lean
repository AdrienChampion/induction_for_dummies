import HaskellMonads.Init.Basic



/-!
# Helpers for `List`
-/



namespace List
  protected def homogeneousSuchThatAux
    [BEq α]
    (prev : α)
    (res : β)
    : List α → Option β
  | [] => some res
  | a :: tail =>
    if a == prev
    then
      List.homogeneousSuchThatAux prev res tail
    else
      none

  --- Returns `some a` if the non-empty list only contains `a` and `filter a` is false.
  def homogeneousSuchThat
    [BEq α]
    (filterMap : α → Option β)
    : List α → Option β
  | [] =>
    none
  | head :: tail =>
    match filterMap head with
    | none =>
      none
    | some res =>
      List.homogeneousSuchThatAux head res tail
end List




-- --- Gathers a value from `list`, its index, and a proof that the value has the correct index in
-- --- `list`.
-- protected structure List.IdxElm (list : List α) where
--   val : α
--   idx : Fin list.length
--   get_idx_eq_val : list.get idx = val

-- --- Coercion from `List.IdxElm` to its inner `val`ue.
-- instance (list : List α) : Coe (List.IdxElm list) α where
--   coe self := self.val



-- --- Transposes a `List.IdxElm` for a `tail` to `head :: tail`.
-- theorem List.IdxElm.idx_cons
--   {head : α}
--   {tail : List α}
--   (elmIdx : List.IdxElm tail)
--   : (elmIdx' : List.IdxElm (head :: tail)) ×' elmIdx'.val = elmIdx.val
-- :=
--   let list := head :: tail
--   let ⟨idx', val_eq⟩ :=
--     elmIdx.idx.cons_get (head := head)
--   let get_idx_eq_val : list.get idx' = elmIdx.val :=
--     by
--       rw [←elmIdx.get_idx_eq_val]
--       apply val_eq
--   ⟨⟨elmIdx.val, idx', get_idx_eq_val⟩, by simp⟩



-- theorem List.IdxElm.cons_idx
--   {head : α}
--   {tail : List α}
--   (elmIdx' : List.IdxElm (head :: tail))
--   (val_gt_0 : 0 < ↑elmIdx'.idx)
--   : (elmIdx : List.IdxElm tail) ×' elmIdx.val = elmIdx'.val
-- :=
--   let idxPrev : Fin tail.length :=
--     elmIdx.idx.decons (fin_gt_0 := val_gt_0)
--   let get_idx_eq_val : tail.get idxPrev = elmIdx.val :=
--     by
--       simp [Fin.decons]
--       cases elmIdx.idx.val with
--       | zero =>
--         contradiction
--       | succ valPrev =>
--         sorry
--   by
--     sorry
  



-- def List.indexed
--   (list : List α)
--   : List (α × Fin list.length)
-- :=
--   match listDef: list with
--   | [] => []
--   | head :: tail =>
--     let sub : List (α × Fin (head :: tail).length) :=
--       tail.indexed
--       |>.map
--         fun (a, idx) =>
--           (a, idx.cons_lift)
--     let idx : Fin list.length := ⟨
--       0,
--       by
--         rw [listDef, List.length_cons]
--         apply Nat.zero_lt_succ
--     ⟩
--     by
--       rw [listDef] at idx
--       apply (head, idx) :: sub

-- def List.indexBump
--   (tail : List α)


-- --- Lemmas over `List.indexed`.
-- section indexed_lemmas
--   def List.indexed_cons
--     (head : α)
--     (tail : List α)
--     ()
--     : List (α × Fin (head :: tail).length)
--   :=

-- end indexed_lemmas

-- theorem List.indexed_post_step
--   (tail : List α)
--   (head : α)
--   (elm : List.IdxElm tail)
--   : List.IdxElm (head :: tail)
-- :=
--   let idx : Fin (head :: tail).length :=
--     elm.idx.cons_lift
--   let get_idx_eq_a : (head :: tail).get idx = elm.a :=
--     by
--       rw [←elm.get_idx_eq_a]
--       apply List.get_cons_succ
--   ⟨elm.a, idx, get_idx_eq_a⟩

-- theorem List.indexed_post
--   (list : List α)
--   (res : List (α × Fin list.length))
--   (resDef : res = list.indexed)
--   : List (List.IdxElm list)
-- :=
--   by
--     unfold indexed at resDef
--     cases list with
--     | nil =>
--       exact []
--     | cons head tail =>
--       simp [Eq.mp] at resDef
--       let ih := tail.indexed_post
--       sorry



-- protected def List.idxFilterMapRevAux
--   (max : Nat)
--   (finAcc : Fin max)
--   (listAcc : List β)
--   (filterMap : Fin max → α → Option β)
--   (l : List α)
--   : List β
-- :=
--   match l with
--   | [] =>
--     panic!
--       "illegal empty list, you're not supposed to call this function "
--       ++ "unless you know what you're doing"
--   | head :: tail =>
--     let listAcc :=
--       Id.run $ do
--         if let some b ← filterMap finAcc head
--         then b :: listAcc
--         else listAcc
--     let idxInc :=
--       ↑finAcc + 1
--     if idxIncLegal : idxInc < max
--     then
--       List.idxFilterMapRevAux
--         max
--         ⟨idxInc, idxIncLegal⟩
--         listAcc
--         filterMap
--         tail
--     else
--       listAcc

-- def List.idxFilterMapRev
--   (list : List α)
--   (_filterMap :
--     (idx : Fin list.length)
--     → (elm : α)
--     → list.get idx = elm
--     → Option β
--   )
--   : List β
-- :=
--   match h : list with
--   | head :: tail =>
--     let finZero : Fin list.length := ⟨
--       0,
--       by
--         rw [h, List.length_cons head tail]
--         apply Nat.zero_lt_succ tail.length
--     ⟩
--     List.idxFilterMapRevAux
--       list.length
--       finZero
--       []

--       (
--         by rw [h] apply _filterMap
--       )
--       list
--   | [] => []

-- def List.idxFilterMapRev₂

--   (list : List α)
--   (_filterMap : (l : List α) → Fin l.length → α → Option β)
--   : List β
-- :=
--   match h : list with
--   | head :: tail =>
--     let finZero : Fin list.length := ⟨
--       0,
--       by
--         rw [h, List.length_cons head tail]
--         apply Nat.zero_lt_succ tail.length
--     ⟩
--     List.idxFilterMapRevAux
--       list.length
--       finZero
--       []
--       (
--         by rw [h] apply _filterMap
--       )
--       list
--   | [] => []