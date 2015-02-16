class CropSearchesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: :search

  def search
    query = params[:q].to_s
    @crops = Crop.search(query,
                         limit: 25,
                         partial: true,
                         misspellings: {distance: 2},
                         fields: ['name^20',
                                  'common_names^10',
                                  'binomial_name^10',
                                  'description'],
                                  boost_by: [:guides_count]
                        )
    if query.empty?
      @crops = Crop.search('*', limit: 25, boost_by: [:guides_count])
    end

    # Use the crop results to look-up guides
    crop_ids = @crops.map { |crop| crop.id }

    @guides = Guide.search('*', where: {crop_id: crop_ids}, order: guide_order)

    render :show
  end

  protected
  def guide_order
    # Default order for logged out user.
    return {_score: :desc} unless current_user

    {
      'compatibilities.score' => {
        order: 'desc', nested_filter: {
          term: { 'compatibilities.user_id' => current_user.id.to_s }
        }
      }
    }
  end
end
