import HaskellMonads.Init

/-!
# Part 6: Monad Transformers


## Notes

- *Typeclass* section is different as we rely on `MonadLift` and lean's auto-lift capabilities

## TODO

- use [`Alternative`] for `failure`/`orElse`, maybe in an advanced version of this part
-/



namespace Part6


def Name := String
instance : ToString Name := ⟨id⟩
def Email := String
instance : ToString Email := ⟨id⟩
def Pass := String
instance : ToString Pass := ⟨id⟩



namespace Session
  def login (name : Name) (email: Email) (pass: Pass) : IO Unit :=
    do
      IO.println "login attempt:"
      IO.println s!"-  name: `{name}`"
      IO.println s!"- email: `{email}`"
      IO.println s!"-  pass: `{pass}`"
      IO.println "..."
      IO.println "access not granted"

  def checkName (name : Name) : Bool :=
    name.length > 5

  def checkEmail (email : Email) : Bool :=
    email.mem '@' && email.mem '.'

  def checkPass (pass : Pass) : Bool :=
    pass.length ≥ 8
    || pass.any Char.isUpper
    || pass.any Char.isLower

  def askName : String :=
    "please enter your name:"
  def askEmail : String :=
    "please enter your email:"
  def askPass : String :=
    "please enter your password:"
end Session



namespace motivatingExample
  def qNa (q : String) (validate: String → Bool) : IO (Option String) :=
    do
      IO.println s!"{q}"
      let mut line ←
        IO.readLine
      line := line.trim
      if validate line
      then return line
      else
        IO.println s!"could not validate `{line}`"
        return none

  def readPass : IO (Option Pass) :=
    qNa
      Session.askPass
      Session.checkPass

  def readEmail : IO (Option Email) :=
    qNa
      Session.askEmail
      Session.checkEmail

  def readName : IO (Option Name) :=
    qNa
      Session.askName
      Session.checkName

  def main : IO Unit :=
    do
      match ←readName with
      | none =>
        IO.println "invalid user name"
      | some name =>
        match ←readEmail with
        | none =>
          IO.println "invalid user email"
        | some email =>
          match ←readEmail with
          | none =>
            IO.println "invalid user password"
          | some pass =>
            Session.login name email pass
end motivatingExample



def Option.T (Mon : Type u → Type v) (α : Type u) :=
  Mon (Option α)

section Option.T
  variable
    {Mon : Type u → Type v}
    [instMon : Monad Mon]

  def Option.T.run : T Mon α → Mon (Option α) :=
    id

  def Option.T.pure : α → T Mon α :=
    instMon.pure
    ∘ some

  def Option.T.fail : T Mon α :=
    instMon.pure none
    |> OptionT.mk

  def Option.T.bind (a : T Mon α) (f : α → T Mon β) : T Mon β :=
    let f : Option α → T Mon β
      | none => instMon.pure none
      | some a => f a
    instMon.bind a f

  instance instMonad : Monad (Option.T Mon) where
    pure :=
      Option.T.pure
    bind :=
      Option.T.bind

  def Option.T.lift (sub : Mon α) : T Mon α :=
    let wrapped :=
      do return some (←sub)
    OptionT.mk wrapped
  
  @[defaultInstance]
  instance instMonadLift : MonadLift Mon (Option.T Mon) where
    monadLift :=
      Option.T.lift
end Option.T



namespace Auth
  def qNa (q : String) (validate : String → Bool) : Option.T IO String :=
    do
      IO.println s!"{q}"
      let mut line ←
        IO.readLine
      line := line.trim
      if validate line
      then return line
      else
        IO.println s!"could not validate `{line}`"
        Option.T.fail

  def readName : Option.T IO Name :=
    qNa
      Session.askName
      Session.checkName
  def readEmail : Option.T IO Email :=
    qNa
      Session.askEmail
      Session.checkEmail
  def readPass : Option.T IO Pass :=
    qNa
      Session.askPass
      Session.checkPass

  def main : IO Unit :=
    do
      let credentials? ←
        Option.T.run do
          let name ← readName
          let email ← readEmail
          let pass ← readPass
          return (name, email, pass)
      if let some (name, email, pass) := credentials?
      then Session.login name email pass
      else
        IO.println "invalid credentials /(-_-)\\"
end Auth



def Env :=
  Option Name × Option Email × Option Pass

namespace Env
  open ReaderT (instMonadReaderT instMonadLiftReaderT)

  def readName : Option.T (ReaderT Env IO) String :=
    Option.T.run do
      let (name?, _, _) ←
        ReaderT.read
        -- turn `ReaderT Env IO` into `Option.T (Reader Env IO)`
        |> Option.T.lift
      match name? with
      | some name =>
        return name
      | none => do
        IO.println Session.askName
        -- turn `IO` into `ReaderT Env IO`
        |> liftM
        -- turn `ReaderT Env IO` into `Option.T (Reader Env IO)`
        |> Option.T.lift
        let name ←
          IO.readLine
        if Session.checkName name
        then return name
        else Option.T.fail
end Env



abbrev TripleMonad (α : Type) :=
  Option.T (ReaderT Env IO) α

def TripleMonad.doRead : ReaderT Env IO α → TripleMonad α :=
  liftM
def TripleMonad.doIO : IO α → TripleMonad α :=
  Option.T.lift ∘ liftM



namespace Debug
  def debugFunc (msg : String) : IO Unit :=
    IO.println s!"sucessfully produced input: {msg}"

  def main : IO Unit :=
    do
      let credentials? ←
        Option.T.run do
          let name ← Auth.readName
          debugFunc name
          let email ← Auth.readEmail
          debugFunc email
          let pass ← Auth.readPass
          debugFunc pass
          return (name, email, pass)
      if let some (name, email, pass) := credentials?
      then Session.login name email pass
      else
        IO.println "invalid credentials /(-_-)\\"
end Debug
