ENV['MASSIVE_API_KEY'] = 'pC0Qw8pkdIlrcP9FYF2nFF6o3f8bZLxL'

max_date = Date.today
max_date -= 1.day while max_date.saturday? || max_date.sunday? || max_date == Date.today

["TSLA", "QQQ", "SPY", "AAPL"].each do |activo|
  puts "Haciendo: #{activo}"
  begin
    Backtesting::MassiveImporter.import_historical_range(activo, max_date - 7.days, max_date)
    puts "¡Éxito con #{activo}!"
    sleep 12
  rescue => e
    puts "Error: #{e.message}"
  end
end
puts "DONE"
