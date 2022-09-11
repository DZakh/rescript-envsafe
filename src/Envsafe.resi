module Env: {
  type t
}

module Config: {
  type t = {env?: Env.t}

  let set: t => unit

  let reset: unit => unit
}

let get: (~key: string, ~struct: S.t<'value>) => 'value
