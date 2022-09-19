open Ava

ava->test(`Successfully get Bool value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "1",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.bool(), ()), true, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Bool value when the env is "t"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "t",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.bool(), ()), true, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Bool value when the env is "true"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "true",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.bool(), ()), true, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Bool value when the env is "false"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "false",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.bool(), ()), false, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Bool value when the env is "f"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "f",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.bool(), ()), false, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Bool value when the env is "0"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "0",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.bool(), ()), false, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Literal Bool (true) value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "1",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.literal(Bool(true)), ()), true, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Literal Bool (true) value when the env is "t"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "t",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.literal(Bool(true)), ()), true, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Literal Bool (true) value when the env is "true"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "true",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.literal(Bool(true)), ()), true, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Lietarl Bool (false) value when the env is "false"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "false",
    }),
    (),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.literal(Bool(false)), ()),
    false,
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Lietarl Bool (false) value when the env is "f"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "f",
    }),
    (),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.literal(Bool(false)), ()),
    false,
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Lietarl Bool (false) value when the env is "0"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "0",
    }),
    (),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.literal(Bool(false)), ()),
    false,
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Fails to get Bool value when the env is "2"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "2",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.bool(), ()), %raw(`undefined`), ())
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close()
    },
    ~expectations=ThrowsException.make(
      ~name="TypeError",
      ~message=String(`========================================
❌ Invalid environment variables:
    BOOL_ENV ("2"): Failed parsing at root. Reason: Expected Bool, received String
========================================`),
      (),
    ),
    (),
  )
})

ava->test(`Successfully get optional Bool value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "BOOL_ENV": "1",
    }),
    (),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(~name="BOOL_ENV", ~struct=S.option(S.bool()), ()),
    Some(true),
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})
