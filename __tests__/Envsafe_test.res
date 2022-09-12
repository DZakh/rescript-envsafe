open Ava

ava->test("Successfully get String value", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(EnvSafe.get(~key="STRING_ENV", ~struct=S.string(), ()), "abc", ())
})

ava->test("Successfully get String value when provided input", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(
    EnvSafe.get(~key="STRING_ENV", ~struct=S.string(), ~input=%raw(`"bar"`), ()),
    "bar",
    (),
  )
})

ava->test("Fails to get String value when provided undefined input even with existing env", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.throws(() => {
    EnvSafe.get(~key="STRING_ENV", ~struct=S.string(), ~input=%raw(`undefined`), ())->ignore
  }, ())
})

ava->test("Fails to get String value when env is an empty string", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "",
    }),
  })
  t->Assert.throws(() => {
    EnvSafe.get(~key="STRING_ENV", ~struct=S.string(), ())->ignore
  }, ())
})

ava->test("Successfully get String value when env is an empty string and allowEmpty is true", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "",
    }),
  })
  t->Assert.is(EnvSafe.get(~key="STRING_ENV", ~struct=S.string(), ~allowEmpty=true, ()), "", ())
})

ava->test(
  `Successfully get String Literal ("") value when env is an empty string and allowEmpty is false`,
  t => {
    EnvSafe.Config.set({
      env: Obj.magic({
        "STRING_ENV": "",
      }),
    })
    t->Assert.is(
      EnvSafe.get(~key="STRING_ENV", ~struct=S.literal(String("")), ~allowEmpty=false, ()),
      "",
      (),
    )
  },
)

ava->test("Failse to get value when env is missing", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.throws(() => {
    EnvSafe.get(~key="MISSING_ENV", ~struct=S.string(), ())->ignore
  }, ())
})

ava->test("Uses devFallback value when env is missing", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(
    EnvSafe.get(
      ~key="MISSING_ENV",
      ~struct=S.literalVariant(String("invalid"), #polymorphicToTestFunctionType),
      ~devFallback=#polymorphicToTestFunctionType,
      (),
    ),
    #polymorphicToTestFunctionType,
    (),
  )
})

ava->test("Doesn't use devFallback value when NODE_ENV is production", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
      "NODE_ENV": "production",
    }),
  })
  t->Assert.throws(() => {
    EnvSafe.get(
      ~key="MISSING_ENV",
      ~struct=S.literalVariant(String("invalid"), #polymorphicToTestFunctionType),
      ~devFallback=#polymorphicToTestFunctionType,
      (),
    )->ignore
  }, ())
})

ava->test("Successfully get optional value when env is missing", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(EnvSafe.get(~key="MISSING_ENV", ~struct=S.string()->S.option, ()), None, ())
})

ava->test("Successfully get defaulted value when env is missing", t => {
  EnvSafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(
    EnvSafe.get(~key="MISSING_ENV", ~struct=S.string()->S.option->S.defaulted("Defaulted"), ()),
    "Defaulted",
    (),
  )
})

// TODO: Test normal struct
// TODO: Test number preprocessing
// TODO: Test unions
// TODO: Test option
