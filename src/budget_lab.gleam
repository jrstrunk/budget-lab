import budget_lab/database
import gleam/io

pub fn main() {
  io.println("Hello from budget_lab!")
  database.connect()
}
