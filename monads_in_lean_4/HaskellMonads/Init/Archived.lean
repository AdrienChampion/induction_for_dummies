


-- def Fin.cons
--   {head : α}
--   {tail : List α}
--   (finTail : Fin tail.length)
--   : Fin (head :: tail).length
-- := ⟨
--   ↑finTail + 1,
--   by
--     simp [List.length_cons]
--     let h :=
--       finTail.isLt
--     apply Nat.succ_lt_succ h
-- ⟩


-- def Fin.cons_get
--   {head : α} {tail : List α}
--   (idx : Fin tail.length)
--   :
--     let list := head :: tail
--     (idx' : Fin list.length)
--     ×' list.get idx' = tail.get idx
-- :=
--   let list :=
--     head :: tail
--   let idx' : Fin list.length :=
--     ⟨↑idx + 1, Nat.succ_lt_succ idx.isLt⟩
--   let get_eq : list.get idx' = tail.get idx :=
--     by simp [List.get]
--   ⟨idx', get_eq⟩



-- def Fin.decons
--   {head : α}
--   {tail : List α}
--   (idx : Fin (head :: tail).length)
--   {idx_gt_0 : 0 < ↑idx}
--   : let list := head :: tail
--     (idx' : Fin tail.length) ×' tail.get idx' = list.get idx
-- :=
--   match idxVal : idx.val with
--   | 0 =>
--     by
--       rw [idxVal] at idx_gt_0
--       contradiction
--   | valPrev + 1 =>
--     let isLt : valPrev < tail.length :=
--       by
--         apply Nat.lt_of_succ_lt_succ
--         rw [←idxVal, ←List.length_cons head]
--         exact idx.isLt
--     let idx' : Fin tail.length :=
--       ⟨valPrev, isLt⟩
--     let get_eq : tail.get idx' = (head :: tail).get idx :=
--       by
--         simp [List.get]
--         rw [
--           ←List.get_cons_succ
--             (a := head)
--             (as := tail)
--             (h := by rw [Nat.add_one , ←idxVal] ; exact idx.isLt),
--         ]
--         simp [Nat.add_one]
--         unfold List.get
--         rw [Nat.add_one, ←idxVal]
--         conv =>
--           left
--           unfold List.get
--         cases valPrev
--         simp
--         sorry
--         sorry
--     ⟨idx', get_eq⟩