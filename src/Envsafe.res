module Lib = {
  module Dict = {
    @get_index external get: (Js.Dict.t<'a>, string) => option<'a> = ""
  }
}

module Env = {
  type t = Js.Dict.t<string>

  @val
  external default: Js.Dict.t<string> = "process.env"
}

module Config = {
  type t = {env?: Env.t}

  let configRef = ref({env: ?None})

  let set = config => {
    configRef.contents = config
  }

  let reset = () => {
    configRef.contents = {env: ?None}
  }

  let getEnv = () => configRef.contents.env->Belt.Option.getWithDefault(Env.default)
}

let prepareStruct = (~struct) => {
  struct->S.advancedPreprocess(~parser=(~struct) => {
    switch (struct->S.classify, struct->S.Literal.classify) {
    | (Literal, Some(Bool(_)))
    | (Bool, _) =>
      Sync(
        unknown => {
          switch unknown->Obj.magic {
          | "true"
          | "t"
          | "1" => true
          | "false"
          | "f"
          | "0" => false
          | _ => unknown->Obj.magic
          }
        },
      )
    | (Literal, Some(Int(_)))
    | (Literal, Some(Float(_)))
    | (Int, _)
    | (Float, _) =>
      Sync(
        unknown => {
          unknown->ignore
          %raw(`+unknown`)
        },
      )
    | _ => Sync(unknown => unknown->Obj.magic)
    }
  }, ())
}

let get = (~key, ~struct) => {
  let preparedStruct = prepareStruct(~struct)
  Config.getEnv()->Lib.Dict.get(key)->S.parseWith(preparedStruct)->S.Result.getExn
}
