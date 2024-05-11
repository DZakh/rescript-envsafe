open Ava

test(`Successfully get Int value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("INT_ENV", S.int), 1)
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test(`Successfully get Literal Int value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("INT_ENV", S.literal(1)), 1)
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test(`Successfully get Float value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("INT_ENV", S.float), 1.)
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test(`Successfully get Literal Float value when the env is "1"`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("INT_ENV", S.literal(1.)), 1.)
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})

test(`Fails to get invalid number`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1_000",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("INT_ENV", S.int), %raw(`undefined`))
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      name: "TypeError",
      message: `========================================
❌ Invalid environment variables:
    INT_ENV: Failed parsing at root. Reason: Expected Int, received "1_000"
========================================`,
    },
  )
})

test(`Fails to get missing number`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "INT_ENV": "1_000",
    }),
  )

  t->Assert.is(envSafe->EnvSafe.get("MISSING_ENV", S.int), %raw(`undefined`))
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
