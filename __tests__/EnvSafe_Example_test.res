open Ava

test(`Works with Example code`, t => {
  let envSafe = EnvSafe.make(
    ~env=Obj.magic({
      "NODE_ENV": "development",
      "PORT": "80",
      "API_URL": "https://example.com/foo",
      "AUTH0_CLIENT_ID": "xxxxx",
      "AUTH0_DOMAIN": "xxxxx.auth0.com",
    }),
  )

  t->Assert.is(
    envSafe->EnvSafe.get(
      ~name="NODE_ENV",
      ~struct=S.union([S.literal(#production), S.literal(#development), S.literal(#test)]),
      ~devFallback=#development,
    ),
    #development,
    (),
  )
  t->Assert.is(
    envSafe->EnvSafe.get(~name="PORT", ~struct=S.int->S.Int.port, ~devFallback=3000),
    80,
    (),
  )
  t->Assert.is(
    envSafe->EnvSafe.get(
      ~name="API_URL",
      ~struct=S.string->S.String.url,
      ~devFallback="https://example.com/graphql",
    ),
    "https://example.com/foo",
    (),
  )
  t->Assert.is(envSafe->EnvSafe.get(~name="AUTH0_CLIENT_ID", ~struct=S.string), "xxxxx", ())
  t->Assert.is(envSafe->EnvSafe.get(~name="AUTH0_DOMAIN", ~struct=S.string), "xxxxx.auth0.com", ())
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  }, ())
})
