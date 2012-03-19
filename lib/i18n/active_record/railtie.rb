require 'i18n'
require 'rails'

module I18n
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/active_record.rake"
    end
  end
end
