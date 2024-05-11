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
      "NODE_ENV",
      S.union([S.literal(#production), S.literal(#development), S.literal(#test)]),
      ~devFallback=#development,
    ),
    #development,
  )
  t->Assert.is(envSafe->EnvSafe.get("PORT", S.int->S.Int.port, ~devFallback=3000), 80)
  t->Assert.is(
    envSafe->EnvSafe.get(
      "API_URL",
      S.string->S.String.url,
      ~devFallback="https://example.com/graphql",
    ),
    "https://example.com/foo",
  )
  t->Assert.is(envSafe->EnvSafe.get("AUTH0_CLIENT_ID", S.string), "xxxxx")
  t->Assert.is(envSafe->EnvSafe.get("AUTH0_DOMAIN", S.string), "xxxxx.auth0.com")
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})
