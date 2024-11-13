import ext/snagx
import fmglee as fmt
import gleam/result
import simplifile
import sqlight
import tempo/date

const db_dir = "data"

const db_name = "budget_lab.db"

pub fn connect() {
  let _ = simplifile.create_directory_all(db_dir)

  let db_path = db_dir <> "/" <> db_name

  use conn <- result.try(
    sqlight.open("file:" <> db_path)
    |> snagx.from_error("Failed to connect to database at " <> db_path),
  )

  use Nil <- result.try(
    sqlight.exec(create_transactions_table, on: conn)
    |> snagx.from_error("Unable to create transactions table"),
  )

  use Nil <- result.try(
    sqlight.exec(create_manual_transactions_table, on: conn)
    |> snagx.from_error("Unable to create manual transactions table"),
  )

  use Nil <- result.try(
    sqlight.exec(create_categories_table, on: conn)
    |> snagx.from_error("Unable to create categories table"),
  )

  use Nil <- result.try(
    sqlight.exec(create_account_balances_table, on: conn)
    |> snagx.from_error("Unable to create account balances table"),
  )

  use Nil <- result.try(
    sqlight.exec(create_account_categories_table, on: conn)
    |> snagx.from_error("Unable to create account categories table"),
  )

  use Nil <- result.try(
    sqlight.exec(insert_static_categories, on: conn)
    |> snagx.from_error("Unable to insert static categories"),
  )

  Ok(conn)
}

pub fn connect_to_transactions_test_db() {
  let assert Ok(conn) = sqlight.open(":memory:")
  let assert Ok(Nil) = sqlight.exec(create_transactions_table, on: conn)
  let assert Ok(Nil) = sqlight.exec(create_manual_transactions_table, on: conn)
  conn
}

pub fn connect_to_categories_test_db() {
  let assert Ok(conn) = sqlight.open(":memory:")
  let assert Ok(Nil) = sqlight.exec(create_categories_table, on: conn)
  let assert Ok(Nil) = sqlight.exec(insert_static_categories, on: conn)
  conn
}

const create_transactions_table = "
CREATE TABLE IF NOT EXISTS transactions (
  date TEXT NOT NULL,
  description TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT NOT NULL,
  category_override INTEGER NOT NULL,
  transaction_type TEXT NOT NULL,
  account TEXT,
  note TEXT,
  active INTEGER NOT NULL,
  PRIMARY KEY (date, description, amount)
)"

pub const transactions_columns = "
  date,
  description,
  amount,
  category,
  subcategory,
  category_override,
  transaction_type,
  account,
  note,
  active
"

const create_manual_transactions_table = "
CREATE TABLE IF NOT EXISTS manual_transactions (
  date TEXT NOT NULL,
  amount REAL NOT NULL,
  desc TEXT
)"

pub const manual_transactions_columns = "
  date,
  amount,
  desc
"

const create_account_balances_table = "
CREATE TABLE IF NOT EXISTS account_balances (
  date TEXT NOT NULL,
  account_id INTEGER NOT NULL,
  label TEXT NOT NULL,
  balance REAL NOT NULL,
  PRIMARY KEY (date, account_id)
)"

const create_account_categories_table = "
CREATE TABLE IF NOT EXISTS account_categories (
  account_id INTEGER NOT NULL,
  category TEXT NOT NULL,
  PRIMARY KEY (account_id)
)"

pub fn form_insert_account_balance(date, account_id, name, amount) {
  fmt.sprintf(
    "INSERT INTO account_balances (
      date,
      account_id,
      label,
      balance
    ) VALUES (
      %s,
      %d,
      %s,
      %f
    )",
    [
      fmt.S(date |> date.to_string),
      fmt.D(account_id),
      fmt.S(name),
      fmt.F(amount),
    ],
  )
}

pub fn form_get_account_id(label) {
  fmt.sprintf(
    "SELECT account_id 
    FROM account_balances 
    WHERE label = %s 
    ORDER BY row_num DESC
    LIMIT 1",
    [fmt.S(label)],
  )
}

pub const get_all_account_balances = "
SELECT b.date, b.account_id, b.label, b.balance, c.category
FROM account_balances b
LEFT JOIN account_categories c ON b.account_id = c.account_id
"

const create_categories_table = "
CREATE TABLE IF NOT EXISTS transaction_categories (
  regex TEXT NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT NOT NULL,
  transaction_type TEXT NOT NULL,
  PRIMARY KEY (regex)
)"

pub const transaction_categories_columns = "
  regex,
  category,
  subcategory,
  transaction_type
"

const insert_static_categories = "
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
  ('VINNY&#39;S ITALIAN G',          'Food',           'Eating Out',   'Expense'),
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
