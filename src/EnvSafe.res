module Stdlib = {
  module Dict = {
    @get_index external get: (Js.Dict.t<'a>, string) => option<'a> = ""
  }

  module Option = {
    @inline
    let forEach = (option, fn) => {
      switch option {
      | Some(v) => fn(v)
      | None => ()
      }
    }
  }

  module Window = {
    let alert = (message: string): unit => {
      message->ignore
      if %raw(`typeof window !== 'undefined' && window.alert`) {
        %raw(`window.alert(message)`)
      }
    }
  }

  module Exn = {
    type error

    @new
    external makeError: string => error = "Error"
    @new
    external makeTypeError: string => error = "TypeError"

    let raiseError = (error: error): 'a => error->Obj.magic->raise
  }
}

module Error = {
  @inline
  let panic = message =>
    Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-envsafe] ${message}`))
}

type env = Js.Dict.t<string>
type issue = {name: string, error: S.Error.t, input: option<string>}
type t = {
  env: env,
  mutable isLocked: bool,
  mutable maybeMissingIssues: option<array<issue>>,
  mutable maybeInvalidIssues: option<array<issue>>,
}

module Env = {
  @val
  external default: Js.Dict.t<string> = "process.env"
}

let mixinIssue = (envSafe, issue) => {
  switch issue.error {
  | {code: UnexpectedType({received: "Option"})} =>
    switch envSafe.maybeMissingIssues {
    | Some(missingIssues) => missingIssues->Js.Array2.push(issue)->ignore
    | None => envSafe.maybeMissingIssues = Some([issue])
    }
  | _ =>
    switch envSafe.maybeInvalidIssues {
    | Some(invalidIssues) => invalidIssues->Js.Array2.push(issue)->ignore
    | None => envSafe.maybeInvalidIssues = Some([issue])
    }
  }
}

let make = (~env=Env.default, ()) => {
  {env, isLocked: false, maybeMissingIssues: None, maybeInvalidIssues: None}
}

let close = (envSafe, ()) => {
  if envSafe.isLocked {
    Error.panic("EnvSafe is already closed.")
  }
  envSafe.isLocked = true
  switch (envSafe.maybeMissingIssues, envSafe.maybeInvalidIssues) {
  | (None, None) => ()
  | (maybeMissingIssues, maybeInvalidIssues) => {
      let text = {
        let line = "========================================"
        let output = [line]

        maybeInvalidIssues->Stdlib.Option.forEach(invalidIssues => {
          output->Js.Array2.push("❌ Invalid environment variables:")->ignore
          invalidIssues->Js.Array2.forEach(issue => {
            output
            ->Js.Array2.push(
              `    ${issue.name}${switch issue.input {
                | Some(v) => ` ("${v}")`
                | None => ""
                }}: ${issue.error->S.Error.toString}`,
            )
            ->ignore
          })
        })

        maybeMissingIssues->Stdlib.Option.forEach(missingIssues => {
          output->Js.Array2.push("💨 Missing environment variables:")->ignore
          missingIssues->Js.Array2.forEach(issue => {
            output
            ->Js.Array2.push(
              `    ${issue.name}: ${switch issue.input {
                | Some("") => "Disallowed empty string"
                | _ => "Missing value"
                }}`,
            )
            ->ignore
          })
        })

        output->Js.Array2.push(line)->ignore
        output->Js.Array2.joinWith("\n")
      }

      Js.Console.error(text)
      Stdlib.Window.alert(text)
      Stdlib.Exn.raiseError(Stdlib.Exn.makeTypeError(text))
    }
  }
}

@inline
let prepareStruct = (~struct, ~allowEmpty) => {
  struct->S.advancedPreprocess(~parser=(~struct) => {
    let tagged = switch struct->S.classify {
    | Option(optionalStruct) => optionalStruct->S.classify
    | tagged => tagged
    }
    switch tagged {
    | Literal(Bool(_))
    | Bool =>
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
    | Literal(Int(_))
    | Literal(Float(_))
    | Int
    | Float =>
      Sync(
        unknown => {
          if unknown->Js.typeof === "string" {
            %raw(`+unknown`)
          } else {
            unknown
          }
        },
      )
    | String if allowEmpty === false =>
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

let get = (
  envSafe,
  ~name,
  ~struct,
  ~allowEmpty=false,
  ~devFallback as maybeDevFallback=?,
  ~input as maybeInlinedInput=?,
  (),
) => {
  if envSafe.isLocked {
    Error.panic("EnvSafe is closed. Make a new one to get access to environment variables.")
  }
  let input = switch maybeInlinedInput {
  | Some(inlinedInput) => inlinedInput
  | None => envSafe.env->Stdlib.Dict.get(name)
  }
  let parseResult = input->S.parseAnyWith(prepareStruct(~struct, ~allowEmpty))
  switch (parseResult, maybeDevFallback) {
  | (Ok(v), _) => v
  | (Error({code: UnexpectedType({received: "Option"})}), Some(devFallback))
    if envSafe.env->Stdlib.Dict.get("NODE_ENV") !== Some("production") => devFallback
  | (Error(error), _) => {
      envSafe->mixinIssue({name, error, input})
      %raw(`undefined`)
    }
  }
}
