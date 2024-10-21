import budget_lab/types
import gleam/dynamic.{type Decoder, type Dynamic}
import gleam/list
import gleam/regex
import gleam/string

fn all_errors(
  result: Result(a, List(dynamic.DecodeError)),
) -> List(dynamic.DecodeError) {
  case result {
    Ok(_) -> []
    Error(errors) -> errors
  }
}

pub fn decode10(
  constructor: fn(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
  t6: Decoder(t6),
  t7: Decoder(t7),
  t8: Decoder(t8),
  t9: Decoder(t9),
  t10: Decoder(t10),
) -> Decoder(t) {
  fn(x: Dynamic) {
    case t1(x), t2(x), t3(x), t4(x), t5(x), t6(x), t7(x), t8(x), t9(x), t10(x) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g), Ok(h), Ok(i), Ok(j) ->
        Ok(constructor(a, b, c, d, e, f, g, h, i, j))
      a, b, c, d, e, f, g, h, i, j ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
            all_errors(f),
            all_errors(g),
            all_errors(h),
            all_errors(i),
            all_errors(j),
          ]),
        )
    }
  }
}

pub fn transaction_type(dy) {
  case dynamic.string(dy) {
    Ok(account_str) ->
      case types.transaction_type_from_string(account_str) {
        Ok(account) -> Ok(account)
        Error(Nil) ->
          Error([dynamic.DecodeError("transaction type", account_str, [])])
      }
    Error(e) -> Error(e)
  }
}

pub fn account(dy) {
  case dynamic.string(dy) {
    Ok(account_str) ->
      case types.account_from_string(account_str) {
        Ok(account) -> Ok(account)
        Error(Nil) ->
          Error([dynamic.DecodeError("account string", account_str, [])])
      }
    Error(e) -> Error(e)
  }
}

pub fn regex(dy) {
  case dynamic.string(dy) {
    Ok(regex_str) ->
      case regex.from_string(regex_str) {
        Ok(regex) -> Ok(regex)
        Error(e) ->
          Error([
            dynamic.DecodeError("regex string", regex_str, [string.inspect(e)]),
          ])
      }
    Error(e) -> Error(e)
  }
}
