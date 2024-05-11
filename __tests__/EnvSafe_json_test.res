open Ava

test(`Uses JSON parsing with object schema`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "OBJ_ENV": `{"foo":true}`,
    }),
  )

  t->Assert.deepEqual(
    envSafe->EnvSafe.get("OBJ_ENV", S.object(s => s.field("foo", S.bool))),
    true,
    (),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test(`Uses JSON parsing with array schema`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "ENV": `[1, 2]`,
    }),
  )

  t->Assert.deepEqual(envSafe->EnvSafe.get("ENV", S.array(S.int)), [1, 2], ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test(`Uses JSON parsing with unknown schema`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "ENV": `[1, 2]`,
    }),
  )

  t->Assert.deepEqual(envSafe->EnvSafe.get("ENV", S.unknown), [1, 2]->Obj.magic, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test(`Uses JSON parsing with JSON schema`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "ENV": `[1, 2]`,
    }),
  )

  t->Assert.deepEqual(envSafe->EnvSafe.get("ENV", S.json), [1, 2]->Obj.magic, ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})

test(`Doens't use JSON parsing with never schema`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "ENV": `[1, 2]`,
    }),
  )

  t->Assert.deepEqual(envSafe->EnvSafe.get("ENV", S.never), %raw(`undefined`), ())
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      message: `========================================
❌ Invalid environment variables:
    ENV: Failed parsing at root. Reason: Expected Never, received "[1, 2]"
========================================`,
    },
    (),
  )
})

test(`Fails with invalid json string`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "ENV": `[1, 2],`,
    }),
  )

  t->Assert.deepEqual(envSafe->EnvSafe.get("ENV", S.array(S.int)), %raw(`undefined`), ())
  t->Assert.throws(
    () => {
      envSafe->EnvSafe.close
    },
    ~expectations={
      message: `========================================
❌ Invalid environment variables:
    ENV: Failed parsing at root. Reason: Expected Array(Int), received "[1, 2],"
========================================`,
    },
    (),
  )
})
