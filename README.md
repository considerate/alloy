# alloy

## TODO
- [x] step 1
  - [x] Closure scope contains ThunkIDs instead of values
  - [x] arithmetic expressions
  - [x] attribute sets
  - [x] field accessor parsing
  - [x] bugs:
    - [x] `let id = x:x; x = 4 in id x` diverges
    - [x] `let x = 4; in {a = x;}` gives unbound variable, `let x=4; in x` works
  - [x] let bindings
  - [x] syntax rework
  - [x] remove lens dependency?
- [ ] step 2
  - [ ] figure out step 2
  - [ ] builtins
    - [ ] error
      - [ ] strings
- [ ] step n
  - [ ] booleans
- [ ] eventually
  - [ ] recursion
  - [ ] trace
  - [ ] stack traces
  - [ ] imports
    - [ ] check for unbound variables to avoid capture issues
  - [ ] warnings
  - [ ] inherit from set, inherit multiple
  - [ ] performance stuff
  - [ ] design questions
    - [ ] Everything
    - [ ] Atoms
  - [ ] remove microlens dependency?
