import budget_lab/database
import ext/snagx
import gleam/dynamic
import gleam/float
import gleam/option
import gleam/string
import sqlight
import tempo
import tempo/datetime

pub type ManualTransaction {
  ManualTransaction(
    id: Int,
    date: tempo.DateTime,
    amount: Float,
    note: option.Option(String),
  )
}

pub fn insert_transaction(conn, transaction: ManualTransaction) {
  sqlight.exec(
    "INSERT INTO manual_transactions ("
      <> database.transactions_columns
      <> ") VALUES ("
      <> [
      "'" <> datetime.to_string(transaction.date) <> "'",
      float.to_string(transaction.amount),
      case transaction.note {
        option.Some(note) -> "'" <> note <> "'"
        option.None -> "NULL"
      },
    ]
    |> string.join(",")
      <> ")",
    on: conn,
  )
  |> snagx.from_error(
    "Unable to insert new transaction into transactions db "
    <> string.inspect(transaction),
  )
}

fn transaction_decoder(row) {
  dynamic.decode4(
    ManualTransaction,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, datetime.from_dynamic_string),
    dynamic.element(2, dynamic.float),
    dynamic.element(3, dynamic.optional(dynamic.string)),
  )(row)
}

pub fn get_all_transactions(conn) {
  sqlight.query(
    "SELECT rowid, "
      <> database.transactions_columns
      <> " FROM manual_transactions",
    on: conn,
    with: [],
    expecting: transaction_decoder,
  )
  |> snagx.from_error("Failed to get all transactions from transaction db ")
}
