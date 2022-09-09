import HaskellMonads.Init

/-!
# Part 5: State Monads

This version does not care about proving anything. We will rely on `List.get!` quite a bit.
-/



macro ll:term ".[" row:term ", " col:term "]" : term =>
  `(List.get! $ll $row |>.get! $col)



--- An index in the 3x3 grid.
structure Idx where
  row : Nat
  col : Nat
deriving Inhabited



--- Either `X` or `O`.
inductive Player
| X
| O
deriving BEq, Inhabited

instance : ToString Player where
  toString
  | Player.X => "X"
  | Player.O => "O"

def Player.switch : Player → Player
| X => O
| O => X



inductive Winner
| is : Player → Winner
| draw



--- Tile state, either empty or marked by `X` or `O`.
inductive Tile
| empty
| has : Player → Tile
deriving BEq, Inhabited

instance : ToString Tile where
  toString
  | Tile.empty => " "
  | Tile.has p => toString p

--- True if the tile is empty.
def Tile.isEmpty : Tile → Bool
| empty => true
| has _ => false
--- True if the tile is **not** empty.
def Tile.isNotEmpty : Tile → Bool :=
  not ∘ Tile.isEmpty
def Tile.toPlayer : Tile → Option Player
| empty => none
| has p => p



--- Stores the board's rows as a list of list of `Tile`s.
structure Board where
  rows : List (List Tile)

def Board.rotate (b : Board) : Board :=
  let src :=
    b.rows
  let (r₀, r₁, r₂) :=
    (src.get! 0, src.get! 1, src.get! 2)
  ⟨[
    [ r₀.get! 0, r₁.get! 0, r₂.get! 0 ],
    [ r₀.get! 1, r₁.get! 1, r₂.get! 1 ],
    [ r₀.get! 2, r₁.get! 2, r₂.get! 2 ]
  ]⟩

def Board.get! (idx : Idx) (b : Board) : Tile :=
  b.rows.get! idx.row
  |>.get! idx.col

def Board.set! (idx : Idx) (p : Player) (b : Board) : Board :=
  -- retrieve row
  b.rows.get! idx.row
  -- set tile
  |>.set idx.col (Tile.has p)
  -- update row
  |> b.rows.set idx.row
  -- reconstruct board
  |> Board.mk

protected def Board.listWinner? (l : List Tile) : Option Player :=
  l.homogeneousSuchThat Tile.toPlayer

protected def Board.listListWinner? (l : List (List Tile)) : Option Player :=
  match l.filterMap Board.listWinner? with
  | [] => none
  | w :: _ => some w


def Board.rowWinner? (b : Board) : Option Player :=
  Board.listListWinner? b.rows

def Board.colWinner? (b : Board) : Option Player :=
  b.rotate.rowWinner?

def Board.diags (b : Board) : List (List Tile) :=
  let src :=
    b.rows
  [
    [ src.[0, 0], src.[1, 1], src.[2, 2] ],
    [ src.[0, 2], src.[1, 1], src.[2, 0] ]
  ]

def Board.diagWinner? (b : Board) : Option Player :=
  Board.listListWinner? b.diags

def Board.winner? (b : Board) : Option Player :=
  b.rowWinner?
  |>.unwrapOrTry fun () => b.colWinner?
  |>.unwrapOrTry fun () => b.diagWinner?

def Board.hasEmptyTiles (b : Board) : Bool :=
  b.rows.any
    fun row =>
      row.any Tile.isEmpty

def Board.emptyTiles (b : Board) : List Idx :=
  -- Extracts the indices of the empty tiles in `row`.
  let emptyColsOf (rowIdx : Nat) (row : List Tile) : List Idx :=
    row.foldl
      -- Accumulator: `row`/`col` indices and result list `acc`.
      (fun ((row, col), acc) tile =>
        let acc :=
          match tile with
          | Tile.empty => ⟨row, col⟩ :: acc
          | _ => acc
        ((row, col + 1), acc)
      )
      -- Starting from current row index, 0-column index, and empty result list.
      ((rowIdx, 0), [])
    |>.snd
  -- Increment `rowIdx` at each step, gathering empty tiles indices.
  b.rows.foldl
    -- Accumulator: row index and result list `acc`.
    (fun (rowIdx, acc) row =>
      let acc :=
        match emptyColsOf rowIdx row with
        | [] => acc
        | list => list ++ acc
      (rowIdx + 1, acc)
    )
      -- Starting from 0-row index, and empty result list.
    (0, [])
  |>.snd



structure State where
  board : Board
  current : Player
  rng : Rng

def State.isDone (s : State) : Option Winner :=
  match s.board.winner? with
  | none =>
    if s.board.hasEmptyTiles then
      none
    else
      Winner.draw
  | some p =>
    Winner.is p

-- --- Returns the winner if the game is over.
-- def State.winner? 

-- --- Generates a random integer strictly less than `ubound` from the current state.
-- def State.randFin
--   (ubound : Nat)
--   (legal : ubound > 0 := by simp [*])
--   : StateM State (Fin ubound)
-- :=
--   do
--     let state ← get
--     let (fin, rng) :=
--       state.rng.fin ubound
--     let state : State :=
--       ⟨state.board, state.current, rng⟩
--     set state
--     return fin

-- def State.nextMove : StateM State Unit :=
--   do
--     let state ←
--       get
--     let empties :=
--       state.board.emptyTiles
--     if lenGt0 : empties.length > 0
--     then
--       let (move, state) ←
--         state.randFin empties.length
--       let idx :=
--         empties.get move
--       let board :=
--         state.board.set! idx state.current
--       State.mk
--         board
--         state.current.switch
--         state.rng
--       |> set
--     else
--       return ()

def State.applyMove
  (idx : Idx)
  : StateM State Unit
:=
  do
    let state ← get
    let board :=
      state.board.set! idx state.current
    set $ State.mk
      board
      state.current.switch
      state.rng

def State.randNat
  (ubound : Nat)
  : StateM State Nat
:=
  do
    let state ← get
    let (n, rng) :=
      state.rng.next
    set $ State.mk
      state.board
      state.current
      rng
    return n % ubound

def State.randMove : StateM State Idx :=
  do
    let empties :=
      (←get).board.emptyTiles
    if empties.length > 0
    then
      let move ←
        State.randNat empties.length
      return empties.get! move
    else
      panic! "board is full, cannot perform moves anymore"

def State.randTurn : StateM State (Option Winner) :=
  do
    let idx ←
      State.randMove
    State.applyMove idx
    return (←get).isDone


def State.show (s : State) : IO Unit :=
  do
    let src :=
      s.board.rows
    IO.println s!"|---|---|---|"
    IO.println s!"| {src.[0, 0]} | {src.[0, 1]} | {src.[0, 2]} |"
    IO.println s!"|---|---|---|"
    IO.println s!"| {src.[1, 0]} | {src.[1, 1]} | {src.[1, 2]} |"
    IO.println s!"|---|---|---|"
    IO.println s!"| {src.[2, 0]} | {src.[2, 1]} | {src.[2, 2]} |"
    IO.println s!"|---|---|---|"

    -- IO.println s!"|"
    -- IO.println s!"├──[     rowWinner: {s.board.rowWinner?} ]"
    -- IO.println s!"├──[     colWinner: {s.board.colWinner?} ]"
    -- IO.println s!"├──[    diagWinner: {s.board.diagWinner?} ]"
    -- IO.println s!"└──[ hasEmptyTiles: {s.board.hasEmptyTiles} ]"

    IO.println ""
    IO.println ""


protected partial def State.randLoop (state : State) : IO (Winner) :=
  do
    let (winner?, state) :=
      StateT.run State.randTurn state
    state.show
    if let some winner := winner?
    then return winner
    else State.randLoop state

def State.randRun : IO Unit :=
  let e :=
    Tile.empty
  let state :=
      Rng.mk 666
      |> State.mk
        ⟨[
          [e, e, e],
          [e, e, e],
          [e, e, e]
        ]⟩
        Player.X
  do
    state.show
    let res ←
      State.randLoop state
    match res with
    | Winner.draw =>
      IO.println "no one won, as usual"
    | Winner.is p =>
      IO.println s!"player `{p}` won"
