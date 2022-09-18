type env
type t

let make: (~env: env=?, unit) => t

let close: (t, unit) => unit

let get: (
  t,
  ~name: string,
  ~struct: S.t<'value>,
  ~allowEmpty: bool=?,
  ~devFallback: 'value=?,
  ~input: option<string>=?,
  unit,
) => 'value
