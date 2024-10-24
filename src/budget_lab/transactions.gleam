import budget_lab/database
import budget_lab/types
import ext/dynamicx
import ext/snagx
import gleam/bool
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/option
import gleam/string
import sqlight
import tempo
import tempo/date
import tempo/datetime

pub type Transaction {
  Transaction(
    id: Int,
    date: tempo.DateTime,
    description: String,
    amount: Float,
    category: types.TransactionCategory,
    category_override: Bool,
    transaction_type: types.TransactionType,
    account: option.Option(types.Account),
    note: option.Option(String),
    active: Bool,
  )
}

pub fn transaction_to_line(transaction: Transaction) {
  let #(category, subcategory) =
    types.transaction_category_to_string(transaction.category)

  [
    transaction.date |> datetime.get_date |> date.to_string,
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
  ]
}

pub type ManualTransaction {
  ManualTransaction(
    id: Int,
    date: tempo.DateTime,
    amount: Float,
    note: option.Option(String),
  )
}

pub fn update_transaction(conn, transaction: Transaction) {
  let #(category, subcategory) =
    types.transaction_category_to_string(transaction.category)

  sqlight.exec("UPDATE transactions SET 
    date = '" <> datetime.to_string(transaction.date) <> "',
    description = '" <> transaction.description <> "',
    amount = " <> float.to_string(transaction.amount) <> ",
    category = '" <> category <> "',
    subcategory = '" <> subcategory <> "',
    category_override = " <> int.to_string(bool.to_int(
    transaction.category_override,
  )) <> ",
    transaction_type = '" <> types.transaction_type_to_string(
    transaction.transaction_type,
  ) <> "',
    account = " <> case transaction.account {
    option.Some(account) -> "'" <> types.account_to_string(account) <> "'"
    option.None -> "NULL"
  } <> ",
    note = " <> case transaction.note {
    option.Some(note) -> "'" <> note <> "'"
    option.None -> "NULL"
  } <> ",
    active = " <> int.to_string(bool.to_int(transaction.active)) <> "
    WHERE rowid = " <> int.to_string(transaction.id), on: conn)
  |> snagx.from_error(
    "Unable to update transaction in transactions db "
    <> string.inspect(transaction),
  )
}

pub fn insert_transaction(conn, transaction: Transaction) {
  let #(category, subcategory) =
    types.transaction_category_to_string(transaction.category)

  sqlight.exec(
    "INSERT INTO transactions ("
      <> database.transactions_columns
      <> ") VALUES ("
      <> [
      "'" <> datetime.to_string(transaction.date) <> "'",
      "'" <> transaction.description <> "'",
      float.to_string(transaction.amount),
      "'" <> category <> "'",
      "'" <> subcategory <> "'",
      transaction.category_override |> bool.to_int |> int.to_string,
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
      <> database.manual_transactions_columns
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
    category_override: Bool,
    transaction_type: types.TransactionType,
    account: option.Option(types.Account),
    note: option.Option(String),
    active: Bool,
  )
}

fn transaction_decoder(row) {
  case
    dynamicx.decode11(
      TransactionRaw,
      dynamic.element(0, dynamic.int),
      dynamic.element(1, datetime.from_dynamic_string),
      dynamic.element(2, dynamic.string),
      dynamic.element(3, dynamic.float),
      dynamic.element(4, dynamic.string),
      dynamic.element(5, dynamic.string),
      dynamic.element(6, sqlight.decode_bool),
      dynamic.element(7, dynamicx.transaction_type),
      dynamic.element(8, dynamic.optional(dynamicx.account)),
      dynamic.element(9, dynamic.optional(dynamic.string)),
      dynamic.element(10, sqlight.decode_bool),
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
            category_override: transaction_raw.category_override,
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
    "SELECT rowid, " <> database.transactions_columns <> " FROM transactions",
    on: conn,
    with: [],
    expecting: transaction_decoder,
  )
  |> snagx.from_error("Failed to get all transactions from transaction db ")
}

pub fn get_all_manual_transactions(conn) {
  sqlight.query(
    "SELECT rowid, "
      <> database.manual_transactions_columns
      <> " FROM manual_transactions",
    on: conn,
    with: [],
    expecting: manual_transaction_decoder,
  )
  |> snagx.from_error(
    "Failed to get all manual transactions from transaction db ",
  )
}
