open Ava

ava->test("Successfully get String value", t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(Envsafe.get(~key="STRING_ENV", ~struct=S.string(), ()), "abc", ())
})

ava->test("Fails to get String value when env is an empty string", t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "",
    }),
  })
  t->Assert.throws(() => {
    Envsafe.get(~key="STRING_ENV", ~struct=S.string(), ())->ignore
  }, ())
})

ava->test("Successfully get String value when env is an empty string and allowEmpty is true", t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "",
    }),
  })
  t->Assert.is(Envsafe.get(~key="STRING_ENV", ~struct=S.string(), ~allowEmpty=true, ()), "", ())
})

ava->test(
  `Successfully get String Literal ("") value when env is an empty string and allowEmpty is false`,
  t => {
    Envsafe.Config.set({
      env: Obj.magic({
        "STRING_ENV": "",
      }),
    })
    t->Assert.is(
      Envsafe.get(~key="STRING_ENV", ~struct=S.literal(String("")), ~allowEmpty=false, ()),
      "",
      (),
    )
  },
)

ava->test("Failse to get value when env is missing", t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.throws(() => {
    Envsafe.get(~key="MISSING_ENV", ~struct=S.string(), ())->ignore
  }, ())
})

ava->test("Successfully get optional value when env is missing", t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(Envsafe.get(~key="MISSING_ENV", ~struct=S.string()->S.option, ()), None, ())
})

ava->test("Successfully get defaulted value when env is missing", t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "STRING_ENV": "abc",
    }),
  })
  t->Assert.is(
    Envsafe.get(~key="MISSING_ENV", ~struct=S.string()->S.option->S.defaulted("Defaulted"), ()),
    "Defaulted",
    (),
  )
})

// TODO: Test normal struct
// TODO: Test number preprocessing
// TODO: Test unions
// TODO: Test option
