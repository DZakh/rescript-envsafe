# ReScript `env`safe 🔒

Validate access to environment variables and parse them to the right type. Makes sure you don't accidentally deploy apps with missing or invalid environment variables.

```
========================================
❌ Invalid environment variables:
    API_URL ("http//example.com/graphql"): Invalid url
💨 Missing environment variables:
    MY_VAR: Disallowed empty string
    PORT: Missing value
========================================
```

## How to use

### Install

```sh
npm install rescript-env rescript-struct
```

Then add `rescript-env` and `rescript-struct` to `bs-dependencies` in your `bsconfig.json`:

```diff
{
  ...
+ "bs-dependencies": ["rescript-env", "rescript-struct"]
}
```

### Basic usage

```rescript
%%private(let envSafe = EnvSafe.make())

let nodeEnv =
  envSafe->EnvSafe.get(
    ~name="NODE_ENV",
    ~struct=S.union([
      S.literalVariant(String("production"), #production),
      S.literalVariant(String("development"), #development),
      S.literalVariant(String("test"), #test),
    ]),
    ~devFallback=#development,
    (),
  )
let port = envSafe->EnvSafe.get(~name="PORT", ~struct=S.int()->S.Int.port(), ~devFallback=3000, ())
let apiUrl =
  envSafe->EnvSafe.get(
    ~name="API_URL",
    ~struct=S.string()->S.String.url(),
    ~devFallback="https://example.com/graphql",
    (),
  )
let auth0ClientId = envSafe->EnvSafe.get(~name="AUTH0_CLIENT_ID", ~struct=S.string(), ())
let auth0Domain = envSafe->EnvSafe.get(~name="AUTH0_DOMAIN", ~struct=S.string(), ())

// It's important to close EnvSafe to report an error and exit the process.
envSafe->EnvSafe.close()
```

It defaults to using `process.env` as a base for plucking the vars, but it can be overridden like this:

```rescript
%%private(let envSafe = EnvSafe.make(~env=%raw("window.__ENVIRONMENT__"), ()))
```

// TODO: API reference
