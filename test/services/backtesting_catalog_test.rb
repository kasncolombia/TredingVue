require "test_helper"

class Backtesting::CatalogTest < ActiveSupport::TestCase
  test "available? con símbolo válido y disponible" do
    assert Backtesting::Catalog.available?("AAPL")
    assert Backtesting::Catalog.available?("TSLA")
    assert Backtesting::Catalog.available?("spy") # Músculo de case insensitive
  end

  test "available? con símbolo válido no incluido" do
    assert_not Backtesting::Catalog.available?("UNKNOWN")
  end

  test "available? con símbolo nulo" do
    assert_not Backtesting::Catalog.available?(nil)
  end

  test "available? con cadena vacía o espacios" do
    assert_not Backtesting::Catalog.available?("")
    assert_not Backtesting::Catalog.available?("   ")
  end
end
