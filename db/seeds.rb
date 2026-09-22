puts "Sembrando base de datos enriquecida para AI Trading Journal..."

# Usuario principal admin
admin_user = User.find_or_initialize_by(email: "admin@admin.com")
admin_user.name                 = "System Admin"
admin_user.password             = "password123"
admin_user.password_confirmation= "password123"
admin_user.role                 = "admin"
admin_user.timezone             = "America/Mexico_City"
admin_user.preferred_currency   = "USD"
admin_user.initial_capital      = 50_000
admin_user.onboarding_completed = true
admin_user.trader_type          = "Futures"
admin_user.main_market          = "NQ / MNQ (Nasdaq 100)"
admin_user.trading_goal         = "Gestionar plataforma y comunidad"
admin_user.save!

# Usuario principal demo
demo_user = User.find_or_initialize_by(email: "trader@coachtrading.com")
demo_user.name                  = "Trader Demo"
demo_user.password              = "password123"
demo_user.password_confirmation = "password123"
demo_user.role                  = "user"
demo_user.timezone              = "America/Mexico_City"
demo_user.preferred_currency    = "USD"
demo_user.initial_capital       = 10_000
demo_user.onboarding_completed  = true
demo_user.trader_type           = "Futures"
demo_user.main_market           = "NQ / MNQ (Nasdaq 100)"
demo_user.trading_goal          = "Mejorar disciplina y frenar el revenge trading"
demo_user.save!

# Asegurar que TODOS los usuarios registrados tengan datos de prueba
target_users = User.all.to_a
target_users << demo_user unless target_users.include?(demo_user)

# Limpieza previa de datos dependientes (evita errores de FK en re-seeds)
ReviewRequest.destroy_all
TradeShare.destroy_all
Reaction.destroy_all
Comment.destroy_all
Post.destroy_all
Message.destroy_all
ChatRoom.destroy_all
Enrollment.destroy_all
Classroom.destroy_all
Resource.destroy_all

