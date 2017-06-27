module Api
  module V1
    class MediaController < ApplicationController
      def index
        pars = strong_params

        page = params[:page]
        page = 1 unless page.present?

        per_page = params[:per_page]
        per_page = 10 unless per_page.present?

        @items = Medium.published.sorted.paginate(:page => page, :per_page => per_page)

        return unless @items.present?

        render json: { results: @items, total: Medium.published.count }, status: 200
      end

      private

      def strong_params
        params.permit(
          :locale,
          :page,
          :per_page
        )
      end
    end
  end
end
