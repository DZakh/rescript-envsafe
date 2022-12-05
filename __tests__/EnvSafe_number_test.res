open Ava

test(`Successfully get Int value when the env is "1"`, t => {
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

test(`Successfully get Literal Int value when the env is "1"`, t => {
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

test(`Successfully get Float value when the env is "1"`, t => {
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

test(`Successfully get Literal Float value when the env is "1"`, t => {
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

test(`Fails to get invalid number`, t => {
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
    ~expectations={
      name: "TypeError",
      message: `========================================
❌ Invalid environment variables:
    INT_ENV ("1_000"): Failed parsing at root. Reason: Expected Int, received NaN Literal (NaN)
========================================`,
    },
    (),
  )
})

test(`Fails to get missing number`, t => {
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