target_users.uniq.each do |user|
  puts "Generando datos para usuario: #{user.email}"
  
  # Limpieza previa de trades del usuario
  user.trades.destroy_all
  user.strategies.destroy_all
  user.ai_analyses.destroy_all

  # Crear estrategias
  strategies_data = [
    { name: "Breakout",         market: "Crypto",  description: "Ruptura de rangos con volumen en velas de 15m/1h" },
    { name: "ICT Silver Bullet",market: "Forex",   description: "Fair Value Gaps en ventanas de liquidez 10:00 - 11:00 AM" },
    { name: "Scalping 5m",      market: "Crypto",  description: "Entradas rápidas en niveles de soporte/resistencia con RSI" },
    { name: "Trend Following",  market: "Stocks",  description: "Continuación de tendencia usando medias móviles EMA 20 y 50" },
    { name: "Reversal FVG",     market: "Indices", description: "Reversión tras barrido de liquidez máxima/mínima del día" }
  ]

  strats = {}
  strategies_data.each do |sdata|
    strats[sdata[:name]] = Strategy.create!(
      name: sdata[:name],
      market: sdata[:market],
      description: sdata[:description],
      user: user
    )
  end

  # Listado de 20 operaciones bien distribuidas en los últimos 30 días
  raw_trades = [
    { symbol: "BTC/USDT",  direction: "LONG",  strategy: "Breakout",         entry_price: 58200, exit_price: 60400, stop_loss: 57500, take_profit: 60500, pnl: 2200, r_multiple: 3.14, emotion: "calm",      entry_at: 28.days.ago },
    { symbol: "ETH/USDT",  direction: "SHORT", strategy: "Reversal FVG",     entry_price: 3450,  exit_price: 3380,  stop_loss: 3490,  take_profit: 3350,  pnl: 700,  r_multiple: 1.75, emotion: "confident", entry_at: 26.days.ago },
    { symbol: "EUR/USD",   direction: "SHORT", strategy: "ICT Silver Bullet",entry_price: 1.0880,exit_price: 1.0910,stop_loss: 1.0895,take_profit: 1.0840,pnl: -300, r_multiple: -1.0, emotion: "anxious",   entry_at: 24.days.ago },
    { symbol: "NVDA",      direction: "LONG",  strategy: "Trend Following",  entry_price: 115,   exit_price: 122,   stop_loss: 112,   take_profit: 124,   pnl: 1400, r_multiple: 2.33, emotion: "calm",      entry_at: 23.days.ago },
    { symbol: "SOL/USDT",  direction: "LONG",  strategy: "Scalping 5m",      entry_price: 132,   exit_price: 130.5, stop_loss: 131,   take_profit: 135,   pnl: -150, r_multiple: -1.0, emotion: "fearful",  entry_at: 21.days.ago },
    { symbol: "BTC/USDT",  direction: "LONG",  strategy: "Breakout",         entry_price: 61000, exit_price: 62800, stop_loss: 60200, take_profit: 63000, pnl: 1800, r_multiple: 2.25, emotion: "confident", entry_at: 19.days.ago },
    { symbol: "TSLA",      direction: "SHORT", strategy: "Reversal FVG",     entry_price: 220,   exit_price: 226,   stop_loss: 224,   take_profit: 210,   pnl: -600, r_multiple: -1.0, emotion: "anxious",   entry_at: 17.days.ago },
    { symbol: "GBP/USD",   direction: "LONG",  strategy: "ICT Silver Bullet",entry_price: 1.2950,exit_price: 1.3020,stop_loss: 1.2920,take_profit: 1.3040,pnl: 700,  r_multiple: 2.33, emotion: "calm",      entry_at: 15.days.ago },
    { symbol: "AAPL",      direction: "LONG",  strategy: "Trend Following",  entry_price: 218,   exit_price: 225,   stop_loss: 215,   take_profit: 226,   pnl: 1050, r_multiple: 2.33, emotion: "calm",      entry_at: 14.days.ago },
    { symbol: "BTC/USDT",  direction: "SHORT", strategy: "Scalping 5m",      entry_price: 63500, exit_price: 63900, stop_loss: 63800, take_profit: 62500, pnl: -400, r_multiple: -1.0, emotion: "fearful",  entry_at: 12.days.ago },
    { symbol: "ETH/USDT",  direction: "LONG",  strategy: "Breakout",         entry_price: 3400,  exit_price: 3550,  stop_loss: 3340,  take_profit: 3560,  pnl: 1500, r_multiple: 2.50, emotion: "confident", entry_at: 10.days.ago },
    { symbol: "SPY",       direction: "LONG",  strategy: "Trend Following",  entry_price: 545,   exit_price: 552,   stop_loss: 542,   take_profit: 554,   pnl: 700,  r_multiple: 2.33, emotion: "calm",      entry_at: 8.days.ago  },
    { symbol: "SOL/USDT",  direction: "LONG",  strategy: "Scalping 5m",      entry_price: 140,   exit_price: 144.5, stop_loss: 138,   take_profit: 145,   pnl: 450,  r_multiple: 2.25, emotion: "calm",      entry_at: 7.days.ago  },
    { symbol: "EUR/USD",   direction: "SHORT", strategy: "ICT Silver Bullet",entry_price: 1.0920,exit_price: 1.0860,stop_loss: 1.0945,take_profit: 1.0850,pnl: 600,  r_multiple: 2.40, emotion: "confident", entry_at: 6.days.ago  },
    { symbol: "NVDA",      direction: "SHORT", strategy: "Reversal FVG",     entry_price: 128,   exit_price: 130,   stop_loss: 129.5,take_profit: 123,   pnl: -200, r_multiple: -1.0, emotion: "anxious",   entry_at: 5.days.ago  },
    { symbol: "BTC/USDT",  direction: "LONG",  strategy: "Breakout",         entry_price: 64200, exit_price: 65800, stop_loss: 63500, take_profit: 66000, pnl: 1600, r_multiple: 2.28, emotion: "calm",      entry_at: 4.days.ago  },
    { symbol: "ETH/USDT",  direction: "SHORT", strategy: "Reversal FVG",     entry_price: 3480,  exit_price: 3520,  stop_loss: 3510,  take_profit: 3400,  pnl: -400, r_multiple: -1.0, emotion: "fearful",  entry_at: 3.days.ago  },
    { symbol: "SOL/USDT",  direction: "LONG",  strategy: "Breakout",         entry_price: 148,   exit_price: 154,   stop_loss: 145,   take_profit: 155,   pnl: 600,  r_multiple: 2.00, emotion: "confident", entry_at: 2.days.ago  },
    { symbol: "EUR/USD",   direction: "LONG",  strategy: "Scalping 5m",      entry_price: 1.0870,exit_price: 1.0860,stop_loss: 1.0855,take_profit: 1.0900,pnl: -100, r_multiple: -0.67,emotion: "neutral",  entry_at: 1.day.ago   },
    { symbol: "BTC/USDT",  direction: "LONG",  strategy: "Breakout",         entry_price: 65100, exit_price: 66400, stop_loss: 64500, take_profit: 66500, pnl: 1300, r_multiple: 2.16, emotion: "confident", entry_at: 6.hours.ago }
  ]

  raw_trades.each do |attrs|
    strat_name = attrs.delete(:strategy)
    strategy   = strats[strat_name]
    trade      = user.trades.create!(
      symbol:         attrs[:symbol],
      direction:      attrs[:direction],
      entry_price:    attrs[:entry_price],
      exit_price:     attrs[:exit_price],
      stop_loss:      attrs[:stop_loss],
      take_profit:    attrs[:take_profit],
      pnl:            attrs[:pnl],
      r_multiple:     attrs[:r_multiple],
      emotion:        attrs[:emotion],
      entry_at:       attrs[:entry_at],
      exit_at:        attrs[:entry_at] + 2.hours,
      strategy:       strategy,
      market:         strategy.market,
      timeframe:      "15m",
      result:         attrs[:pnl] >= 0 ? "WIN" : "LOSS",
      entry_reason:   "Confirmación de estructura en 15m + confluencia de volumen",
      notes:          attrs[:pnl] >= 0 ? "Ejecución perfecta siguiendo el plan de trading." : "Salida apresurada por dudas emocionales."
    )

    # Crear análisis AI para trades clave
    if trade.pnl > 1000
      AiAnalysis.create!(
        trade: trade,
        user: user,
        discipline_score: 9,
        feedback: "Excelente disciplina en #{trade.symbol}. Mantuviste el Ratio Riesgo:Beneficio superior a 2.0R sin alterar el Stop Loss.",
        pattern_detected: "Ruptura con volumen confirmado",
        reflection_question: "¿Identificaste este setup desde la sesión previa o fue una oportunidad imprevista?"
      )
    elsif trade.pnl < 0
      AiAnalysis.create!(
        trade: trade,
        user: user,
        discipline_score: 5,
        feedback: "Operación en pérdida. Notamos que tu entrada en #{trade.symbol} ocurrió fuera de tu horario habitual de mayor efectividad.",
        pattern_detected: "Entrada apresurada / FOMO",
        reflection_question: "¿Esperaste al cierre de la vela de confirmación antes de ingresar?"
      )
    end
  end
  puts "  ✔ #{user.trades.count} operaciones sembradas para #{user.email}"
