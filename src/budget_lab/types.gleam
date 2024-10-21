pub const data_dir = "./data"

pub type Account {
  SoFiBankingJoint
  SoFiCreditJohn
  SoFiCreditJessica
  WhitakerJohn
  FultonJohn
  DiscoverCreditJohn
  DiscoverCreditJessica
  VenmoJessica
}

pub fn account_to_string(account: Account) -> String {
  case account {
    SoFiBankingJoint -> "Joint SoFi Banking"
    SoFiCreditJohn -> "John's SoFi Credit Card"
    SoFiCreditJessica -> "Jessica's SoFi Credit Card"
    WhitakerJohn -> "John's Whitaker Bank"
    FultonJohn -> "John's Fulton Bank"
    DiscoverCreditJohn -> "John's Discover Credit Card"
    DiscoverCreditJessica -> "Jessica's Discover Credit Card"
    VenmoJessica -> "Jessica's Venmo"
  }
}

pub fn account_from_string(string: String) -> Result(Account, Nil) {
  case string {
    "Joint SoFi Banking" -> Ok(SoFiBankingJoint)
    "John's SoFi Credit Card" -> Ok(SoFiCreditJohn)
    "Jessica's SoFi Credit Card" -> Ok(SoFiCreditJessica)
    "John's Whitaker Bank" -> Ok(WhitakerJohn)
    "John's Fulton Bank" -> Ok(FultonJohn)
    "John's Discover Credit Card" -> Ok(DiscoverCreditJohn)
    "Jessica's Discover Credit Card" -> Ok(DiscoverCreditJessica)
    "Jessica's Venmo" -> Ok(VenmoJessica)
    _ -> Error(Nil)
  }
}

pub type TransactionCategory {
  Food(subcategory: FoodSubcategory)
  Health(subcategory: HealthSubcategory)
  Utility(subcategory: UtilitySubcategory)
  Housing(subcategory: HousingSubcategory)
  Transportation(subcategory: TransportationSubcategory)
  Discretionary(subcategory: DiscretionarySubcategory)
  Education(subcategory: EducationSubcategory)
  Baby(subcategory: BabySubcategory)
  Event(subcategory: EventSubcategory)
  Professional(subcategory: ProfessionalSubcategory)
  Giving(subcategory: GivingSubcategory)
  Income(subcategory: IncomeSubcategory)
  Uncategorized
}

pub type FoodSubcategory {
  Groceries
  EatingOut
}

pub type HealthSubcategory {
  HealthInsurance
  Dentistry
  Doctor
  Supplements
  HealthProduct
  Hygiene
}

pub type UtilitySubcategory {
  Electricity
  Water
  GasHome
  Trash
  Sewer
  Internet
}

pub type HousingSubcategory {
  Rent
  Mortgage
  HomeInsurance
  HomeUpgrade
  HomeMaintenance
}

pub type TransportationSubcategory {
  GasCar
  CarInsurance
  LicensesAndRegistration
  CarMaintenance
}

pub type DiscretionarySubcategory {
  Shopping
  Office
  Music
  Entertainment
}

pub type EducationSubcategory {
  StudentDebt
}

pub type BabySubcategory {
  BabyProduct
  BabyToiletry
  BabyDoctor
  BabyShopping
}

pub type EventSubcategory {
  Vacation
  Holiday
  Traveling
  OneTimeEvent
}

pub type ProfessionalSubcategory {
  PrivacySoftware
  CreativeSoftware
  TaxServices
  SoftwareDevelopment
  InvestmentBusiness
}

pub type GivingSubcategory {
  Poverty
  Tithe
  Personal
}

pub type IncomeSubcategory {
  Salary
  Bonus
  OneTimeIncome
}

pub fn transaction_category_to_string(category: TransactionCategory) {
  case category {
    Food(Groceries) -> #("Food", "Groceries")
    Food(EatingOut) -> #("Food", "Eating Out")
    Health(HealthInsurance) -> #("Health", "Health Insurance")
    Health(Dentistry) -> #("Health", "Dentistry")
    Health(Doctor) -> #("Health", "Doctor")
    Health(Supplements) -> #("Health", "Supplements")
    Health(HealthProduct) -> #("Health", "Health Product")
    Health(Hygiene) -> #("Health", "Hygiene")
    Utility(Electricity) -> #("Utility", "Electricity")
    Utility(Water) -> #("Utility", "Water")
    Utility(GasHome) -> #("Utility", "Gas (Home)")
    Utility(Trash) -> #("Utility", "Trash")
    Utility(Sewer) -> #("Utility", "Sewer")
    Utility(Internet) -> #("Utility", "Internet")
    Housing(Rent) -> #("Housing", "Rent")
    Housing(Mortgage) -> #("Housing", "Mortgage")
    Housing(HomeInsurance) -> #("Housing", "Home Insurance")
    Housing(HomeUpgrade) -> #("Housing", "Home Upgrade")
    Housing(HomeMaintenance) -> #("Housing", "Home Maintenance")
    Transportation(GasCar) -> #("Transportation", "Gas (Car)")
    Transportation(CarInsurance) -> #("Transportation", "Car Insurance")
    Transportation(LicensesAndRegistration) -> #(
      "Transportation",
      "Licenses and Registration",
    )
    Transportation(CarMaintenance) -> #("Transportation", "Car Maintenance")
    Discretionary(Shopping) -> #("Discretionary", "Shopping")
    Discretionary(Office) -> #("Discretionary", "Office")
    Discretionary(Music) -> #("Discretionary", "Music")
    Discretionary(Entertainment) -> #("Discretionary", "Entertainment")
    Education(StudentDebt) -> #("Education", "Student Debt")
    Baby(BabyProduct) -> #("Baby", "Baby Product")
    Baby(BabyToiletry) -> #("Baby", "Baby Toiletry")
    Baby(BabyDoctor) -> #("Baby", "Baby Doctor")
    Baby(BabyShopping) -> #("Baby", "Baby Shopping")
    Event(Vacation) -> #("Event", "Vacation")
    Event(Holiday) -> #("Event", "Holiday")
    Event(Traveling) -> #("Event", "Traveling")
    Event(OneTimeEvent) -> #("Event", "One Time Event")
    Professional(PrivacySoftware) -> #("Professional", "Privacy Software")
    Professional(CreativeSoftware) -> #("Professional", "Creative Software")
    Professional(TaxServices) -> #("Professional", "Tax Services")
    Professional(SoftwareDevelopment) -> #(
      "Professional",
      "Software Development",
    )
    Professional(InvestmentBusiness) -> #("Professional", "Investment Business")
    Giving(Poverty) -> #("Giving", "Poverty")
    Giving(Tithe) -> #("Giving", "Tithe")
    Giving(Personal) -> #("Giving", "Personal")
    Income(Salary) -> #("Income", "Salary")
    Income(Bonus) -> #("Income", "Bonus")
    Income(OneTimeIncome) -> #("Income", "One Time Income")
    Uncategorized -> #("Uncategorized", "Uncategorized")
  }
}

