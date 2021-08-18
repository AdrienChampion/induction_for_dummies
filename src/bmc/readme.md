# Unrolling and BMC

In the previous chapter, we played with our running example using Z3 by

- defining the transition relation as a `define-fun`,

<details>
	<summary>Expand for a refresher on this definition.</summary>

```text
{{ #include ../trans_smt/code/sw_trans_1.smt2:trans_def }}
```
</details>

- declaring two states `0` and `1`,

<details>
	<summary>Expand for a refresher on these declarations.</summary>

```text
{{ #include ../trans_smt/code/sw_trans_1.smt2:state_def }}
```
</details>

- asserting the transition relation between state `0` and state `1`, and

<details>
	<summary>Expand for a refresher on this assertion.</summary>

```text
{{ #include ../trans_smt/code/sw_trans_1.smt2:unroll_1 }}
```
</details>

- querying Z3 by constraining state `0` and/or state `1` to inspect the transition relation and
  prove some basic properties over it.

<details>
	<summary>Expand for a refresher on the querying.</summary>

```text
{{ #include ../trans_smt/code/sw_trans_1.smt2:state_constraints }}
```
</details>

\
\

Now, this process of asserting the transition relation between two states `0` and `1` effectively
enforces the constraint that state `1` must be a legal successor of state `0`. This process is
called *unrolling the transition relation*, or *unrolling the system*, or just *unrolling*.

So far, we have only unrolled once to relate state `0` and state `1`. We can unroll more than once,
simply by declaring more states and relate `0` to `1`, `1` to `2`, *etc.* by asserting the
transition relation over the appropriate state variables.

<details>
	<summary>Expand for an example of unrolling the system thrice.</summary>

```text
{{ #include code/sw_unroll_1.smt2 }}
```

Output:

```text
> z3 test.smt2
{{ #include code/sw_unroll_1.smt2.out }}
```
</details>