end

puts "¡Base de datos cargada con éxito!"

# ============================================
# COMMUNITY SEED DATA
# ============================================
puts ""
puts "Sembrando datos de Community..."

# Clean community data
Post.destroy_all
Comment.destroy_all
Reaction.destroy_all
TradeShare.destroy_all
ChatRoom.destroy_all
Message.destroy_all
Classroom.destroy_all
Resource.destroy_all
ReviewRequest.destroy_all
Enrollment.destroy_all

all_users = User.all.to_a
all_users << demo_user unless all_users.include?(demo_user)
all_users = all_users.uniq

# --- POSTS ---
post_contents = [
  "¡Estoy muy emocionado con el análisis de BTC/USDT hoy! El R:R es excelente y la confluencia de volumen confirma el setup. 💪",
  "Mejora en mi disciplina de trading. Finalmente logré seguir el plan al pie de la letra en una operación difícil.",
  "El FOMO es mi peor enemigo. Aprendí a esperar la confirmación antes de entrar. #TradingPsychology",
  "Mi estrategia de scalping 5m está funcionando muy bien esta semana. Win rate del 70% 📈",
  "El análisis técnico en EUR/USD muestra un patrón de reversión clara. Esperando la entrada perfecta.",
  "Gestión del riesgo: nunca arriesgues más del 2% de tu capital por operación. Esto cambió mi trading para siempre.",
  "El ICT Silver Bullet es una estrategia poderosa pero requiere paciencia. Practiqué durante 3 semanas antes de aplicarla.",
  "Mejorando mi journaling diario. Registro cada operación con emociones, resultado y lecciones aprendidas.",
  "La tendencia es tu amiga. NVDA en breakout con volumen masivo. ¡A favor del movimiento!",
  "Error costoso hoy: entré sin confirmación de vela. Lección aprendida: espera la confirmación siempre."
]