pub fn transaction_category_from_string(
  category: String,
  subcategory: String,
) -> Result(TransactionCategory, Nil) {
  case category, subcategory {
    "Food", "Groceries" -> Ok(Food(Groceries))
    "Food", "Eating Out" -> Ok(Food(EatingOut))
    "Health", "Health Insurance" -> Ok(Health(HealthInsurance))
    "Health", "Dentistry" -> Ok(Health(Dentistry))
    "Health", "Doctor" -> Ok(Health(Doctor))
    "Health", "Supplements" -> Ok(Health(Supplements))
    "Health", "Health Product" -> Ok(Health(HealthProduct))
    "Health", "Hygiene" -> Ok(Health(Hygiene))
    "Utility", "Electricity" -> Ok(Utility(Electricity))
    "Utility", "Water" -> Ok(Utility(Water))
    "Utility", "Gas (Home)" -> Ok(Utility(GasHome))
    "Utility", "Trash" -> Ok(Utility(Trash))
    "Utility", "Sewer" -> Ok(Utility(Sewer))
    "Utility", "Internet" -> Ok(Utility(Internet))
    "Housing", "Rent" -> Ok(Housing(Rent))
    "Housing", "Mortgage" -> Ok(Housing(Mortgage))
    "Housing", "Home Insurance" -> Ok(Housing(HomeInsurance))
    "Housing", "Home Upgrade" -> Ok(Housing(HomeUpgrade))
    "Housing", "Home Maintenance" -> Ok(Housing(HomeMaintenance))
    "Transportation", "Gas (Car)" -> Ok(Transportation(GasCar))
    "Transportation", "Car Insurance" -> Ok(Transportation(CarInsurance))
    "Transportation", "Licenses and Registration" ->
      Ok(Transportation(LicensesAndRegistration))
    "Transportation", "Car Maintenance" -> Ok(Transportation(CarMaintenance))
    "Discretionary", "Shopping" -> Ok(Discretionary(Shopping))
    "Discretionary", "Office" -> Ok(Discretionary(Office))
    "Discretionary", "Music" -> Ok(Discretionary(Music))
    "Discretionary", "Entertainment" -> Ok(Discretionary(Entertainment))
    "Education", "Student Debt" -> Ok(Education(StudentDebt))
    "Baby", "Baby Product" -> Ok(Baby(BabyProduct))
    "Baby", "Baby Toiletry" -> Ok(Baby(BabyToiletry))
    "Baby", "Baby Doctor" -> Ok(Baby(BabyDoctor))
    "Baby", "Baby Shopping" -> Ok(Baby(BabyShopping))
    "Event", "Vacation" -> Ok(Event(Vacation))
    "Event", "Holiday" -> Ok(Event(Holiday))
    "Event", "Traveling" -> Ok(Event(Traveling))
    "Event", "One Time Event" -> Ok(Event(OneTimeEvent))
    "Professional", "Privacy Software" -> Ok(Professional(PrivacySoftware))
    "Professional", "Creative Software" -> Ok(Professional(CreativeSoftware))
    "Professional", "Tax Services" -> Ok(Professional(TaxServices))
    "Professional", "Software Development" ->
      Ok(Professional(SoftwareDevelopment))
    "Professional", "Investment Business" ->
      Ok(Professional(InvestmentBusiness))
    "Giving", "Poverty" -> Ok(Giving(Poverty))
    "Giving", "Tithe" -> Ok(Giving(Tithe))
    "Giving", "Personal" -> Ok(Giving(Personal))
    "Income", "Salary" -> Ok(Income(Salary))
    "Income", "Bonus" -> Ok(Income(Bonus))
    "Income", "One Time Income" -> Ok(Income(OneTimeIncome))
    "Uncategorized", "Uncategorized" -> Ok(Uncategorized)
    _, _ -> Error(Nil)
  }
}

pub type TransactionType {
  Expense
  SetAside
  External
}

pub fn transaction_type_from_string(string) {
  case string {
    "Expense" -> Ok(Expense)
    "Set Aside" -> Ok(SetAside)
    "External" -> Ok(External)
    _ -> Error(Nil)
  }
}

pub fn transaction_type_to_string(transaction_type) {
  case transaction_type {
    Expense -> "Expense"
    SetAside -> "Set Aside"
    External -> "External"
  }
}
