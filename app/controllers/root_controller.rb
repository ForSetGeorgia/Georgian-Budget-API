# Non-resource pages
class RootController < ApplicationController
  def index
  end

  def explore
    @programs = Program.all.with_most_recent_names
    @priorities = Priority.all.with_most_recent_names
    @spending_agencies = SpendingAgency.all.with_most_recent_names
  end

  def about
  end

  def temp_nameable_show
    nameable_type = params[:nameable_type].to_sym

    if nameable_type == :program
      @nameable = Program.find(params[:nameable_id])
    end

    if nameable_type == :spending_agency
      @nameable = SpendingAgency.find(params[:nameable_id])
    end

    if nameable_type == :priority
      @nameable = Priority.find(params[:nameable_id])
    end
  end

  def api
    budget_item = Program.first
    chart_config = TimeSeriesChart.new(budget_item, budget_item.spent_finances ).config
    render json: chart_config, status: :ok
  end
end
