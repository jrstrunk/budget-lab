import budget_lab/database
import budget_lab/transactions
import budget_lab/types
import ext/dynamicx
import ext/snagx
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/string
import gsv
import snag
import sqlight
import tempo/date
import tempo/datetime
import tempo/offset
import tempo/time

pub fn ingest_csv(conn, csv) {
  use categorizers <- result.try(get_transaction_categories(conn))

  use rows <- result.map(
    gsv.to_lists(csv)
    |> result.map_error(fn(e) {
      snag.new(e) |> snag.layer("Failed to parse csv")
    }),
  )

  list.map(rows, fn(row) {
    case row {
      [date, description, amount, ..] -> {
        use date <- result.try(date.parse_any(date))
        use amount <- result.try(
          amount
          |> string.replace("$", "")
          |> string.replace(",", "")
          |> float.parse,
        )
        let category = categorize(categorizers, description)

        case category {
          types.Exclude -> Error(Nil)
          _ ->
            Ok(transactions.Transaction(
              id: -1,
              date: datetime.new(date, time.literal("00:00:00"), offset.local()),
              amount: amount,
              description: description,
              category: category,
              category_override: False,
              transaction_type: types.Expense,
              account: option.None,
              note: option.None,
              active: True,
            ))
        }
      }
      _ -> Error(Nil)
    }
  })
  |> result.values
}

pub fn categorize(categorizers: List(TransactionCategorizer), desc) {
  list.find(categorizers, fn(categorizer) {
    regex.check(categorizer.regex, desc |> string.lowercase)
  })
  |> result.map(fn(categorizer) { categorizer.category })
  |> result.unwrap(types.Uncategorized)
}

pub type TransactionCategorizer {
  TransactionCategorizer(
    regex: regex.Regex,
    regex_str: String,
    category: types.TransactionCategory,
    transaction_type: types.TransactionType,
  )
}

pub fn add_transaction_category(
  conn,
  regex_string,
  category: types.TransactionCategory,
  transaction_type: types.TransactionType,
) {
  let #(category, subcategory) = types.transaction_category_to_string(category)

  sqlight.exec(
    "INSERT INTO transaction_categories ("
      <> database.transaction_categories_columns
      <> ") VALUES ("
      <> [
      "'" <> regex_string <> "'",
      "'" <> category <> "'",
      "'" <> subcategory <> "'",
      "'" <> types.transaction_type_to_string(transaction_type) <> "'",
    ]
    |> string.join(",")
      <> ")",
    on: conn,
  )
}

pub fn get_transaction_categories(conn) {
  sqlight.query(
    "SELECT "
      <> database.transaction_categories_columns
      <> " FROM transaction_categories",
    on: conn,
    with: [],
    expecting: transaction_category_decoder,
  )
  |> result.map(fn(cats) {
    list.sort(cats, fn(a, b) {
      int.compare(string.length(b.regex_str), string.length(a.regex_str))
    })
  })
  |> snagx.from_error("Failed to get all transactions from transaction db ")
}

type TransactionCategorizerRaw {
  TransactionCategorizerRaw(
    regex: regex.Regex,
    regex_str: String,
    category: String,
    subcategory: String,
    transaction_type: types.TransactionType,
  )
}

fn transaction_category_decoder(row) {
  case
    dynamic.decode5(
      TransactionCategorizerRaw,
      dynamic.element(0, dynamicx.regex),
      dynamic.element(0, dynamic.string),
      dynamic.element(1, dynamic.string),
      dynamic.element(2, dynamic.string),
      dynamic.element(3, dynamicx.transaction_type),
    )(row)
  {
    Ok(TransactionCategorizerRaw(
      regex:,
      regex_str:,
      category:,
      subcategory:,
      transaction_type:,
    )) ->
      case types.transaction_category_from_string(category, subcategory) {
        Ok(category) ->
          Ok(TransactionCategorizer(
            regex:,
            regex_str:,
            category:,
            transaction_type:,
          ))
        Error(Nil) ->
          Error([
            dynamic.DecodeError(
              "transaction category",
              category <> subcategory,
              [],
            ),
          ])
      }
    Error(e) -> Error(e)
  }
}
