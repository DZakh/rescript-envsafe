module Env = {
  type t = Js.Dict.t<string>

  @val
  external default: Js.Dict.t<string> = "process.env"
}

module Config = {
  type t = {env: Env.t}

  let value = {env: Env.default}
}

let get = (~key, ~struct) => {
  Config.value.env->Js.Dict.get(key)->S.parseWith(struct)->S.Result.getExn
}
