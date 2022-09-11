// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var S = require("rescript-struct/src/S.bs.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");

var Env = {};

var configRef = {
  contents: {}
};

function set(config) {
  configRef.contents = config;
}

function reset(param) {
  configRef.contents = {};
}

function getEnv(param) {
  return Belt_Option.getWithDefault(configRef.contents.env, process.env);
}

function get(key, struct, allowEmptyOpt, param) {
  var allowEmpty = allowEmptyOpt !== undefined ? allowEmptyOpt : false;
  return S.Result.getExn(S.parseWith(getEnv(undefined)[key], S.advancedPreprocess(struct, (function (struct) {
                        var match = S.classify(struct);
                        var match$1 = S.Literal.classify(struct);
                        var exit = 0;
                        if (typeof match === "number") {
                          switch (match) {
                            case /* String */2 :
                                if (allowEmpty === false) {
                                  return {
                                          TAG: /* Sync */0,
                                          _0: (function (unknown) {
                                              if (unknown === "") {
                                                return ;
                                              } else {
                                                return unknown;
                                              }
                                            })
                                        };
                                }
                                exit = 1;
                                break;
                            case /* Int */3 :
                            case /* Float */4 :
                                exit = 3;
                                break;
                            case /* Bool */5 :
                                exit = 2;
                                break;
                            case /* Literal */6 :
                                if (match$1 !== undefined && typeof match$1 !== "number") {
                                  switch (match$1.TAG | 0) {
                                    case /* Int */1 :
                                    case /* Float */2 :
                                        exit = 3;
                                        break;
                                    case /* Bool */3 :
                                        exit = 2;
                                        break;
                                    default:
                                      exit = 1;
                                  }
                                } else {
                                  exit = 1;
                                }
                                break;
                            case /* Never */0 :
                            case /* Unknown */1 :
                            case /* Date */7 :
                                exit = 1;
                                break;
                            
                          }
                        } else {
                          exit = 1;
                        }
                        switch (exit) {
                          case 1 :
                              return {
                                      TAG: /* Sync */0,
                                      _0: (function (unknown) {
                                          return unknown;
                                        })
                                    };
                          case 2 :
                              return {
                                      TAG: /* Sync */0,
                                      _0: (function (unknown) {
                                          switch (unknown) {
                                            case "0" :
                                            case "f" :
                                            case "false" :
                                                return false;
                                            case "1" :
                                            case "t" :
                                            case "true" :
                                                return true;
                                            default:
                                              return unknown;
                                          }
                                        })
                                    };
                          case 3 :
                              return {
                                      TAG: /* Sync */0,
                                      _0: (function (unknown) {
                                          return (+unknown);
                                        })
                                    };
                          
                        }
                      }), undefined, undefined)));
}

var Config = {
  set: set,
  reset: reset
};

exports.Env = Env;
exports.Config = Config;
exports.get = get;
/* S Not a pure module */
