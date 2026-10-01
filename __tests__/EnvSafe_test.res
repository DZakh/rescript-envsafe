open Ava

test("Successfully get String value", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string->S.nonEmpty), S.NonEmpty("abc"))
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Successfully get String value when provided input", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get("STRING_ENV", S.string->S.nonEmpty, ~input=%raw(`"bar"`)),
    S.NonEmpty("bar"),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Fails to get String value when provided undefined input even with existing env", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get("STRING_ENV", S.string->S.nonEmpty, ~input=%raw(`undefined`)),
    %raw(`undefined`),
  )
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
💨 Missing environment variables:
    STRING_ENV: Missing value
========================================`,
    },
  )
})

test("Fails to get String value when env is an empty string and the schema rejects a blank", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string->S.nonEmpty), %raw(`undefined`))
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
❌ Invalid environment variables:
    STRING_ENV: Expected string.length >= 1, received ""
========================================`,
    },
  )
})

test("Successfully get String value when env is an empty string and the schema keeps a blank", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string->S.minLength(0)), "")
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test(`Successfully get String Literal ("") value when env is an empty string`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.literal("")), "")
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Fails to get value when env is missing", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("MISSING_ENV", S.string->S.nonEmpty), %raw(`undefined`))
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
💨 Missing environment variables:
    MISSING_ENV: Missing value
========================================`,
    },
  )
})

test("Uses devFallback value when env is missing", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(
      "MISSING_ENV",
      S.literal("invalid")->S.shape(_ => #polymorphicToTestFunctionType2),
      ~devFallback=#polymorphicToTestFunctionType,
    ),
    #polymorphicToTestFunctionType,
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Uses fallback value when env is missing", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(
      "MISSING_ENV",
      S.literal("invalid")->S.shape(_ => #polymorphicToTestFunctionType2),
      ~fallback=#polymorphicToTestFunctionType,
    ),
    #polymorphicToTestFunctionType,
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Uses fallback value when env is missing for union schema", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(
      "MISSING_ENV",
      S.union([S.literal("foo"), S.literal("bar")]),
      ~fallback="fallback",
    ),
    "fallback",
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

type fallbackTestVariant = ReadResult | FallbackResult | DevFallbackResult
test(
  "Uses devFallback value over fallback when env is missing and NODE_ENV is not set to production",
  t => {
    let envSafe = EnvSafe.make(
      ~env=Obj.magic({
        "STRING_ENV": "abc",
      }),
    )

    t->Assert.is(
      envSafe->EnvSafe.get(
        "MISSING_ENV",
        S.literal(ReadResult),
        ~fallback=FallbackResult,
        ~devFallback=DevFallbackResult,
      ),
      DevFallbackResult,
    )
    t->Assert.notThrows(() => {
      envSafe->EnvSafe.close
    })
  },
)

test("Doesn't use devFallback value when NODE_ENV is production", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
      "NODE_ENV": "production",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(
      "MISSING_ENV",
      S.literal("invalid")->S.shape(_ => #polymorphicToTestFunctionType2),
      ~devFallback=#polymorphicToTestFunctionType,
    ),
    %raw(`undefined`),
  )
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
💨 Missing environment variables:
    MISSING_ENV: Missing value
========================================`,
    },
  )
})

test("Successfully get optional value when env is missing", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("MISSING_ENV", S.string->S.option), None)
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Successfully get defaulted value when env is missing", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get("MISSING_ENV", S.string->S.option->S.Option.getOr("Defaulted")),
    "Defaulted",
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Closes with 1 valid, 2 missing and 3 invalid environment variables", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
      "BOOL_ENV1": "true",
      "BOOL_ENV2": "f",
      "EMPTY_STRING_ENV": "",
    }),
  )

  // valid 1
  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string->S.nonEmpty), S.NonEmpty("abc"))
  // invalid 1
  envSafe->EnvSafe.get("BOOL_ENV1", S.int)->ignore
  // invalid 2
  envSafe->EnvSafe.get("BOOL_ENV2", S.literal(true))->ignore
  // missing 1
  envSafe->EnvSafe.get("MISSING_ENV1", S.int)->ignore
  // missing 2
  envSafe->EnvSafe.get("MISSING_ENV2", S.string->S.nonEmpty)->ignore
  // invalid 3: a blank is the schema's call now, not a missing var
  envSafe->EnvSafe.get("EMPTY_STRING_ENV", S.string->S.nonEmpty)->ignore

  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
