open Ava

test("Successfully get String value", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string), "abc", ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test("Successfully get String value when provided input", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string, ~input=%raw(`"bar"`)), "bar", ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test("Fails to get String value when provided undefined input even with existing env", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get("STRING_ENV", S.string, ~input=%raw(`undefined`)),
    %raw(`undefined`),
    (),
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
    (),
  )
})

test("Fails to get String value when env is an empty string", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string), %raw(`undefined`), ())
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
💨 Missing environment variables:
    STRING_ENV: Disallowed empty string
========================================`,
    },
    (),
  )
})

test("Successfully get String value when env is an empty string and allowEmpty is true", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string, ~allowEmpty=true), "", ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test(
  `Successfully get String Literal ("") value when env is an empty string and allowEmpty is false`,
  t => {
    let envSafe = EnvSafe.make(
      ~env=Obj.magic({
        "STRING_ENV": "",
      }),
    )

    t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.literal(""), ~allowEmpty=false), "", ())
    t->Assert.notThrows(() => {
      envSafe->EnvSafe.close
    }, ())
  },
)

test("Fails to get value when env is missing", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("MISSING_ENV", S.string), %raw(`undefined`), ())
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
    (),
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
      S.literal("invalid")->S.variant(_ => #polymorphicToTestFunctionType2),
      ~devFallback=#polymorphicToTestFunctionType,
    ),
    #polymorphicToTestFunctionType,
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
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
      S.literal("invalid")->S.variant(_ => #polymorphicToTestFunctionType2),
      ~fallback=#polymorphicToTestFunctionType,
    ),
    #polymorphicToTestFunctionType,
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
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
      (),
    )
    t->Assert.notThrows(() => {
      envSafe->EnvSafe.close
    }, ())
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
      S.literal("invalid")->S.variant(_ => #polymorphicToTestFunctionType2),
      ~devFallback=#polymorphicToTestFunctionType,
    ),
    %raw(`undefined`),
    (),
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
    (),
  )
})

test("Successfully get optional value when env is missing", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("MISSING_ENV", S.string->S.option), None, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
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
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test("Closes with 1 valid, 3 missing and 2 invalid environment variables", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
      "BOOL_ENV1": "true",
      "BOOL_ENV2": "f",
      "EMPTY_STRING_ENV": "",
    }),
  )

  // valid 1
  t->Assert.is(envSafe->EnvSafe.get("STRING_ENV", S.string), "abc", ())
  // invalid 1
  envSafe->EnvSafe.get("BOOL_ENV1", S.int)->ignore
  // invalid 2
  envSafe->EnvSafe.get("BOOL_ENV2", S.literal(true))->ignore
  // missing 1
  envSafe->EnvSafe.get("MISSING_ENV1", S.int)->ignore
  // missing 2
  envSafe->EnvSafe.get("MISSING_ENV2", S.string)->ignore
  // missing 3
  envSafe->EnvSafe.get("EMPTY_STRING_ENV", S.string)->ignore

  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
❌ Invalid environment variables:
    BOOL_ENV1: Failed parsing at root. Reason: Expected Int, received "true"
    BOOL_ENV2: Failed parsing at root. Reason: Expected true, received false
💨 Missing environment variables:
    MISSING_ENV1: Missing value
    MISSING_ENV2: Missing value
    EMPTY_STRING_ENV: Disallowed empty string
========================================`,
    },
    (),
  )
})

test(`Doesn't show input value when it's missing for invalid env`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1_000",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get("MISSING_ENV", S.int->S.option->S.refine(s => _ => s.fail("User error"))),
    %raw(`undefined`),
    (),
  )
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
❌ Invalid environment variables:
    MISSING_ENV: Failed parsing at root. Reason: User error
========================================`,
    },
    (),
  )
})

test("Applies preprocessor logic for union schemas separately", t => {
  let schema = S.union([
    S.bool->S.variant(bool => #Bool(bool)),
    S.string->S.variant(string => #String(string)),
    S.union([S.int->S.variant(int => #Int(int)), S.string->S.variant(string => #String(string))]),
  ])

  let envSafe = EnvSafe.make(~env=Obj.magic(Js.Dict.empty()))

  t->Assert.deepEqual(
    envSafe->EnvSafe.get("STRING_VALID_ENV", schema, ~input=Some("foo")),
    #String("foo"),
    (),
  )
  t->Assert.deepEqual(
    envSafe->EnvSafe.get("STRING_EMPTY_ENV", schema, ~input=Some(""), ~allowEmpty=true),
    #String(""),
    (),
  )
  t->Assert.deepEqual(
    envSafe->EnvSafe.get("BOOL_VALID_ENV", schema, ~input=Some("f")),
    #Bool(false),
    (),
  )

  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test("Fails to access EnvSafe after close", t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "STRING_ENV": "abc",
    }),
  )

  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())

  t->Assert.throws(
    () => {envSafe->EnvSafe.get("STRING_ENV", S.string)},
    ~expectations={
      message: "[rescript-envsafe] EnvSafe is closed. Make a new one to get access to environment variables.",
    },
    (),
  )
})
