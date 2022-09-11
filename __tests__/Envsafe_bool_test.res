open Ava

ava->test(`Successfully get Bool value when the env is "1"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "1",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.bool()), true, ())
})

ava->test(`Successfully get Bool value when the env is "t"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "t",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.bool()), true, ())
})

ava->test(`Successfully get Bool value when the env is "true"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "true",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.bool()), true, ())
})

ava->test(`Successfully get Bool value when the env is "false"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "false",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.bool()), false, ())
})

ava->test(`Successfully get Bool value when the env is "f"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "f",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.bool()), false, ())
})

ava->test(`Successfully get Bool value when the env is "0"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "0",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.bool()), false, ())
})

ava->test(`Successfully get Literal Bool (true) value when the env is "1"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "1",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.literal(Bool(true))), true, ())
})

ava->test(`Successfully get Literal Bool (true) value when the env is "t"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "t",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.literal(Bool(true))), true, ())
})

ava->test(`Successfully get Literal Bool (true) value when the env is "true"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "true",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.literal(Bool(true))), true, ())
})

ava->test(`Successfully get Lietarl Bool (false) value when the env is "false"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "false",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.literal(Bool(false))), false, ())
})

ava->test(`Successfully get Lietarl Bool (false) value when the env is "f"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "f",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.literal(Bool(false))), false, ())
})

ava->test(`Successfully get Lietarl Bool (false) value when the env is "0"`, t => {
  Envsafe.Config.set({
    env: Obj.magic({
      "BOOL_ENV": "0",
    }),
  })
  t->Assert.is(Envsafe.get(~key="BOOL_ENV", ~struct=S.literal(Bool(false))), false, ())
})
