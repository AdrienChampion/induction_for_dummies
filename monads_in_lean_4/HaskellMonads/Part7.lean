import HaskellMonads.Init

/-!
# Part 7: Monad Laws


## Notes

- 

## TODO

- 
-/



namespace Part6



class Functor.Laws (Fct : Type u → Type v)
extends
  Functor Fct
where
  funct_identity :
    ∀ (a? : Fct α),
      map id a? = a?
  funct_composition :
    ∀ (f : α → β) (g : β → γ),
      map (g ∘ f) = map g ∘ map f



class Applicative.Laws (App : Type u → Type v)
extends
  Applicative App,
  Functor.Laws App
where
  app_identity :
    ∀ (a? : App α),
      pure id <*> a? = a?
  app_homomorphism :
    ∀ (a : α) (f : α → β),
      pure f <*> pure a = pure (f a)
  app_interchange :
    ∀ (f? : App (α → β)) (a : α),
      f? <*> pure a = pure (· a) <*> f?
  app_composition :
    ∀ (u : App α) (v : App (α → β)) (w : App (β → γ)),
      pure (· ∘ ·) <*> w <*> v <*> u = w <*> (v <*> u)



class Monad.Laws (Mon : Type u → Type v)
extends
  Monad Mon,
  Applicative.Laws Mon
where
  mon_identity_left :
    ∀ (a : α) (f : α → Mon β),
      (pure a) >>= f = f a
  mon_identity_right :
    ∀ (a? : Mon α),
      a? >>= (pure ·) = a?
  mon_assoc :
    ∀ (a? : Mon α) (f : α → Mon β) (g : β → Mon γ),
      (a? >>= f) >>= g = a? >>= (fun a => f a >>= g)



/-!
## **PROVING** the Laws
-/



instance : Monad.Laws Id where
  funct_identity _ :=
    rfl
  funct_composition _ _ :=
    rfl

  app_identity _ :=
    rfl
  app_homomorphism _ _ :=
    rfl
  app_interchange _ _ :=
    rfl
  app_composition _ _ _ :=
    rfl

  mon_identity_left _ _ :=
    rfl
  mon_identity_right _ :=
    rfl
  mon_assoc _ _ _ :=
    rfl



instance : Monad.Laws Option where
  funct_identity {α} a? :=
    by
      cases a?
      <;> rfl 
  funct_composition {α β γ} f g :=
    by
      funext a?
      cases a?
      <;> rfl

  app_identity a? :=
    by
      cases a?
      <;> rfl
  app_homomorphism {α β} a f :=
    by
      rw [Seq.seq]
      rfl
  app_interchange {α β} f? a :=
    by
      rw [Seq.seq]
      cases f?
      <;> rfl
  app_composition {α β γ} a? f? g? :=
    by
      rw [Seq.seq]
      cases a?
      <;> cases f?
      <;> cases g?
      <;> rfl

  mon_identity_left _ _ :=
    rfl
  mon_identity_right a? :=
    by
      cases a?
      <;> rfl
  mon_assoc {α β γ} a? fMon gMon :=
    by
      cases a?
      <;> rfl



instance : Monad.Laws IO where
  funct_identity action :=
    by
      funext io
      simp [Functor.map, EStateM.map]
      cases action io
      <;> rfl
  funct_composition {α β γ} f g :=
    by
      funext io env
      simp [Functor.map, EStateM.map]
      cases io env
      <;> rfl

  app_identity {α} a? :=
    by
      funext io
      unfold
        Seq.seq,
        Applicative.toSeq,
        Monad.toApplicative,
        instMonadEIO,
        inferInstanceAs,
        EStateM.instMonadEStateM,
        EStateM.bind
      simp [id, pure, EStateM.pure, EStateM.map]
      cases a? io
      <;> rfl
  app_homomorphism _ _ :=
    rfl
  app_interchange _ _ :=
    rfl
  app_composition {α β γ} a? fMon gMon :=
    by
      funext io
      unfold
        Seq.seq,
        Applicative.toSeq,
        Monad.toApplicative,
        instMonadEIO,
        inferInstanceAs,
        EStateM.instMonadEStateM,
        EStateM.bind
      simp [id, pure, EStateM.pure, EStateM.map]
      cases gMon io
      <;> simp
      cases fMon _
      <;> simp
      cases a? _
      <;> simp

  mon_identity_left _ _ :=
    rfl
  mon_identity_right a? :=
    by
      funext io
      unfold
        bind,
        Monad.toBind,
        instMonadEIO,
        inferInstanceAs,
        EStateM.instMonadEStateM,
        EStateM.bind
      simp
      cases a? io
      <;> rfl
  mon_assoc {α β γ} a? fMon gMon :=
    by
      funext io
      unfold
        bind,
        Monad.toBind,
        instMonadEIO,
        inferInstanceAs,
        EStateM.instMonadEStateM,
        EStateM.bind
      simp
      cases a? io
      <;> rfl



instance : Monad.Laws (StateM σ) where
  funct_identity _ :=
    rfl
  funct_composition _ _ :=
    rfl

  app_identity _ :=
    rfl
  app_homomorphism _ _ :=
    rfl
  app_interchange _ _ :=
    rfl
  app_composition _ _ _ :=
    rfl

  mon_identity_left _ _ :=
    rfl
  mon_identity_right _ :=
    rfl
  mon_assoc _ _ _ :=
    rfl
