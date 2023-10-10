source 'https://rubygems.org'

gemspec

plugin 'bundler-multilock', '1.2.0'
return unless Plugin.installed?('bundler-multilock')

Plugin.send(:load_plugin, 'bundler-multilock')

lockfile 'rails-6.1' do
  gem 'rails', '~> 6.1.0'
end

lockfile 'rails-7.0' do
  gem 'rails', '~> 7.0.0'
end

lockfile do
  gem 'rails', '~> 7.1.0'
end
