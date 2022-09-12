module Reporter: {
  type t = (. ~key: string, ~error: S.Error.t) => unit
}

module Env: {
  type t
}

module Config: {
  type t = {env?: Env.t, reporter?: Reporter.t}

  let set: t => unit

  let reset: unit => unit
}

let get: (
  ~key: string,
  ~struct: S.t<'value>,
  ~allowEmpty: bool=?,
  ~devFallback: 'value=?,
  unit,
) => 'value
