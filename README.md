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

Heavily inspired by the great project [envsafe](https://github.com/KATT/envsafe), but designed with care for ReScript users:

- **Always strict** - only access the variables you have defined
- Built for node.js **and** the browser
- **Composable** parsers with **[rescript-struct](https://github.com/DZakh/rescript-struct)**

## How to use

### Install

```sh
npm install rescript-envsafe rescript-struct
```

Then add `rescript-envsafe` and `rescript-struct` to `bs-dependencies` in your `bsconfig.json`:

```diff
{
  ...
+ "bs-dependencies": ["rescript-envsafe", "rescript-struct"],
+ "bsc-flags": ["-open RescriptStruct"],
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

// 🧠 If you forget to close `envSafe` then invalid vars end up being `undefined` leading to an expected runtime error.
envSafe->EnvSafe.close()
```

## API Reference

### **`EnvSafe.make`**

`(~env: EnvSafe.env=?, unit) => EnvSafe.t`

```rescript
%%private(let envSafe = EnvSafe.make(~env=%raw("window.__ENVIRONMENT__"), ()))
```

Creates `envSafe` to start working with environment variables. By default it uses `process.env` as a base for plucking the vars, but it can be overridden using the `env` argument.

### **`EnvSafe.get`**

`(EnvSafe.t, ~name: string, ~struct: S.t<'value>, ~allowEmpty: bool=?, ~devFallback: 'value=?, ~input: option<string>=?, unit) => 'value`

```rescript
let port = envSafe->EnvSafe.get(~name="PORT", ~struct=S.int()->S.Int.port(), ~devFallback=3000, ())
```

Gets an environment variable from `envSafe` applying coercion and parsing logic of `struct`.

#### Possible options

| Name          | Type          | Description                                                                                                                                                                                                                                                                        |
| ------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`        | `string`      | Name of the environment variable                                                                                                                                                                                                                                                   |
| `struct`      | `S.t<'value>` | A struct created with **[rescript-struct](https://github.com/DZakh/rescript-struct)**. It's used for coercion and parsing. For bool structs coerces `"0", "1", "true", "false", "t", "f"` to boolean values. For int and float structs coerces string to number.                   |
| `devFallback` | `'value=?`    | A fallback value to use only when `NODE_ENV` is not `production`. This is handy for env vars that are required for production environments, but optional for development and testing. If you need to set fallback value for all environments, you can use `S.defaulted` on struct. |
| `input`       | `string=?`    | As some environments don't allow you to dynamically read env vars, we can manually put it in as well. Example: `input=%raw("process.env.NEXT_PUBLIC_API_URL")`.                                                                                                                    |
| `allowEmpty`  | `bool=false`  | Default behavior is `false` which treats empty strings as the value is missing. if explicit empty strings are OK, pass in `true`.                                                                                                                                                  |

### **`EnvSafe.close`**

`(EnvSafe.t, unit) => unit`

```rescript
envSafe->EnvSafe.close()
```

It makes a readable summary of your issues, `console.error`-log an error, `window.alert()` with information about the missing envrionment variable if you're in the browser, throws an error (will exit the process with a code 1 in node).

> 🧠 If you forget to close `envSafe` then invalid vars end up being `undefined` leading to an expected runtime error.
