class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.recent

    # System Status & Health Metrics
    @openai_configured    = ENV['OPENAI_API_KEY'].present?
    @db_status            = (ActiveRecord::Base.connection.active? rescue false)
    @total_users          = User.count
    @onboarded_users      = User.where(onboarding_completed: true).count
    @pro_users            = User.select(&:pro?).count
    @total_trades         = Trade.count
    @total_global_pnl     = Trade.sum(:pnl)
    @total_ai_analyses    = AiAnalysis.count
    @avg_discipline_score = (AiAnalysis.average(:discipline_score)&.round(1) || 0.0)
    @total_posts          = Post.count
    @total_trade_shares   = TradeShare.count
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "Usuario actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "Usuario eliminado correctamente."
  end

  def update_ai_settings
    provider = params[:ai_provider].to_s.presence || 'google'
    model    = params[:ai_model].to_s.presence || (provider == 'google' ? 'gemini-3.6-flash' : 'gpt-4o-mini')
    api_key  = params[:api_key].to_s.strip

    ENV['AI_PROVIDER'] = provider
    ENV['AI_MODEL']    = model

    if provider == 'openrouter'
      ENV['OPENROUTER_API_KEY'] = api_key if api_key.present?
    else
      ENV['OPENAI_API_KEY'] = api_key if api_key.present?
    end

    env_file = Rails.root.join('.env')
    env_content = File.exist?(env_file) ? File.read(env_file) : ""

    # Actualizar o agregar variables en .env
    {
      'AI_PROVIDER'        => provider,
      'AI_MODEL'           => model,
      'OPENROUTER_API_KEY' => ENV['OPENROUTER_API_KEY'],
      'OPENAI_API_KEY'     => ENV['OPENAI_API_KEY']
    }.each do |key, val|
      next if val.blank?
      if env_content.match?(/^#{key}=/)
        env_content.sub!(/^#{key}=.*/, "#{key}=#{val}")
      else
        env_content += "\n#{key}=#{val}\n"
      end
    end

    File.write(env_file, env_content)
    redirect_to admin_users_path, notice: "✅ Configuración de IA (#{provider.upcase} / #{model}) guardada correctamente."
  end

  def test_ai_connection
    provider = ENV.fetch('AI_PROVIDER', 'google')
    model    = ENV.fetch('AI_MODEL', 'gemini-3.6-flash')
    key      = ENV['GEMINI_API_KEY'].presence || ENV['OPENROUTER_API_KEY'].presence || ENV['OPENAI_API_KEY']

    if key.blank?
      render json: { success: false, message: "No hay API Key configurada para #{provider.upcase}." }
    else
      begin
        coach = Ai::TradingCoach.new(current_user)
        reply = coach.ask("Responde solo: 'Conexión OK'")
        if reply.present?
          render json: { success: true, message: "¡Conexión exitosa a #{provider.upcase} (#{model})! Respuesta: #{reply}" }
        else
          render json: { success: false, message: "No se obtuvo respuesta de #{provider.upcase} (#{model}). Verifica tu API Key y saldo." }
        end
      rescue => e
        render json: { success: false, message: "Error al conectar con #{provider.upcase}: #{e.message}" }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :initial_capital, :preferred_currency, :timezone)
  end
end
