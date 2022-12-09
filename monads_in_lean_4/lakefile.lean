import Lake
open Lake DSL

package haskellMonads {
  -- add package configuration options here
}

lean_lib HaskellMonads {
  -- add library configuration options here
}

@[default_target]
lean_exe haskellMonads {
  root := `Main
}

require std from git
  "https://github.com/leanprover/std4"
