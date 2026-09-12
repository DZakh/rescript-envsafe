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
type missingIssue = {name: string}
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
            output->Array.push(`    ${issue.name}: Missing value`)->ignore
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

// `S.env` is Sury's environment-variable codec: it reads a raw string into
// literals, numbers, bigints, options and literal unions, and it answers what a
// blank means from the schema the caller wrote - `S.nonEmpty` to reject one,
// `S.minLength(0)` to keep it, `S.option` to read it as absent. Two things it
// does not do:
//
// - the "t"/"f"/"1"/"0" spellings envsafe documents, normalized in the value
//   below rather than in the schema. Layering a coder on `S.env` would cost its
//   option handling: `boolEnv->S.to(S.option(S.bool))` rejects a missing var.
// - anything JSON-shaped, where the string is a document rather than a value
//   `S.env` could reach (`Can't decode env -> int32[]`). `S.jsonString` is that
//   reading, and `S.unknown` wants it too - `S.env` hands back the raw string.
//
// The reading has to be picked by shape, not by trying one and catching: `S.to`
// builds lazily, so an unreachable conversion only fails when a value arrives.
let needsJsonReading = member =>
  switch member {
  | S.String(_)
  | S.Boolean(_)
  | S.Number(_)
  | S.BigInt(_)
  | S.Never(_) => false
  | _ => true
  }

let coerceWith = (schema: S.t<'value>, member): S.t<'value> =>
  if member->needsJsonReading {
    S.jsonString->S.to(schema)
  } else {
    S.env->S.to(schema)
  }

// Anything the codec doesn't read passes through for the schema to reject,
// which is what keeps "2" an error rather than a silent `false`.
let normalizeBool = (string, schema: S.t<'value>) =>
  switch schema {
  | S.Boolean(_)
  | S.AnyOf({has: {boolean: true}}) =>
    switch string {
    | "t" | "1" => "true"
    | "f" | "0" => "false"
    | string => string
    }
  | _ => string
  }

// A union carrying its own refinement or conversion is a normal schema rather
// than a union (Sury's CODEC_SPEC.md), and rebuilding it from `anyOf` would
// drop what it carries. `decoder`/`encoder` are the compiled dispatch every
// union has, not own logic; `refiner` has no field on `S.untagged`.
let carriesOwnLogic = (schema: S.t<'value>) =>
  %raw(`s => s.refiner !== undefined`)(schema) || (schema->S.untag).to->Option.isSome

// Sury flattens nested unions and spells `S.option(X)` as an `X | undefined`
// union, and it reads an option or a single-type union as a whole - `S.option`
// is itself one of the three answers to what a blank means. A union mixing
// types has no single reading ("Ambiguous string -> boolean | string"), so
// there each member is wrapped on its own.
let coerceSchema = (schema: S.t<'value>): S.t<'value> =>
  switch schema {
  | S.AnyOf({anyOf}) if !(schema->carriesOwnLogic) =>
    let members = anyOf->Array.filter(member =>
      switch member {
      | S.Undefined(_) => false
      | _ => true
      }
    )
    let tags = members->Array.map(member => (member->S.untag).tag)
    switch (members->Array.get(0), tags->Array.get(0)) {
    | (Some(first), Some(firstTag)) =>
      if tags->Array.every(tag => tag === firstTag) {
        schema->coerceWith(first)
      } else {
        S.union(
          anyOf->Array.map(member =>
            switch member {
            | S.Undefined(_) => member
            | _ => member->coerceWith(member)
            }
          ),
        )->magic
      }
    | _ => schema
    }
  // A union carrying its own logic is left alone: there is no single member to
  // read the string as, and the JSON reading would be wrong for it.
  | S.AnyOf(_) => schema
  | leaf => schema->coerceWith(leaf)
  }

let get = (
  envSafe,
  name,
  schema,
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
  let isMissing = input === None
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
        envSafe->mixinMissingIssue({name: name})
        %raw(`undefined`)
      }
    }
  } else {
    let input = input->Option.map(string => string->normalizeBool(schema))
    try input->S.parseOrThrow(~to=schema->coerceSchema) catch {
    | S.Exn(error) => {
        envSafe->mixinInvalidIssue({name, error, input})
        %raw(`undefined`)
      }
    }
  }
}
