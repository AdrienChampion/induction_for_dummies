# Induction for Dummies

- Adrien Champion
- <adrien.champion@ocamlpro.com>

This series of posts broadly discusses *induction* as a *formal verification* technique, which here
really means *formal program verification*. We will use concrete, runnable examples whenever
possible so that readers can mess around with them. Some of them can run directly in a browser,
while others require to run a small tool locally. Such is the case for pretty much all examples
dealing directly with induction.

Different communities, and different people in the same community, will use the same words to mean
different things. The technical terms defined in this series are no exceptions, and readers should
beware that the way this series defines and use them might differ, sometimes subtly, in other
discussions on verification and induction.

\
\

These posts discuss verification from the point of view of the solvers available for verification,
and actual semi-industrial or industrial program verification challenges. Solvers are low-level
tools working on systems that are relatively far from the programs to analyze: we are interested in
bridging this gap.

\
\

The main goal of these posts is to introduce readers to induction-based verification techniques. A
simple tool called `mikino` is used throughout and will let us inspect low-level aspects as well as
run and inspect our proofs at (relatively) high level. Readers are encouraged to attempt to verify
their own programs. We also hope to give an understanding of the challenges in designing a
verification framework for a specific context using existing low-level solvers.


## Table of Contents

- [Preface](./preface/readme.md)

    High-level presentation of (formal) verification as a formal method.

- [SMT Solvers](./smt/readme.md)

    SMT solvers are the basic building blocks for many modern verification tools.

- [Transition Systems](./trans/readme.md)

    Transition systems are *one way* to encode a wide variety of programs in a formalism suited for
    formal verification. Following sections will only deal with transition system as they are fairly
    easy to understand. They definitely have downsides, but one can get a surprising mileage out of
    them if careful.

- [BMC](./bmc/readme.md)

    **B**ounded **M**odel-**C**hecking is, *in general*, not a verification technique. Still, it is
    quite useful for finding *concrete counterexample*, *i.e.* a concrete behavior of the system
    that illustrates a problem. It is also a good context to showcase what one can do with a
    transition system using an SMT solver.

- [Induction](./induction/readme.md)

    Induction is a natural step from BMC. Since induction *is* a verification technique, this part
    is where we finally start proving things; which is actually not the interesting case because
    *i)* it's the case where we are done, we proved whatever we wanted to prove, and *ii)* induction
    will often not manage to prove much on most systems.

    We will mostly discuss what *"induction not working"* means, why it *not-works*, and what
    information we can get back when it does.

- [Property Strengthening](./strength/readme.md)

    This last part of the series focuses on property strengthening, which is really *discovering*
    useful, powerful facts about the system's behavior. Automatic *discovery* of such facts using
    computers as they exist today yields interesting results but has its limits. Arguably, it would
    be much easier if we could have computers harness a human brain instead. Ideally, a brain that
    is knowledgeable about the actual system being analyzed.

    The main ambition of this series is to upload just enough knowledge about verification into the
    brains of its readers that, if they end up using formal verification in real life, the
    verification engine can try to harness their flawed but occasionally relevant capacities.
