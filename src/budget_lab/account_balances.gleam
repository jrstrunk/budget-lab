import budget_lab/database
import ext/dynamicx
import ext/snagx
import gleam/dynamic
import gleam/result
import snag
import sqlight

pub fn get_account_balances(conn) {
  sqlight.query(
    database.get_all_account_balances,
    on: conn,
    with: [],
    expecting: dynamicx.account_balance_decoder,
  )
  |> snagx.from_error("Failed to get all transactions from transaction db ")
}

pub fn insert_account_balance(conn, date, name, amount) {
  use account_id <- result.try(get_account_id(conn, name))

  sqlight.exec(
    database.form_insert_account_balance(date, account_id, name, amount),
    on: conn,
  )
  |> snagx.from_error(
    "Unable to insert new account balance into account balances db for " <> name,
  )
}

fn get_account_id(conn, label) {
  sqlight.query(
    database.form_get_account_id(label),
    on: conn,
    with: [],
    expecting: dynamic.int,
  )
  |> snagx.from_error("Failed to get account id for label " <> label)
  |> result.try(fn(account_ids) {
    case account_ids {
      [account_id] -> Ok(account_id)
      [_, ..] -> snag.error("Multiple account ids returned for label " <> label)
      [] -> snag.error("No account ids returned for label " <> label)
    }
  })
}
