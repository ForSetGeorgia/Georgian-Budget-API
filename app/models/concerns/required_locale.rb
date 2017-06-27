module RequiredLocale
  extend ActiveSupport::Concern

  included do

    def self.globalize_validations(attrs)
      if attrs.present? && attrs.length.present?
        validate do |v|
          v.required_locale_fields(attrs)
        end
      end
    end

    def required_locale_fields(attrs)
      attrs.each {|attr|
        attr_name = "#{attr}_#{I18n.locale}"
        errors.add(attr_name, "#{I18n.t('errors.messages.blank')}") if self.send(attr_name).blank?
      }
    end
  end
end
