open Ava

ava->test(`Successfully get Int value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="INT_ENV", ~struct=S.int(), ()), 1, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Literal Int value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="INT_ENV", ~struct=S.literal(Int(1)), ()), 1, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Float value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="INT_ENV", ~struct=S.float(), ()), 1., ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Successfully get Literal Float value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="INT_ENV", ~struct=S.literal(Float(1.)), ()), 1., ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close()
  }, ())
})

ava->test(`Fails to get invalid number`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1_000",
    }),
    (),
  )

  t->Assert.is(envSafe->EnvSafe.get(~name="INT_ENV", ~struct=S.int(), ()), %raw(`undefined`), ())
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close()
    },
    ~expectations=ThrowsException.make(
      ~name="TypeError",
      ~message=String(`========================================
❌ Invalid environment variables:
    INT_ENV ("1_000"): Failed parsing at root. Reason: Expected Int, received NaN Literal (NaN)
========================================`),
      (),
    ),
    (),
  )
})

ava->test(`Fails to get missing number`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1_000",
    }),
    (),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(~name="MISSING_ENV", ~struct=S.int(), ()),
    %raw(`undefined`),
    (),
  )
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close()
    },
    ~expectations=ThrowsException.make(
      ~name="TypeError",
      ~message=String(`========================================
💨 Missing environment variables:
    MISSING_ENV: Missing value
========================================`),
      (),
    ),
    (),
  )
})
