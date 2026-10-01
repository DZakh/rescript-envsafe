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
  t->Assert.is(envSafe->EnvSafe.get("PORT", S.port, ~devFallback=S.Port(3000)), S.Port(80))
  t->Assert.is(
    envSafe->EnvSafe.get(
      "API_URL",
      S.httpUrl,
      ~devFallback=S.HttpUrl("https://example.com/graphql"),
    ),
    S.HttpUrl("https://example.com/foo"),
  )
  t->Assert.is(envSafe->EnvSafe.get("AUTH0_CLIENT_ID", S.string->S.nonEmpty), S.NonEmpty("xxxxx"))
  t->Assert.is(
    envSafe->EnvSafe.get("AUTH0_DOMAIN", S.string->S.nonEmpty),
    S.NonEmpty("xxxxx.auth0.com"),
  )
  t->Assert.notThrows(() => {
    envSafe->EnvSafe.close
  })
})
