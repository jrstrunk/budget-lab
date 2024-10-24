import budget_lab/database
import budget_lab/transaction_categories
import budget_lab/types
import gleam/list
import gleam/regex
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn insert_transaction_categories_round_trip_test() {
  let conn = database.connect_to_categories_test_db()

  let assert Ok(Nil) =
    transaction_categories.add_transaction_category(
      conn,
      "TEST MARKET",
      types.Food(types.Groceries),
      types.Expense,
    )

  let assert Ok(reg) =
    regex.compile(
      "TEST MARKET",
      regex.Options(case_insensitive: True, multi_line: False),
    )

  let assert Ok(categorizers) =
    transaction_categories.get_transaction_categories(conn)

  categorizers
  |> list.find(fn(categorizer) {
    categorizer
    == transaction_categories.TransactionCategorizer(
      regex: reg,
      regex_str: "TEST MARKET",
      category: types.Food(types.Groceries),
      transaction_type: types.Expense,
    )
  })
  |> should.equal(
    Ok(transaction_categories.TransactionCategorizer(
      regex: reg,
      regex_str: "TEST MARKET",
      category: types.Food(types.Groceries),
      transaction_type: types.Expense,
    )),
  )
}

pub fn insert_no_duplicates_test() {
  let conn = database.connect_to_categories_test_db()

  let assert Ok(Nil) =
    transaction_categories.add_transaction_category(
      conn,
      "TEST MARKET",
      types.Food(types.Groceries),
      types.Expense,
    )

  transaction_categories.add_transaction_category(
    conn,
    "TEST MARKET",
    types.Food(types.Groceries),
    types.Expense,
  )
  |> should.be_error
}

pub fn largest_first_test() {
  let conn = database.connect_to_categories_test_db()

  let really_long_regex_str =
    "HELLO TEST MARKET THIS REGEX IS SO LONG THAT THERE SHOULD BE NO OTHERS THAT SURPASS ITS POWER"

  let assert Ok(Nil) =
    transaction_categories.add_transaction_category(
      conn,
      really_long_regex_str,
      types.Food(types.Groceries),
      types.Expense,
    )

  let assert Ok([categorizer1, ..]) =
    transaction_categories.get_transaction_categories(conn)

  categorizer1.regex_str
  |> should.equal(really_long_regex_str)
}
