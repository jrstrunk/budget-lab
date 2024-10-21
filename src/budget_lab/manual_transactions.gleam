import budget_lab/types
import ext/snagx
import gleam/dynamic
import gleam/float
import gleam/option
import gleam/result
import gleam/string
import simplifile
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
      <> transactions_columns
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
    "SELECT rowid, " <> transactions_columns <> " FROM manual_transactions",
    on: conn,
    with: [],
    expecting: transaction_decoder,
  )
  |> snagx.from_error("Failed to get all transactions from transaction db ")
}

const transactions_db = "manual_transactions.db"

const create_transactions_table = "
CREATE TABLE IF NOT EXISTS manual_transactions (
  date TEXT NOT NULL,
  amount REAL NOT NULL,
  note TEXT
)"

const transactions_columns = "
  date,
  amount,
  note
"

pub fn connect_to_transactions_db() {
  let _ = simplifile.create_directory_all(types.data_dir)

  let transactions_db_path = types.data_dir <> "/" <> transactions_db

  use conn <- result.map(
    sqlight.open("file:" <> transactions_db_path)
    |> snagx.from_error(
      "Failed to connect to transactions db " <> transactions_db_path,
    ),
  )

  let _ = sqlight.exec(create_transactions_table, on: conn)

  conn
}

pub fn connect_to_transactions_test_db() {
  let _ = simplifile.create_directory_all(types.data_dir)

  let transactions_db_path = types.data_dir <> "/transactions_test.db"

  let assert Ok(conn) = sqlight.open("file:" <> transactions_db_path)

  let _ = sqlight.exec("DROP TABLE transactions", on: conn)
  let _ = sqlight.exec("DROP TABLE manual_transactions", on: conn)
  let _ = sqlight.exec(create_transactions_table, on: conn)

  conn
}