all_users.each_with_index do |user, idx|
  posts_to_create = [post_contents[idx % post_contents.length]]
  posts_to_create.each do |content|
    Post.create!(
      user: user,
      content: content,
      visibility: ["public", "public", "public", "friends"].sample,
      status: "active"
    )
  end
  
  # Add comments and reactions to first 3 users' posts
  if idx < 3
    post = user.posts.first
    next unless post
    reactors = all_users.reject { |u| u == user }.sample(3)
    reactors.each do |reactor|
      Comment.create!(
        user: reactor,
        post: post,
        content: "¡Gran post! #{["Muy de acuerdo", "Excelente análisis", "Gracias por compartir", "Interesante perspectiva"].sample} 🤔"
      )
      Reaction.find_or_create_by!(user: reactor, post: post) do |r|
        r.reaction_type = ["like", "heart", "fire"].sample
      end
    end
  end
end

puts "  ✔ #{Post.count} posts creados"

# --- TRADE SHARES ---
all_users.each do |user|
  next unless user.trades.any?
  trade = user.trades.order(created_at: :desc).first
  TradeShare.create!(
    user: user,
    trade: trade,
    title: "#{trade.symbol} - #{trade.direction} #{trade.result == 'WIN' ? '✅' : '❌'}",
    note: "Compartiendo esta operación del día. Resultado: #{trade.pnl >= 0 ? '+' : ''}$#{trade.pnl}",
    privacy: ["public", "public", "followers"].sample
  )
end

puts "  ✔ #{TradeShare.count} trade shares creados"

# --- CHAT ROOMS ---
chat_rooms_data = [
  { name: "General" },
  { name: "Ayuda Trading" },
  { name: "Estrategias Avanzadas" },
  { name: "Psicología Trading" },
  { name: "Scalping & Day Trading" }
]

chat_rooms_data.each do |data|
  room = ChatRoom.find_or_create_by!(name: data[:name])
  
  # Add messages to each room
  5.times do |i|
    Message.create!(
      chat_room: room,
      user: all_users.sample,
      content: ["¡Hola a todos! 👋", "Alguien tiene análisis de BTC hoy?", "Excelente sesión de trading 💪", "¿Alguien usa el ICT Silver Bullet?", "Les comparto mi setup del día 📊", "Cuidado con el FOMO hoy 🔥", "La tendencia está a favor 👆", "Gran análisis del soporte"].sample,
      created_at: rand(1..24).hours.ago
    )
  end
end

puts "  ✔ #{ChatRoom.count} chat rooms con #{Message.count} mensajes creados"

# --- CLASSROOMS ---
classroom_data = [
  { title: "Introducción al Análisis Técnico", description: "Aprende los fundamentos del análisis técnico: velas, soportes, resistencias y patrones de precio.", category: "beginner" },
  { title: "Gestión de Riesgo Avanzada", description: "Domina el cálculo de posición, stop loss dinámico y gestión del riesgo por operación.", category: "intermediate" },
  { title: "Estrategias ICT para Forex", description: "Fair Value Gaps, liquidez y ventanas de tiempo en el trading de divisas.", category: "advanced" },
  { title: "Trading Psicología y Disciplina", description: "Control emocional, journaling y mentalidad de trader profesional.", category: "beginner" },
  { title: "Scalping Profesital con Volumen", description: "Entradas rápidas basadas en flujo de órdenes y volumen institucional.", category: "intermediate" },
  { title: "Swing Trading con Tendencias", description: "Identifica tendencias fuertes y opera en su favor con medias móviles.", category: "beginner" }
]

classroom_data.each do |data|
  Classroom.create!(
    author: all_users.sample,
    title: data[:title],
    description: data[:description],
    category: data[:category]
  )
end

# Enroll some users
Classroom.find_each do |classroom|
  users_to_enroll = all_users.sample([2, 5].max)
  users_to_enroll.each do |user|
    Enrollment.find_or_create_by!(classroom: classroom, user: user)
  end
end

puts "  ✔ #{Classroom.count} classrooms con #{Enrollment.count} inscripciones creados"

# --- RESOURCES ---
resource_data = [
  { title: "Guía Completa de R:R", url: "https://example.com/r-r-guide", category: "article", description: "Aprende a calcular y optimizar tu Ratio Riesgo:Beneficio en cada operación." },
  { title: "Curso de Price Action", url: "https://example.com/price-action", category: "course", description: "Curso completo de lectura de gráficos y patrones de precio." },
  { title: "Podcast: Trading Mentalidad", url: "https://example.com/trading-podcast", category: "podcast", description: "Episodios sobre psicología, disciplina y desarrollo como trader." },
  { title: "Video: Análisis BTC Hoy", url: "https://example.com/btc-analysis", category: "video", description: "Análisis técnico actualizado de Bitcoin con confluencias clave." },
  { title: "Libro: Market Wizards", url: "https://example.com/market-wizards", category: "book", description: "Clásico de la literatura de trading con entrevistas a los mejores traders." }
]

