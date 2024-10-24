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
import simplifile
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
      <> transaction_categories_columns
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
      <> transaction_categories_columns
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

const categories_db = "transaction_categories.db"

pub fn connect_to_categories_db() {
  let _ = simplifile.create_directory_all(types.data_dir)

  let categories_db_path = types.data_dir <> "/" <> categories_db

  use conn <- result.map(
    sqlight.open("file:" <> categories_db_path)
    |> snagx.from_error(
      "Failed to connect to transactions db at " <> categories_db_path,
    ),
  )

  let _ = sqlight.exec(create_transaction_categories_table, on: conn)
  let _ = sqlight.exec(static_transaction_categories, on: conn)

  conn
}

pub fn connect_to_categories_test_db() {
  let _ = simplifile.create_directory_all(types.data_dir)

  let categories_db_path = types.data_dir <> "/transaction_categories_test.db"

  let assert Ok(conn) =
    sqlight.open("file:" <> categories_db_path)
    |> snagx.from_error(
      "Failed to connect to transactions db at " <> categories_db_path,
    )

  let _ = sqlight.exec("DROP TABLE transaction_categories", on: conn)
  let _ = sqlight.exec(create_transaction_categories_table, on: conn)
  let _ = sqlight.exec(static_transaction_categories, on: conn)

  conn
}

const create_transaction_categories_table = "
CREATE TABLE IF NOT EXISTS transaction_categories (
  regex TEXT NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT NOT NULL,
  transaction_type TEXT NOT NULL,
  PRIMARY KEY (regex)
)"

const transaction_categories_columns = "
  regex,
  category,
  subcategory,
  transaction_type
"

