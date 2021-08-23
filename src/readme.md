# Induction for Dummies

- Adrien Champion
- <adrien.champion@ocamlpro.com>

This series of posts broadly discusses *induction* as a *formal verification* technique, which here
really means *formal program verification*. We will use concrete, runnable examples whenever
possible. Some of them can run directly in a browser, while others require to run small
easy-to-retrieve tools locally. Such is the case for pretty much all examples dealing directly with
induction.

These posts try to introduce the following notions:

- formal logics and formal frameworks;
- SMT-solving: modern, *low-level* verification building blocks;
- declarative transition systems;
- transition system unrolling;
- BMC and induction proofs over transition systems.

\
\

The approach presented here is far from being the only one when it comes to program verification.
It happens to be relatively simple to understand, and we believe that familiarity with the notions
discussed here makes understanding other approaches significantly easier.

\
\

## Table of Contents

- [Preface](./preface)

    High-level presentation of (formal) verification as a formal method.

- [SMT Solvers](./smt)

    SMT solvers are the basic building blocks for many modern verification tools.

- [Transition Systems](./trans)

    Transition systems are *one way* to encode a wide variety of programs in a formalism suited for
    formal verification. Following sections will discuss all notions in the context of transition
    system as they are fairly easy to understand. They definitely have downsides, but one can get a
    surprising mileage out of them if careful.

- [SMT and Transition Systems](./trans_smt)

    Transition systems are represented by formulas that SMT solver can work on. This post lays out
    the foundation for more complex SMT-based analyses.

- [Unrolling and BMC](./bmc)

    **B**ounded **M**odel-**C**hecking is, *in general*, not a verification technique. Still, it is
    quite useful for finding *concrete counterexample*, *i.e.* a concrete behavior of the system
    that illustrates a problem. It is also a good context to showcase what one can do with a
    transition system using an SMT solver.

- [BMC: Mikino](./mikino_bmc)

    Mikino is a small proof engine that can perform BMC. While it requires getting familiar with
    its simple input format, it abstracts SMT solvers for us so that we can focus on higher-level
    concepts.

- [Induction](./induction)

    Induction is a natural step from BMC: it requires a simple BMC-like *base* check but also a
    *step* check which is simple to encode with SMT solvers. Since induction *is* a verification
    technique contrary to BMC, this is where we finally start proving things.

- [Induction: Mikino and Step Cex-s](./mikino_induction)

    In addition to BMC, mikino can also perform induction. It can thus prove *inductive* properties
    of a system. Once again, mikino abstracts the SMT solver for us.

- [Property Strengthening](./strength)

    An invariant for a system is not necessarily inductive. This last part of the series focuses on
    property strengthening, which is really about *discovering* useful, powerful facts about the
    system's behavior. Such facts can make non-inductive invariants inductive, which is why most
    modern induction-based verification engines focus heavily on property strengthening.
