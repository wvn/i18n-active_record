module I18n
  module Backend
    class Import
      include Flatten
      class << self
      def store_default_translations(locale, key, options = {})
        count, scope, default, separator = options.values_at(:count, :scope, :default, :separator)
        separator ||= I18n.default_separator
        key = normalize_flat_keys(locale, key, scope, separator)

        unless ActiveRecord::Translation.locale(locale).lookup(key).exists?
          interpolations = options.keys - I18n::RESERVED_KEYS
          keys = count ? I18n.t('i18n.plural.keys', :locale => locale).map { |k| [key, k].join(FLATTEN_SEPARATOR) } : [key]
          keys.each { |key| store_default_translation(locale, key, interpolations) }
        end
      end

      def store_default_translation(locale, key, value, interpolations)
        translation = ActiveRecord::Translation.new :locale => locale.to_s, :key => key, :value => value
        translation.interpolations = interpolations
        translation.save
      end

      def translate(locale, key, options = {})
        super
      rescue I18n::MissingTranslationData => e
        self.store_default_translations(locale, key, options)
        raise e
      end
    end

    def import_all
      Dir.glob("#{Rails.root}/config/locales/*.{rb,yml}").each do |file|

        hash = eval(File.open(file).read)

        keys = extract_i18n_keys(hash)

        keys.each do |key|
          value = I18n::Backend::Simple.new.send(:lookup, code, key)
          if value.is_a?(Array)
            value.each_with_index do |v, index|
              create_translation(locale, "#{key}", index, v) unless v.nil?
            end
          else
            store_default_translation(locale, key, pluralization_index, value)
          end
        end

      end
    end
  end
  end

  private
  class << self

    def extract_i18n_keys(hash, parent_keys = [])
      hash.inject([]) do |keys, (key, value)|
        full_key = parent_keys + [key]
        if value.is_a?(Hash)
          # Nested hash
          keys += extract_i18n_keys(value, full_key)
        elsif !value.nil?
          # String leaf node
          keys << full_key.join(".")
        end
        keys
      end
    end

  end
end