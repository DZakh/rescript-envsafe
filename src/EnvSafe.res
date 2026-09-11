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

// Sury's `S.string->S.to(S.boolean)` reads "true"/"false"; envsafe also reads
// "t"/"f"/"1"/"0", so those are normalized into the two the conversion knows.
// Normalizing the string rather than producing the bool keeps the target doing
// the validating: a custom coder's result is the target's *output*, so nothing
// would reject "2".
let boolString = S.string->S.to(
  S.string,
  ~custom={
    decode: Sync(
      string =>
        switch string {
        | "true" | "t" | "1" => "true"
        | "false" | "f" | "0" => "false"
        | string => string
        },
    ),
    encode: Auto,
  },
)

// Sury's built-in `S.string->S.to` coercion covers every leaf: literals,
// numbers, bigints and a string passing through. Two kinds need a word:
//
// - bool, whose extra tokens are normalized into the two the conversion reads.
// - anything JSON-shaped, where the string is a document rather than a value
//   the built-in conversion could reach. `S.jsonString` is that reading.
//
// The reading has to be picked by shape, not by trying one and catching: `S.to`
// builds lazily, so an unreachable conversion only fails when a value arrives.
let coerceLeaf = (schema: S.t<'value>): S.t<'value> =>
  switch schema {
  | S.Boolean(_) => boolString->S.to(schema)
  | S.String(_)
  | S.Number(_)
  | S.BigInt(_)
  | S.Never(_) =>
    S.string->S.to(schema)
  | _ => S.jsonString->S.to(schema)
  }

// A union carrying its own refinement or conversion is a normal schema rather
// than a union (Sury's CODEC_SPEC.md), and rebuilding it from `anyOf` would
// drop what it carries. `decoder`/`encoder` are the compiled dispatch every
// union has, not own logic; `refiner` has no field on `S.untagged`.
let carriesOwnLogic = (schema: S.t<'value>) =>
  %raw(`s => s.refiner !== undefined`)(schema) || (schema->S.untag).to->Option.isSome

// Sury flattens nested unions and spells `S.option(X)` as an `X | undefined`
// union. A string never arrives for the `undefined` member, so it passes
// through; the rest coerce on their own, which is what the preprocessor
// rescript-schema distributed over a union's members used to do. Wrapping each
// member is also Sury's own remedy for the ambiguity a bare
// `string -> boolean | string` is rejected with.
let coerceSchema = (schema: S.t<'value>): S.t<'value> =>
  switch schema {
  | S.AnyOf({anyOf}) if !(schema->carriesOwnLogic) =>
    S.union(
      anyOf->Array.map(member =>
        switch member {
        | S.Undefined(_) => member
        | _ => member->coerceLeaf
        }
      ),
    )->magic
  // A union carrying its own logic is left alone: there is no single member to
  // read the string as, and the JSON reading below would be wrong for it.
  | S.AnyOf(_) => schema
  | _ => schema->coerceLeaf
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
    let input = switch input {
    | Some("") if !allowEmpty => None
    | input => input
    }
    try input->S.parseOrThrow(~to=schema->coerceSchema) catch {
    | S.Exn(error) => {
        envSafe->mixinInvalidIssue({name, error, input})
        %raw(`undefined`)
      }
    }
  }
}
