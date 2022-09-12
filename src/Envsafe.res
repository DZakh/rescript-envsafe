module Lib = {
  module Dict = {
    @get_index external get: (Js.Dict.t<'a>, string) => option<'a> = ""
  }
}

module Reporter = {
  type t = (. ~key: string, ~error: S.Error.t) => unit

  let default = (. ~key as _, ~error as _) => Js.Exn.raiseTypeError("Invalid env variable")
}

module Env = {
  type t = Js.Dict.t<string>

  @val
  external default: Js.Dict.t<string> = "process.env"
}

module Config = {
  type t = {env?: Env.t, reporter?: Reporter.t}

  let configRef = ref({env: ?None})

  let set = config => {
    configRef.contents = config
  }

  let reset = () => {
    configRef.contents = {env: ?None}
  }

  let getEnv = overwrite => overwrite.env->Belt.Option.getWithDefault(Env.default)
  let getReporter = overwrite => overwrite.reporter->Belt.Option.getWithDefault(Reporter.default)
}

@inline
let prepareStruct = (~struct, ~allowEmpty) => {
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
          }->Obj.magic
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
    | (String, _) if allowEmpty === false =>
      Sync(
        unknown => {
          switch unknown->Obj.magic {
          | "" => Js.undefined->Obj.magic
          | _ => unknown->Obj.magic
          }
        },
      )
    | _ => Sync(unknown => unknown->Obj.magic)
    }
  }, ())
}

let get = (~key, ~struct, ~allowEmpty=false, ~devFallback as maybeDevFallback=?, ()) => {
  let config = Config.configRef.contents
  let env = config->Config.getEnv
  let input = env->Lib.Dict.get(key)
  let parseResult = input->S.parseWith(prepareStruct(~struct, ~allowEmpty))

  switch (parseResult, maybeDevFallback) {
  | (Ok(v), _) => v
  | (Error({code: UnexpectedType({received: "Option"})}), Some(devFallback))
    if env->Lib.Dict.get("NODE_ENV") !== Some("production") => devFallback
  | (Error(error), _) => (config->Config.getReporter)(. ~key, ~error)->Obj.magic
  }
}
