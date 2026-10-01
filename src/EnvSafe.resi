@@uncurried

type env
type t

let make: (~env: env=?) => t

let close: t => unit

let get: (
  t,
  string,
  S.t<'value>,
  ~fallback: 'value=?,
  ~devFallback: 'value=?,
  ~input: option<string>=?,
) => 'value
