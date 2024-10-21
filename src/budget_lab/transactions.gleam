import budget_lab/types
import ext/dynamicx
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

pub type Transaction {
  Transaction(
    id: Int,
    date: tempo.DateTime,
    description: String,
    amount: Float,
    category: types.TransactionCategory,
    transaction_type: types.TransactionType,
    account: option.Option(types.Account),
    note: option.Option(String),
    active: Bool,
  )
}

pub fn transaction_to_line(transaction: Transaction) {
  let #(category, subcategory) =
    types.transaction_category_to_string(transaction.category)

  string.join(
    [
      datetime.to_string(transaction.date),
      transaction.description,
      float.to_string(transaction.amount),
      category,
      subcategory,
      types.transaction_type_to_string(transaction.transaction_type),
      case transaction.account {
        option.Some(account) -> types.account_to_string(account)
        option.None -> ""
      },
      option.unwrap(transaction.note, ""),
    ],
    ",",
  )
}

pub type ManualTransaction {
  ManualTransaction(
    id: Int,
    date: tempo.DateTime,
    amount: Float,
    note: option.Option(String),
  )
}

pub fn insert_transaction(conn, transaction: Transaction) {
  let #(category, subcategory) =
    types.transaction_category_to_string(transaction.category)

  sqlight.exec(
    "INSERT INTO transactions ("
      <> transactions_columns
      <> ") VALUES ("
      <> [
      "'" <> datetime.to_string(transaction.date) <> "'",
      "'" <> transaction.description <> "'",
      float.to_string(transaction.amount),
      "'" <> category <> "'",
      "'" <> subcategory <> "'",
      "'"
        <> types.transaction_type_to_string(transaction.transaction_type)
        <> "'",
      case transaction.account {
        option.Some(account) -> "'" <> types.account_to_string(account) <> "'"
        option.None -> "NULL"
      },
      case transaction.note {
        option.Some(note) -> "'" <> note <> "'"
        option.None -> "NULL"
      },
      "1",
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

pub fn insert_manual_transaction(conn, transaction: ManualTransaction) {
  sqlight.exec(
    "INSERT INTO manual_transactions ("
      <> manual_transactions_columns
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

type TransactionRaw {
  TransactionRaw(
    id: Int,
    date: tempo.DateTime,
    description: String,
    amount: Float,
    category: String,
    subcategory: String,
    transaction_type: types.TransactionType,
    account: option.Option(types.Account),
    note: option.Option(String),
    active: Bool,
  )
}

fn transaction_decoder(row) {
  case
    dynamicx.decode10(
      TransactionRaw,
      dynamic.element(0, dynamic.int),
      dynamic.element(1, datetime.from_dynamic_string),
      dynamic.element(2, dynamic.string),
      dynamic.element(3, dynamic.float),
      dynamic.element(4, dynamic.string),
      dynamic.element(5, dynamic.string),
      dynamic.element(6, dynamicx.transaction_type),
      dynamic.element(7, dynamic.optional(dynamicx.account)),
      dynamic.element(8, dynamic.optional(dynamic.string)),
      dynamic.element(9, sqlight.decode_bool),
    )(row)
  {
    Ok(transaction_raw) -> {
      case
        types.transaction_category_from_string(
          transaction_raw.category,
          transaction_raw.subcategory,
        )
      {
        Ok(cate) ->
          Ok(Transaction(
            id: transaction_raw.id,
            date: transaction_raw.date,
            amount: transaction_raw.amount,
            description: transaction_raw.description,
            category: cate,
            transaction_type: transaction_raw.transaction_type,
            account: transaction_raw.account,
            note: transaction_raw.note,
            active: transaction_raw.active,
          ))

        Error(Nil) ->
          Error([
            dynamic.DecodeError(
              "transaction category",
              transaction_raw.category <> transaction_raw.subcategory,
              [],
            ),
          ])
      }
    }

    Error(e) -> Error(e)
  }
}

fn manual_transaction_decoder(row) {
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
    "SELECT rowid, " <> transactions_columns <> " FROM transactions",
    on: conn,
    with: [],
    expecting: transaction_decoder,
  )
  |> snagx.from_error("Failed to get all transactions from transaction db ")
}

pub fn get_all_manual_transactions(conn) {
  sqlight.query(
    "SELECT rowid, "
      <> manual_transactions_columns
      <> " FROM manual_transactions",
    on: conn,
    with: [],
    expecting: manual_transaction_decoder,
  )
  |> snagx.from_error(
    "Failed to get all manual transactions from transaction db ",
  )
}

const transactions_db = "transactions.db"

const create_transactions_table = "
CREATE TABLE IF NOT EXISTS transactions (
  date TEXT NOT NULL,
  description TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT NOT NULL,
  transaction_type TEXT NOT NULL,
  account TEXT,
  note TEXT,
  active INTEGER NOT NULL
)"

const transactions_columns = "
  date,
  description,
  amount,
  category,
  subcategory,
  transaction_type,
  account,
  note,
  active
"

const create_manual_transactions_table = "
CREATE TABLE IF NOT EXISTS manual_transactions (
  date TEXT NOT NULL,
  amount REAL NOT NULL,
  note TEXT
)"

const manual_transactions_columns = "
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
      "Failed to connect to transactions db at " <> transactions_db_path,
    ),
  )

  let _ = sqlight.exec(create_transactions_table, on: conn)
  let _ = sqlight.exec(create_manual_transactions_table, on: conn)

  conn
}

pub fn connect_to_transactions_test_db() {
  let _ = simplifile.create_directory_all(types.data_dir)

  let transactions_db_path = types.data_dir <> "/transactions_test.db"

  let assert Ok(conn) = sqlight.open("file:" <> transactions_db_path)

  let _ = sqlight.exec("DROP TABLE transactions", on: conn)
  let _ = sqlight.exec(create_transactions_table, on: conn)

  let _ = sqlight.exec("DROP TABLE manual_transactions", on: conn)
  let _ = sqlight.exec(create_manual_transactions_table, on: conn)

  conn
}
