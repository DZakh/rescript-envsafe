[![npm](https://img.shields.io/npm/dm/rescript-envsafe)](https://www.npmjs.com/package/rescript-envsafe)

# ReScript `env`safe 🔒

Validate access to environment variables and parse them to the right type. Makes sure you don't accidentally deploy apps with missing or invalid environment variables.

```
========================================
❌ Invalid environment variables:
    API_URL ("http//example.com/graphql"): Invalid url
💨 Missing environment variables:
    PORT: Missing value
========================================
```

Heavily inspired by the great project [envsafe](https://github.com/KATT/envsafe), but designed with care for ReScript users:

- **Always strict** - only access the variables you have defined
- Built for node.js **and** the browser
- **Composable** parsers with **[Sury](https://github.com/DZakh/sury)**

## Basic usage

```rescript
%%private(let envSafe = EnvSafe.make())

let nodeEnv = envSafe->EnvSafe.get(
  "NODE_ENV",
  S.union([
    S.literal(#production),
    S.literal(#development),
    S.literal(#test),
  ]),
  ~devFallback=#development,
)
let port = envSafe->EnvSafe.get("PORT", S.port, ~fallback=S.Port(3000))
let apiUrl = envSafe->EnvSafe.get("API_URL", S.httpUrl, ~devFallback=S.HttpUrl("https://example.com/graphql"))
let auth0ClientId = envSafe->EnvSafe.get("AUTH0_CLIENT_ID", S.string)
let auth0Domain = envSafe->EnvSafe.get("AUTH0_DOMAIN", S.string)

// 🧠 If you forget to close `envSafe` then invalid vars end up being `undefined` leading to an expected runtime error.
envSafe->EnvSafe.close
```

## Install

```sh
npm install rescript-envsafe sury
```

Then add `rescript-envsafe` and `sury` to `dependencies` in your `rescript.json`:

```diff
{
  ...
+ "dependencies": ["rescript-envsafe", "sury"],
}
```

## API Reference

### **`EnvSafe.make`**

`(~env: EnvSafe.env=?) => EnvSafe.t`

```rescript
%%private(let envSafe = EnvSafe.make(~env=%raw("window.__ENVIRONMENT__")))
```

Creates `envSafe` to start working with environment variables. By default it uses `process.env` as a base for plucking the vars, but it can be overridden using the `env` argument.

### **`EnvSafe.get`**

`(EnvSafe.t, string, S.t<'value>, ~fallback: 'value=?, ~devFallback: 'value=?, ~input: option<string>=?) => 'value`

```rescript
let port = envSafe->EnvSafe.get("PORT", S.port, ~fallback=S.Port(3000))
```

Gets an environment variable from `envSafe` applying coercion and parsing logic of `schema`.

#### Possible options

| Name          | Type          | Description                                                                                                                                                                                                                                                                                                                                                           |
| ------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`        | `string`      | Name of the environment variable                                                                                                                                                                                                                                                                                                                                      |
| `schema`      | `S.t<'value>` | A schema created with **[Sury](https://github.com/DZakh/sury)**. It's used for coercion and parsing, through Sury's `S.env` codec. For bool schemas coerces `"0", "1", "true", "false", "t", "f"` to boolean values. For int, float and bigint schemas coerces string to number. For other non-string schemas the value is coerced using `JSON.parse` before being validated. The schema also says what a blank value means - see below. |
| `fallback`    | `'value=?`    | A fallback value when the environment variable is missing.                                                                                                                                                                                                                                                                                                            |
| `devFallback` | `'value=?`    | A fallback value to use only when `NODE_ENV` is not `production`. This is handy for env vars that are required for production environments, but optional for development and testing.                                                                                                                                                                                 |
| `input`       | `string=?`    | As some environments don't allow you to dynamically read env vars, we can manually put it in as well. Example: `input=%raw("process.env.NEXT_PUBLIC_API_URL")`.                                                                                                                                                                                                       |

#### Blank values

A blank value is the schema's call, not an option on `get`. A plain `S.string`
asks you to choose:

```rescript
envSafe->EnvSafe.get("NAME", S.string)
// Ambiguous "" for string. Should a blank input be rejected, kept, or read as
// absent? Choose with S.nonEmpty, S.minLength(0), or S.optional
```

```rescript
envSafe->EnvSafe.get("NAME", S.string->S.minLength(1)) // rejected, reported as invalid
envSafe->EnvSafe.get("NAME", S.string->S.minLength(0)) // kept as ""
envSafe->EnvSafe.get("NAME", S.option(S.string)) // read as None
```

Only a variable that isn't set at all is reported as missing.

### **`EnvSafe.close`**

`(EnvSafe.t) => unit`

```rescript
envSafe->EnvSafe.close
```

It makes a readable summary of your issues, `console.error`-log an error, `window.alert()` with information about the missing envrionment variable if you're in the browser, throws an error (will exit the process with a code 1 in node).

> 🧠 If you forget to close `envSafe` then invalid vars end up being `undefined` leading to an expected runtime error.