resource_data.each do |data|
  Resource.create!(
    author: all_users.sample,
    title: data[:title],
    url: data[:url],
    category: data[:category],
    description: data[:description]
  )
end

puts "  ✔ #{Resource.count} recursos creados"

# --- REVIEW REQUESTS ---
mentors = all_users.reject { |u| u.trades.count < 3 }.first(3)
requesters = all_users.reject { |u| u.trades.count < 1 }

requesters.each do |requester|
  mentor = (mentors - [requester]).sample || (all_users - [requester]).sample
  trade = requester.trades.order(created_at: :desc).first
  next unless trade && mentor && mentor != requester
  
  ReviewRequest.create!(
    requester: requester,
    mentor: mentor,
    trade: trade,
    message: "¿Podrías revisar mi análisis de #{trade.symbol}? Busco feedback sobre mi gestión de riesgo.",
    status: ["pending", "pending", "accepted"].sample
  )
end

puts "  ✔ #{ReviewRequest.count} solicitudes de revisión creadas"

# --- BROKERS & PLATFORMS ---
puts ""
puts "Sembrando catálogo de Brokers y Plataformas..."

brokers_list = [
  { name: "Topstep", logo_filename: "brokers/Topstep.png", category: "prop_firm", supports_autosync: true, supports_file_upload: true, supports_manual: true },
  { name: "Apex Trader Funding", logo_filename: "compañias/Apex Trader funding.png", category: "prop_firm", supports_autosync: true, supports_file_upload: true, supports_manual: true },
  { name: "My Funded Futures", logo_filename: "compañias/My funded futures.png", category: "prop_firm", supports_autosync: true, supports_file_upload: true, supports_manual: true },
  { name: "Alpha Futures", logo_filename: "compañias/Alpha futures.png", category: "prop_firm", supports_autosync: false, supports_file_upload: true, supports_manual: true },
  { name: "Lucid Trading", logo_filename: "compañias/Lucid trading.png", category: "prop_firm", supports_autosync: false, supports_file_upload: true, supports_manual: true },
  { name: "Tradeify", logo_filename: "compañias/Tradeify.png", category: "prop_firm", supports_autosync: false, supports_file_upload: true, supports_manual: true },
  { name: "Take Profit Trader", logo_filename: "compañias/take profit trader.png", category: "prop_firm", supports_autosync: true, supports_file_upload: true, supports_manual: true },
  { name: "Interactive Brokers", logo_filename: "brokers/Interactive Brokers.png", category: "broker", supports_autosync: true, supports_file_upload: true, supports_manual: true },
  { name: "Tradovate", logo_filename: "brokers/Tradovate.png", category: "platform", supports_autosync: true, supports_file_upload: true, supports_manual: true },
  { name: "NinjaTrader", logo_filename: "brokers/Ninja Trader.png", category: "platform", supports_autosync: false, supports_file_upload: true, supports_manual: true },
  { name: "MatchTrader", logo_filename: nil, category: "platform", supports_autosync: true, supports_file_upload: true, supports_manual: true },
  { name: "MetaTrader 4/5 (MT4/MT5)", logo_filename: nil, category: "platform", supports_autosync: false, supports_file_upload: true, supports_manual: true },
  { name: "Binance / Crypto Exchange", logo_filename: nil, category: "crypto_exchange", supports_autosync: true, supports_file_upload: true, supports_manual: true }
]

brokers_list.each do |battrs|
  b = Broker.find_or_initialize_by(name: battrs[:name])
  b.logo_filename = battrs[:logo_filename]
  b.category = battrs[:category]
  b.supports_autosync = battrs[:supports_autosync]
  b.supports_file_upload = battrs[:supports_file_upload]
  b.supports_manual = battrs[:supports_manual]
  b.autosync_instructions = "1. Accede al panel API de tu broker #{battrs[:name]}.\n2. Genera una clave API (Read-Only).\n3. Pega la clave y el secreto en este formulario para sincronizar automáticamente tus trades."
  b.save!
end

puts "  ✔ #{Broker.count} brokers/plataformas registradas"

puts "✅ Datos de Community y Brokers sembrados con éxito!"