❌ Invalid environment variables:
    BOOL_ENV1: Expected int32, received "true"
    BOOL_ENV2: Expected "true", received "false"
    EMPTY_STRING_ENV: Expected string.length >= 1, received ""
💨 Missing environment variables:
    MISSING_ENV1: Missing value
    MISSING_ENV2: Missing value
========================================`,
    },
  )
})

test(`Doesn't show input value when it's missing for invalid env`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1_000",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get("MISSING_ENV", S.int->S.option->S.refine(_ => false, ~error="User error")),
    %raw(`undefined`),
  )
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
❌ Invalid environment variables:
    MISSING_ENV: User error
========================================`,
    },
  )
})

test("Applies preprocessor logic for union schemas separately", t => {
  let schema = S.union([
    S.bool->S.shape(bool => #Bool(bool)),
    S.string->S.shape(string => #String(string)),
    S.union([S.int->S.shape(int => #Int(int)), S.string->S.shape(string => #String(string))]),
  ])

  let envSafe = EnvSafe.make(~env=Obj.magic(Dict.make()))

  t->Assert.deepEqual(
    envSafe->EnvSafe.get("STRING_VALID_ENV", schema, ~input=Some("foo")),
    #String("foo"),
  )
  t->Assert.deepEqual(
    envSafe->EnvSafe.get("STRING_EMPTY_ENV", schema, ~input=Some("")),
    #String(""),
  )
  t->Assert.deepEqual(
    envSafe->EnvSafe.get("BOOL_VALID_ENV", schema, ~input=Some("f")),
    #Bool(false),
  )

  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test("Fails to access EnvSafe after close", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })

  t->Assert.throws(
    () => {envSafe->EnvSafe.get("STRING_ENV", S.string->S.nonEmpty)},
    ~expectations={
      message: "[rescript-envsafe] EnvSafe is closed. Make a new one to get access to environment variables.",
    },
  )
})

test("Coerces for a union carrying its own refinement", t => {
  let schema = S.union([S.int->S.castToUnknown, S.bigint->S.castToUnknown])->S.refine(
    value => value !== 99->Obj.magic,
    ~error="Not 99",
  )

  let envSafe = EnvSafe.make(~env=Obj.magic(Dict.make()))

  t->Assert.deepEqual(envSafe->EnvSafe.get("INT_ENV", schema, ~input=Some("1")), 1->Obj.magic)
  t->Assert.deepEqual(
    envSafe->EnvSafe.get("REFINED_ENV", schema, ~input=Some("99")),
    %raw(`undefined`),
  )
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      message: `========================================
❌ Invalid environment variables:
    REFINED_ENV: Not 99
========================================`,
    },
  )
})

// Known gap against the rescript-schema version, which coerced this through a
// preprocessor: a union that carries its own logic AND whose members convert
// gets no coercion, so "true" reads as the string member rather than the bool
// one. Coercing through a converting member would feed its output back into the
// union's own input, which is a worse answer than none.
test("Does not coerce for a union carrying its own refinement over converting members", t => {
  let schema = S.union([
    S.bool->S.shape(bool => #Bool(bool))->S.castToUnknown,
    S.string->S.minLength(0)->S.shape(string => #String(string))->S.castToUnknown,
  ])->S.refine(_ => true)

  let envSafe = EnvSafe.make(~env=Obj.magic(Dict.make()))

  t->Assert.deepEqual(
    envSafe->EnvSafe.get("BOOL_ENV", schema, ~input=Some("true")),
    #String("true")->Obj.magic,
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})
