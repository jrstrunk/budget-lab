import budget_lab/transactions
import budget_lab/types
import gleam/option
import gleeunit
import gleeunit/should
import tempo/datetime

pub fn main() {
  gleeunit.main()
}

pub fn insert_transactions_round_trip_test() {
  let conn = transactions.connect_to_transactions_test_db()

  let transaction =
    transactions.Transaction(
      id: -1,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.0,
      description: "Test Transaction",
      category: types.Food(types.Groceries),
      category_override: False,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    )

  transactions.insert_transaction(conn, transaction)
  |> should.equal(Ok(Nil))

  let transaction =
    transactions.Transaction(
      id: -1,
      date: datetime.literal("2024-07-08T13:20:00Z"),
      amount: -24.76,
      description: "Test Transaction2",
      category: types.Food(types.Groceries),
      category_override: False,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    )

  transactions.insert_transaction(conn, transaction)
  |> should.equal(Ok(Nil))

  let assert Ok(transactions) = transactions.get_all_transactions(conn)

  transactions
  |> should.equal([
    transactions.Transaction(
      id: 1,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.0,
      description: "Test Transaction",
      category: types.Food(types.Groceries),
      category_override: False,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    ),
    transactions.Transaction(
      id: 2,
      date: datetime.literal("2024-07-08T13:20:00Z"),
      amount: -24.76,
      description: "Test Transaction2",
      category: types.Food(types.Groceries),
      category_override: False,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    ),
  ])
}

pub fn insert_manual_transactions_round_trip_test() {
  let conn = transactions.connect_to_transactions_test_db()

  let transaction =
    transactions.ManualTransaction(
      id: -1,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.0,
      note: option.None,
    )

  transactions.insert_manual_transaction(conn, transaction)
  |> should.equal(Ok(Nil))

  let transaction =
    transactions.ManualTransaction(
      id: -1,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.74,
      note: option.None,
    )

  transactions.insert_manual_transaction(conn, transaction)
  |> should.equal(Ok(Nil))
  let assert Ok(transactions) = transactions.get_all_manual_transactions(conn)

  transactions
  |> should.equal([
    transactions.ManualTransaction(
      id: 1,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.0,
      note: option.None,
    ),
    transactions.ManualTransaction(
      id: 2,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.74,
      note: option.None,
    ),
  ])
}

pub fn update_transactions_round_trip_test() {
  let conn = transactions.connect_to_transactions_test_db()

  let transaction =
    transactions.Transaction(
      id: -1,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.0,
      description: "Test Transaction",
      category: types.Food(types.Groceries),
      category_override: False,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    )

  transactions.insert_transaction(conn, transaction)
  |> should.equal(Ok(Nil))

  let transaction =
    transactions.Transaction(
      id: -1,
      date: datetime.literal("2024-07-08T13:20:00Z"),
      amount: -24.76,
      description: "Test Transaction2",
      category: types.Food(types.Groceries),
      category_override: False,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    )

  transactions.insert_transaction(conn, transaction)
  |> should.equal(Ok(Nil))

  let updated_transaction =
    transactions.Transaction(
      id: 2,
      date: datetime.literal("2024-07-08T13:20:00Z"),
      amount: -24.76,
      description: "Updated Desc",
      category: types.Utility(types.Internet),
      category_override: True,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    )

  let assert Ok(Nil) =
    transactions.update_transaction(conn, updated_transaction)

  let assert Ok(transactions) = transactions.get_all_transactions(conn)

  transactions
  |> should.equal([
    transactions.Transaction(
      id: 1,
      date: datetime.literal("2024-07-08T13:00:00Z"),
      amount: -24.0,
      description: "Test Transaction",
      category: types.Food(types.Groceries),
      category_override: False,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    ),
    transactions.Transaction(
      id: 2,
      date: datetime.literal("2024-07-08T13:20:00Z"),
      amount: -24.76,
      description: "Updated Desc",
      category: types.Utility(types.Internet),
      category_override: True,
      transaction_type: types.Expense,
      account: option.None,
      note: option.None,
      active: True,
    ),
  ])
}
