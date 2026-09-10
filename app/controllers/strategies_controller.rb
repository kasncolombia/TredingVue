class StrategiesController < ApplicationController
  before_action :set_strategy, only: [:show, :edit, :update, :destroy]

  def index
    @strategies = current_user.strategies
  end

  def new
    @strategy = current_user.strategies.build
  end

  def create
    @strategy = current_user.strategies.build(strategy_params)
    if @strategy.save
      redirect_to strategies_path, notice: "Estrategia creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @strategy.update(strategy_params)
      redirect_to strategies_path, notice: "Estrategia actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @strategy.destroy
    redirect_to strategies_path, notice: "Estrategia eliminada."
  end

  private

  def set_strategy
    @strategy = current_user.strategies.find(params[:id])
  end

  def strategy_params
    params.require(:strategy).permit(:name, :description, :market)
  end
end
