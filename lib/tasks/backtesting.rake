namespace :backtesting do
  desc "Importa velas históricas desde Massive API (uso manual)"
  task :import, [:symbol, :from_date, :to_date] => :environment do |_, args|
    symbol = args[:symbol] || "AAPL"
    from_date = args[:from_date] ? Date.parse(args[:from_date]) : 7.days.ago.to_date
    to_date = args[:to_date] ? Date.parse(args[:to_date]) : Date.today - 1.day

    puts "Importando #{symbol} desde #{from_date} a #{to_date}..."
    
    count = Backtesting::MassiveImporter.import_historical_range(symbol, from_date, to_date)
    puts "¡Completado! #{count} velas agregadas."
  end
end
