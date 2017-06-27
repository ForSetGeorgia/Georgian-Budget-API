class Admin::MediaController < AdminController
  before_filter :authenticate_user!
  authorize_resource
  before_filter do @model = Medium; end
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  def index
    @items = @model.sorted
  end

  def show
  end

  def new
    @item = @model.new
  end

  def edit
  end

  def create
    pars = strong_params
    medium_image = pars.delete(:medium_image)
    ms = []
    if medium_image.present?
      I18n.available_locales.each{|locale|
        image_locale = "image_#{locale}"
        image_id_locale = "image_id_#{locale}"
        tmp = medium_image[image_locale]
        if tmp.present?
          m = MediumImage.create({image: tmp})
          if m.present?
            pars[image_id_locale] = m.id
            ms << m
          end
        end
      }
    end

    @item = @model.new(pars)

    respond_to do |format|
      if @item.save
        format.html { redirect_to [:admin, @item], notice: t('shared.msgs.success_created',
                            obj: t('activerecord.models.medium', count: 1))}
      else
        ms.each(&:destroy)
        format.html { render :new }
      end
    end

  end

  def update
    pars = strong_params
    medium_image = pars.delete(:medium_image)
    ms = []
    if medium_image.present?
      I18n.available_locales.each{|locale|
        image_locale = "image_#{locale}"
        image_id_locale = "image_id_#{locale}"
        tmp = medium_image[image_locale]
        if tmp.present?
          image_id = @item.send(image_id_locale)
          if image_id.present?
            m = MediumImage.find(image_id)
            m.update({image: tmp})
          else
            m = MediumImage.create({image: tmp})
            if m.present?
              pars[image_id_locale] = m.id
              ms << m
            end
          end
        end
      }
    end

    respond_to do |format|
      if @item.update(pars)
        format.html { redirect_to [:admin,@item], notice: t('shared.msgs.success_updated',
                            obj: t('activerecord.models.medium', count: 1))}
      else
        ms.each(&:destroy)
        format.html { render :edit }
      end
    end
  end

  # DELETE /media/1
  def destroy
    @item = @model.find(params[:id])
    @item.translations.each {|translation|
      m = MediumImage.find_by(id: translation.image_id)
      m.destroy if m.present?
    }
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_media_url, notice: t('shared.msgs.success_destroyed',
                              obj: t('activerecord.models.medium', count: 1))}
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = @model.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def strong_params
      images = []
      I18n.available_locales.each {|locale|
        images << "image_#{locale}"
      }
      permitted = Medium.globalize_attribute_names + [ :published, :story_published_at, medium_image: [ *images ]]
      params.require(:medium).permit(*permitted)
    end
end
