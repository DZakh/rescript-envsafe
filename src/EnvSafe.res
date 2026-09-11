@@uncurried

%%private(external magic: 'a => 'b = "%identity")

module Stdlib = {
  module Dict = {
    @get_index external get: (dict<'a>, string) => option<'a> = ""
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

    let raiseError = (error: error): 'a => error->magic->throw
  }
}

module Error = {
  @inline
  let panic = message =>
    Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-envsafe] ${message}`))
}

type env = dict<string>
type invalidIssue = {name: string, error: S.error, input: option<string>}
type missingIssue = {name: string, input: option<string>}
type t = {
  env: env,
  mutable isLocked: bool,
  mutable maybeMissingIssues: option<array<missingIssue>>,
  mutable maybeInvalidIssues: option<array<invalidIssue>>,
}

module Env = {
  @val
  external // FIXME: process might be missing
  default: dict<string> = "process.env"
}

let mixinMissingIssue = (envSafe, issue) => {
  switch envSafe.maybeMissingIssues {
  | Some(missingIssues) => missingIssues->Array.push(issue)->ignore
  | None => envSafe.maybeMissingIssues = Some([issue])
  }
}

let mixinInvalidIssue = (envSafe, issue: invalidIssue) => {
  switch envSafe.maybeInvalidIssues {
  | Some(invalidIssues) => invalidIssues->Array.push(issue)->ignore
  | None => envSafe.maybeInvalidIssues = Some([issue])
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
          output->Array.push("❌ Invalid environment variables:")->ignore
          invalidIssues->Array.forEach(issue => {
            output->Array.push(`    ${issue.name}: ${issue.error.message}`)->ignore
          })
        })

        maybeMissingIssues->Stdlib.Option.forEach(missingIssues => {
          output->Array.push("💨 Missing environment variables:")->ignore
          missingIssues->Array.forEach(issue => {
            output
            ->Array.push(
              `    ${issue.name}: ${switch issue.input {
                | Some("") => "Disallowed empty string"
                | _ => "Missing value"
                }}`,
            )
            ->ignore
          })
        })

        output->Array.push(line)->ignore
        output->Array.joinUnsafe("\n")
      }

      Console.error(text)
      Stdlib.Window.alert(text)
      Stdlib.Exn.raiseError(Stdlib.Exn.makeTypeError(text))
    }
  }
}

let boolCoerce = string =>
  switch string {
  | "true"
  | "t"
  | "1" =>
    true->magic
  | "false"
  | "f"
  | "0" =>
    false->magic
  | _ => string
  }

let numberCoerce = string => {
  let float = %raw(`+string`)
  if Float.isNaN(float) {
    string
  } else {
    float->magic
  }
}

let bigintCoerce = string => {
  try string->BigInt.fromStringOrThrow->magic catch {
  | _ => string
  }
}

let jsonCoerce = string => {
  try string->JSON.parseOrThrow->magic catch {
  | _ => string
  }
}

// Sury flattens nested unions and spells `S.option(X)` as an `X | undefined`
// union, so the `undefined` member comes off before asking what a raw string
// should coerce to. One member left means the schema reads as that type; more
// than one is a real union, where every member coerces on its own.
let coercionTarget = (schema: S.t<'value>): option<S.t<unknown>> =>
  switch schema {
  | S.AnyOf({anyOf}) =>
    switch anyOf->Array.filter(member =>
      switch member {
      | S.Undefined(_) => false
      | _ => true
      }
    ) {
    | [member] => Some(member)
    | _ => None
    }
  | leaf => Some(leaf->S.castToUnknown)
  }

let coerceString = (string, schema) =>
  switch schema {
  | S.Boolean(_) => string->boolCoerce
  | S.BigInt(_) => string->bigintCoerce
  | S.Number(_) => string->numberCoerce
  | S.String(_)
  | S.Never(_) => string
  | _ => string->jsonCoerce
  }

// A union carrying its own refinement or conversion is a normal schema rather
// than a union (Sury's CODEC_SPEC.md), and rebuilding it from `anyOf` would
// drop what it carries - so leave those alone and pass the string through.
// `decoder`/`encoder` are the compiled dispatch every union has, not own logic.
// `refiner` has no field on `S.untagged`, hence the raw read.
let carriesOwnLogic = (schema: S.t<'value>) =>
  %raw(`s => s.refiner !== undefined`)(schema) || (schema->S.untag).to->Option.isSome

// `S.to` replaces the preprocessor rescript-schema distributed over a union's
// members: each member decodes the raw string the way its own type wants.
let coerceUnion = (schema: S.t<'value>): S.t<'value> =>
  switch schema {
  | S.AnyOf({anyOf}) if !(schema->carriesOwnLogic) =>
    S.union(
      anyOf->Array.map(member =>
        S.any->S.to(
          member,
          ~custom={decode: Sync(input => input->magic->coerceString(member)->magic), encode: Never},
        )
      ),
    )->magic
  | _ => schema
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
  let isMissing = switch (input, allowEmpty) {
  | (None, _)
  | (Some(""), false) => true
  | _ => false
  }
  let isOptional = switch schema {
  | S.AnyOf({has: {undefined: true}}) => true
  | _ => false
  }
  if isMissing && !isOptional {
    switch (maybeDevFallback, maybeFallback) {
    | (Some(devFallback), _)
      if envSafe.env->Stdlib.Dict.get("NODE_ENV") !== Some("production") => devFallback
    | (_, Some(fallback)) => fallback
    | _ => {
        envSafe->mixinMissingIssue({name, input})
        %raw(`undefined`)
      }
    }
  } else {
    let target = schema->coercionTarget
    let input = switch input {
    | Some("") if !allowEmpty => None
    | None => None
    | Some(string) =>
      switch target {
      | Some(member) => string->coerceString(member)
      | None => string
      }->Some
    }
    let schema = switch target {
    | Some(_) => schema
    | None => schema->coerceUnion
    }
    try input->S.parseOrThrow(~to=schema) catch {
    | S.Exn(error) => {
        envSafe->mixinInvalidIssue({name, error, input})
        %raw(`undefined`)
      }
    }
  }
}