const static_transaction_categories = "
INSERT OR IGNORE INTO transaction_categories VALUES
  ('SAUBELS MARKET',                 'Food',           'Groceries',    'Expense'),
  ('ALDI',                           'Food',           'Groceries',    'Expense'),
  ('YORK GROCERY OUTLET',            'Food',           'Groceries',    'Expense'),
  ('BBS GROCE',                      'Food',           'Groceries',    'Expense'),
  ('BBs',                            'Food',           'Groceries',    'Expense'),
  ('GIANT',                          'Food',           'Groceries',    'Expense'),
  ('TRADER JOE',                     'Food',           'Groceries',    'Expense'),
  ('FOOD LION',                      'Food',           'Groceries',    'Expense'),
  ('PUBLIX',                         'Food',           'Groceries',    'Expense'),
  ('EVANS ORCHARD',                  'Food',           'Groceries',    'Expense'),
  ('KROGER',                         'Food',           'Groceries',    'Expense'),
  ('LEG UP FARMERS',                 'Food',           'Groceries',    'Expense'),
  ('MARKET HOUSE PICKL',             'Food',           'Groceries',    'Expense'),
  ('THE FRESH MARKET',               'Food',           'Groceries',    'Expense'),
  ('WHOLEFDS',                       'Food',           'Groceries',    'Expense'),
  ('grocery',                        'Food',           'Groceries',    'Expense'),
  ('Groceries',                      'Food',           'Groceries',    'Expense'),
  ('ROHRERSTOWN GRO',                'Food',           'Groceries',    'Expense'),
  ('York Market Pickles',            'Food',           'Groceries',    'Expense'),
  ('Lidl',                           'Food',           'Groceries',    'Expense'),
  ('Hillside',                       'Food',           'Groceries',    'Expense'),
  ('🐝',                             'Food',           'Groceries',    'Expense'),
  ('🥛',                             'Food',           'Groceries',    'Expense'),
  ('🍼',                             'Food',           'Groceries',    'Expense'),
  ('Milk',                           'Food',           'Groceries',    'Expense'),
  ('Perrydell farm',                 'Food',           'Groceries',    'Expense'),
  ('Godfrey bros',                   'Food',           'Groceries',    'Expense'),
  ('Cantelope',                      'Food',           'Groceries',    'Expense'),
  ('Watermelon',                     'Food',           'Groceries',    'Expense'),
  ('Dutch way farm',                 'Food',           'Groceries',    'Expense'),
  ('Wegmans',                        'Food',           'Groceries',    'Expense'),
  ('Ebenezer.{0,1}s',                'Food',           'Groceries',    'Expense'),
  ('Beezers',                        'Food',           'Groceries',    'Expense'),
  ('Sonnewald natural food',         'Food',           'Groceries',    'Expense'),
  ('FRESH MARKE',                    'Food',           'Groceries',    'Expense'),
  ('Tropical smoothie cafe',         'Food',           'Eating Out',   'Expense'),
  ('Gardinos pizza',                 'Food',           'Eating Out',   'Expense'),
  ('MONTE CARLO PIZZA',              'Food',           'Eating Out',   'Expense'),
  ('GRAETERS',                       'Food',           'Eating Out',   'Expense'),
  ('COOL DOUGH',                     'Food',           'Eating Out',   'Expense'),
  ('WENDYS',                         'Food',           'Eating Out',   'Expense'),
  ('THE BUBBLE ROOM',                'Food',           'Eating Out',   'Expense'),
  ('SMOOTHIE KING',                  'Food',           'Eating Out',   'Expense'),
  ('CHIPOTLE',                       'Food',           'Eating Out',   'Expense'),
  ('CHARLESTON COFFEE',              'Food',           'Eating Out',   'Expense'),
  ('CHICK-FIL-A',                    'Food',           'Eating Out',   'Expense'),
  ('TST* WIRED CUP',                 'Food',           'Eating Out',   'Expense'),
  ('AUNTIEANNES',                    'Food',           'Eating Out',   'Expense'),
  ('PANERA BREAD',                   'Food',           'Eating Out',   'Expense'),
  ('Tst\\* lunas',                   'Food',           'Eating Out',   'Expense'),
  ('Parma pizza',                    'Food',           'Eating Out',   'Expense'),
  ('Sq \\*molly&#39;s courtyard',    'Food',           'Eating Out',   'Expense'),
  ('Pizza',                          'Food',           'Eating Out',   'Expense'),
  ('🍕',                             'Food',           'Eating Out',   'Expense'),
  ('Soft Pretzel',                   'Food',           'Eating Out',   'Expense'),
  ('Chicken guy',                    'Food',           'Eating Out',   'Expense'),
  ('coffee',                         'Food',           'Eating Out',   'Expense'), 
  ('GRAND CENTRAL B',                'Food',           'Eating Out',   'Expense'),
  ('MARLOWS TAVERN',                 'Food',           'Eating Out',   'Expense'),
  ('Bovaconti Coffe',                'Food',           'Eating Out',   'Expense'),
  ('THE LOCAL GRIND',                'Food',           'Eating Out',   'Expense'),
  ('ATHENIAN GRILL',                 'Food',           'Eating Out',   'Expense'),
  ('MAYLYNN S CREAMER',              'Food',           'Eating Out',   'Expense'),
  ('YAMALLAMA GARAGE',               'Food',           'Eating Out',   'Expense'),
  ('SNAKEROOT BOTANIC',              'Food',           'Eating Out',   'Expense'),
  ('ROSIES PLACE MAIN STR',          'Food',           'Eating Out',   'Expense'),
  ('DOLLIES FARM LLC',               'Food',           'Eating Out',   'Expense'),
  ('THEFEED.COM',                    'Food',           'Eating Out',   'Expense'),
  ('WEAVER MARKETS INC',             'Food',           'Eating Out',   'Expense'),
  ('MILLIES LIVING CAFE',            'Food',           'Eating Out',   'Expense'),
  ('VINNY'S ITALIAN G',              'Food',           'Eating Out',   'Expense'),
  ('BRIDGE STREET CAFE',             'Food',           'Eating Out',   'Expense'),
  ('STARBUCKS',                      'Food',           'Eating Out',   'Expense'),
  ('Bellas of bristol', 'Food', 'Eating Out', 'Expense'),
  ('Wendy&#39;s', 'Food', 'Eating Out', 'Expense'),
  ('Javateas gourmet coffe', 'Food', 'Eating Out', 'Expense'),
  ('Old town road dairy', 'Food', 'Eating Out', 'Expense'),
  ('Plaza azteca', 'Food', 'Eating Out', 'Expense'),
  ('Cubby&#39;s ice cream cafe', 'Food', 'Eating Out', 'Expense'),
  ('Dairy queen', 'Food', 'Eating Out', 'Expense'),
  ('findlay marke', 'Food', 'Eating Out', 'Expense'),
  ('deeper roots coffe', 'Food', 'Eating Out', 'Expense'),
  ('em&#39;s sourdough bre', 'Food', 'Eating Out', 'Expense'),
  ('La Carreta', 'Food', 'Eating Out', 'Expense'),
  ('Mosbys pub', 'Food', 'Eating Out', 'Expense'),
  ('bagel',                          'Food',           'Eating Out',   'Expense'),
  ('aunt lydias pretze', 'Food', 'Eating Out', 'Expense'),
  ('sweet willows crea', 'Food', 'Eating Out', 'Expense'),
  ('white hart cafe', 'Food', 'Eating Out', 'Expense'),
  ('Willow street restaura', 'Food', 'Eating Out', 'Expense'),
  ('Tst* grand central bag', 'Food', 'Eating Out', 'Expense'),
  ('Tst* viet thai cafe',            'Food',           'Eating Out',   'Expense'),
  ('SHEETZ',                         'Transportation', 'Gas (Car)',    'Expense'),
  ('TURKEY HILL',                    'Transportation', 'Gas (Car)',    'Expense'),
  ('RUTTER',                         'Transportation', 'Gas (Car)',    'Expense'),
  ('BP#',                            'Transportation', 'Gas (Car)',    'Expense'),
  ('CIRCLE K',                       'Transportation', 'Gas (Car)',    'Expense'),
  ('SUNOCO',                         'Transportation', 'Gas (Car)',    'Expense'),
  ('RACETRAC',                       'Transportation', 'Gas (Car)',    'Expense'),
  ('PARKERS',                        'Transportation', 'Gas (Car)',    'Expense'),
  ('SHELL SERVICE STATION',          'Transportation', 'Gas (Car)',    'Expense'),
  ('Shell oil',                      'Transportation', 'Gas (Car)',    'Expense'),
  ('GO MART',                        'Transportation', 'Gas (Car)',    'Expense'),
  ('MARATHON PETRO',                 'Transportation', 'Gas (Car)',    'Expense'),
  ('Speedway',                       'Transportation', 'Gas (Car)',    'Expense'),
  ('Pilot 00002584',                 'Transportation', 'Gas (Car)',    'Expense'), 
  ('Marathon petro',                 'Transportation', 'Gas (Car)',    'Expense'),
  ('Wawa',                           'Transportation', 'Gas (Car)',    'Expense'),
  ('SAM&#39;S FUEL', 'Transportation', 'Gas (Car)', 'Expense'),
  ('Gulf oil', 'Transportation', 'Gas (Car)', 'Expense'),
  ('WEIGELS', 'Transportation', 'Gas (Car)', 'Expense'),
  ('Exxon', 'Transportation', 'Gas (Car)', 'Expense'),
  ('Samsclub .* gas', 'Transportation', 'Gas (Car)', 'Expense'),
  ('Conoco', 'Transportation', 'Gas (Car)', 'Expense'),
  ('TOM&#39;S ORBIT EXPRESS', 'Transportation', 'Gas (Car)', 'Expense'),
  ('Gas Sam&#39;s Club', 'Transportation', 'Gas (Car)', 'Expense'),
  ('PRICERITE YORK',                 'Discretionary', 'Shopping',      'Expense'),
  ('Finders Keepers',                'Discretionary', 'Shopping',      'Expense'),
  ('Fashion Cents',                  'Discretionary', 'Shopping',      'Expense'),
  ('MERCARI',                        'Discretionary', 'Shopping',      'Expense'),
  ('GABRIEL BROS',                   'Discretionary', 'Shopping',      'Expense'),
  ('ABERCROMBIE & FITCH',            'Discretionary', 'Shopping',      'Expense'),
  ('THRIFT',                         'Discretionary', 'Shopping',      'Expense'),
  ('MARSHALLS',                      'Discretionary', 'Shopping',      'Expense'),
  ('TARGET',                         'Discretionary', 'Shopping',      'Expense'),
  ('GOODWILL',                       'Discretionary', 'Shopping',      'Expense'),
  ('ROSS STORES',                    'Discretionary', 'Shopping',      'Expense'),
  ('Forever 21',                     'Discretionary', 'Shopping',      'Expense'),
  ('TJMAXX',                         'Discretionary', 'Shopping',      'Expense'),
  ('OLD NAVY',                       'Discretionary', 'Shopping',      'Expense'),
  ('THE SALVATION ARMY',             'Discretionary', 'Shopping',      'Expense'),
  ('Poshmark',                       'Discretionary', 'Shopping',      'Expense'),
  ('Plato&#39;s closet',             'Discretionary', 'Shopping',      'Expense'),
  ('Jcpenney.com',                   'Discretionary', 'Shopping',      'Expense'),
  ('H&amp;m',                        'Discretionary', 'Shopping',      'Expense'),
  ('H&m',                            'Discretionary', 'Shopping',      'Expense'),
  ('AIORI',                          'Discretionary', 'Shopping',      'Expense'),
  ('KOHL&#39;S',                     'Discretionary', 'Shopping',      'Expense'),
  ('flux footwear',                  'Discretionary', 'Shopping',      'Expense'),
  ('J crew',                         'Discretionary', 'Shopping',      'Expense'),
  ('American eagle outfitt',         'Discretionary', 'Shopping',      'Expense'),
  ('BED BATH & BEYOND',              'Discretionary', 'Shopping',      'Expense'),
  ('BEDBATH&amp;BEYOND',             'Discretionary', 'Shopping',      'Expense'),
  ('Hotel columbia collect',         'Discretionary', 'Shopping',      'Expense'),
  ('Joann stores',                   'Discretionary', 'Shopping',      'Expense'),
  ('gray apple market',              'Discretionary', 'Shopping',      'Expense'),
  ('Chevy chase hardware',           'Discretionary', 'Shopping',      'Expense'),
  ('Wiseway supply',                 'Discretionary', 'Shopping',      'Expense'),
  ('COMMUNITYAID',                   'Discretionary', 'Shopping',      'Expense'),
  ('OLLIES BARGAIN OUTLET',          'Discretionary', 'Shopping',      'Expense'),
  ('Ebay',                           'Discretionary', 'Shopping',      'Expense'),
  ('SQUARE CAT VINYL',               'Discretionary', 'Shopping',      'Expense'),
  ('Dollar tree', 'Discretionary', 'Shopping', 'Expense'),
  ('DOLLAR-GE', 'Discretionary', 'Shopping', 'Expense'),
  ('Etsy.com', 'Discretionary', 'Shopping', 'Expense'),
  ('Etsy inc seller fees', 'Discretionary', 'Shopping', 'Expense'),
  ('Amazon.com', 'Discretionary', 'Shopping', 'Expense'),
  ('AMZN', 'Discretionary', 'Shopping', 'Expense'),
  ('Five below', 'Discretionary', 'Shopping', 'Expense'),
  ('BURLINGTON', 'Discretionary', 'Shopping', 'Expense'),
  ('Hobby[\\s-]lobby', 'Discretionary', 'Shopping', 'Expense'),
  ('MICHAELS STORES', 'Discretionary', 'Shopping', 'Expense'),
  ('Dicks sporting goods', 'Discretionary', 'Shopping', 'Expense'),
  ('Dickssportinggoods.com', 'Discretionary', 'Shopping', 'Expense'),
  ('Books a million', 'Discretionary', 'Shopping', 'Expense'),
  ('Community Aid', 'Discretionary', 'Shopping', 'Expense'),
  ('Lifepath', 'Discretionary', 'Shopping', 'Expense'),
  ('Framework', 'Discretionary', 'Office', 'Expense'),
  ('Newegg', 'Discretionary', 'Office', 'Expense'),
  ('Fosiaudio', 'Discretionary', 'Office', 'Expense'),
  ('QUALITY INN',                'Event',          'Traveling',       'Expense'),
  ('Frontier abzepm',            'Event',          'Traveling',       'Expense'),
  ('Frontier airlines',          'Event',          'Traveling',       'Expense'),
  ('Best western',               'Event',          'Traveling',       'Expense'),
  ('Airbnb',                     'Event',          'Traveling',       'Expense'),
  ('La Quinta',                  'Event',          'Traveling',       'Expense'),
  ('SPOTIFY',                    'Discretionary',  'Music',           'Expense'),
  ('PRIME VIDEO',                'Discretionary',  'Entertainment',   'Expense'),
  ('Movie',                      'Discretionary',  'Entertainment',   'Expense'),
  ('Cinema',                     'Discretionary',  'Entertainment',   'Expense'),
  ('Steam\\s*Games',             'Discretionary',  'Entertainment',   'Expense'),
  ('Diaper',                     'Dependent',      'Baby Toiletry',   'Expense'),
  ('RebelStork',                 'Dependent',      'Baby Product',    'Expense'),
  ('AirDoctor',                  'Health',         'Health Product',  'Expense'),
  ('Clearly\\s*Filtered',        'Health',         'Health Product',  'Expense'),
  ('Comcast',                    'Utility',        'Internet',        'Expense'),
  ('First\\s*Energy',            'Utility',        'Electricity',     'Expense'),
  ('AMER ELECT PWR',             'Utility',        'Electricity',     'Expense'),
  ('Columbia\\s*Gas',            'Utility',        'Gas (Home)',      'Expense'),
  ('FIRSTMARK',                  'Education',      'Student Debt',    'External'),
  ('Supermaven',                 'Professional',   'Software Development', 'Expense'),
  ('Tello us',                   'Utility',        'Internet',        'Expense'),
  ('Advance Auto Parts',         'Transportation', 'Car Maintenance', 'Expense')
"
