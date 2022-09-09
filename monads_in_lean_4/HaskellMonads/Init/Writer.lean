import HaskellMonads.Init.Algebra

/-!
# Writer Monad

- <https://leanprover-community.github.io/mathlib4_docs/Mathlib/Control/Writer.html>
-/

def WriterT (ω : Type u) (Mon : Type u → Type v) (α : Type u) :=
  Mon (α × ω)

@[reducible]
def Writer (ω : Type u) :=
  WriterT ω Id



class MonadWriter (ω : outParam (Type u)) (Mon : Type u → Type v) where
  tell : ω → Mon PUnit
  listen {α} : Mon α → Mon (α × ω)
  pass {α} : Mon (α × (ω → ω)) → Mon α

export MonadWriter (tell listen pass)



variable
  {Mon : Type u → Type v}
  [Monad Mon]

instance [MonadWriter ω Mon] : MonadWriter ω (ReaderT ρ Mon) where
  tell w := (tell w : Mon _)
  listen x r := listen <| x r
  pass x r := pass <| x r

instance [MonadWriter ω Mon] : MonadWriter ω (StateT σ Mon) where
  tell w :=
    (tell w : Mon _)
  listen x s :=
    (fun ((a, w), s) => ((a, s), w))
    <$> listen (x s)
  pass x s :=
    pass <|
      (fun ((a, f), s) => ((a, s), f))
      <$> (x s)



namespace WriterT

variable
  {α ω : Type u}

def mk (cmd : Mon (α × ω)) : WriterT ω Mon α :=
  cmd

def run (cmd : WriterT ω Mon α) : Mon (α × ω) :=
  cmd

def monad
  (empty : ω)
  (append : ω → ω → ω)
  : Monad (WriterT ω Mon)
where
  map f (cmd : Mon _) :=
    mk
    $ (fun (a, w) => (f a, w)) <$> cmd
  pure a :=
    pure (f := Mon) (a, empty)
  bind (cmd : Mon _) f :=
    mk
    $ cmd >>= (
      fun (a, w₁) =>
        (fun (b, w₂) => (b, append w₁ w₂)) <$> (f a)
    )



/-- Lift an `M` to a `WriterT ω M`, using the given `empty` as the monoid unit. -/
protected def liftTell (empty : ω) : MonadLift Mon (WriterT ω Mon) where
  monadLift cmd :=
    WriterT.mk
    $ (·, empty) <$> cmd



instance [EmptyCollection ω] [Append ω] : Monad (WriterT ω Mon) :=
  monad ∅ (· ++ ·)
instance [EmptyCollection ω] : MonadLift Mon (WriterT ω Mon) :=
  WriterT.liftTell ∅
instance [Monoid ω] : Monad (WriterT ω Mon) :=
  monad Monoid.toNeutral.neutral Monoid.toSemigroup.law
instance [Monoid ω] : MonadLift Mon (WriterT ω Mon) :=
  WriterT.liftTell Monoid.toNeutral.neutral



instance : MonadWriter ω (WriterT ω Mon) where
  tell w :=
    WriterT.mk
    $ pure (⟨⟩, w)
  listen cmd :=
    WriterT.mk
    $ (fun (a, w) => ((a, w), w)) <$> cmd
  pass cmd :=
    WriterT.mk
    $ (fun ((a, f), w) => (a, f w)) <$> cmd

instance [MonadExcept ε Mon] : MonadExcept ε (WriterT ω Mon) where
  throw e :=
    WriterT.mk
    $ throw e
  tryCatch cmd c :=
    WriterT.mk
    $ tryCatch cmd fun e => (c e).run

instance [MonadLiftT Mon (WriterT ω Mon)] : MonadControl Mon (WriterT ω Mon) where
  stM := fun α => α × ω
  liftWith f := liftM <| f fun x => x.run
  restoreM := WriterT.mk

instance : MonadFunctor Mon (WriterT ω Mon) where
  monadMap := fun k (w : Mon _) => WriterT.mk $ k w

end WriterT



def Writer.run := @WriterT.run
