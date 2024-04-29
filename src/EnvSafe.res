@@uncurried

%%private(external magic: 'a => 'b = "%identity")

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

    let raiseError = (error: error): 'a => error->magic->raise
  }
}

module Error = {
  @inline
  let panic = message =>
    Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-envsafe] ${message}`))
}

type env = Js.Dict.t<string>
type issue = {name: string, error: S.error, input: option<string>}
type t = {
  env: env,
  mutable isLocked: bool,
  mutable maybeMissingIssues: option<array<issue>>,
  mutable maybeInvalidIssues: option<array<issue>>,
}

module Env = {
  @val
  external // FIXME: process might be missing
  default: Js.Dict.t<string> = "process.env"
}

// TODO: When can't coerce, default to json parsing

let mixinIssue = (envSafe, issue) => {
  switch issue.error {
  | {code: InvalidType({received})}
  | {code: InvalidLiteral({received})} if received === %raw(`undefined`) =>
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

let make = (~env=Env.default) => {
  {env, isLocked: false, maybeMissingIssues: None, maybeInvalidIssues: None}
}

let close = envSafe => {
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
            output->Js.Array2.push(`    ${issue.name}: ${issue.error->S.Error.message}`)->ignore
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
let prepareSchema = (~schema, ~allowEmpty) => {
  schema->S.preprocess(s => {
    let tagged = switch s.schema->S.classify {
    | Option(optionalSchema) => optionalSchema->S.classify
    | tagged => tagged
    }
    switch tagged {
    | Literal(Boolean(_))
    | Bool => {
        parser: unknown => {
          switch unknown->magic {
          | "true"
          | "t"
          | "1" => true
          | "false"
          | "f"
          | "0" => false
          | _ => unknown->magic
          }->magic
        },
      }

    | Literal(Number(_))
    | Int
    | Float => {
        parser: unknown => {
          if unknown->Js.typeof === "string" {
            let float = %raw(`+unknown`)
            if Js.Float.isNaN(float) {
              unknown
            } else {
              float
            }
          } else {
            unknown
          }
        },
      }
    | String if allowEmpty === false => {
        parser: unknown => {
          switch unknown->magic {
          | "" => Js.undefined->magic
          | _ => unknown->magic
          }
        },
      }
    | String
    | Literal(String(_))
    | JSON
    | Union(_)
    | Unknown
    | Never => {}
    | _ => {
        parser: unknown => {
          if unknown->Js.typeof === "string" {
            let string = unknown->(magic: unknown => string)
            string->Js.Json.parseExn->magic
          } else {
            unknown
          }
        },
      }
    }
  })
}

let get = (
  envSafe,
  name,
  schema,
  ~allowEmpty=false,
  ~fallback as maybeFallback=?,
  ~devFallback as maybeDevFallback=?,
  ~input as maybeInlinedInput=?,
) => {
  if envSafe.isLocked {
    Error.panic("EnvSafe is closed. Make a new one to get access to environment variables.")
  }
  let input = switch maybeInlinedInput {
  | Some(inlinedInput) => inlinedInput
  | None => envSafe.env->Stdlib.Dict.get(name)
  }
  let parseResult = input->S.parseAnyWith(prepareSchema(~schema, ~allowEmpty))
  switch (parseResult, maybeDevFallback, maybeFallback) {
  | (Ok(v), _, _) => v
  | (Error({code: InvalidLiteral({received})}), Some(devFallback), _)
  | (Error({code: InvalidType({received})}), Some(devFallback), _)
    if received === %raw(`undefined`) &&
      envSafe.env->Stdlib.Dict.get("NODE_ENV") !== Some("production") => devFallback
  | (Error({code: InvalidLiteral({received})}), _, Some(fallback))
  | (Error({code: InvalidType({received})}), _, Some(fallback))
    if received === %raw(`undefined`) => fallback
  | (Error(error), _, _) => {
      envSafe->mixinIssue({name, error, input})
      %raw(`undefined`)
    }
  }
}
