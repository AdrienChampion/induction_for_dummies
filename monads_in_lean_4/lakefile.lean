import Lake
open Lake DSL

package haskellMonads {
  -- add package configuration options here
}

lean_lib HaskellMonads {
  -- add library configuration options here
}

@[defaultTarget]
lean_exe haskellMonads {
  root := `Main
}
