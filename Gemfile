source "https://rubygems.org"

gem 'coveralls', require: false
platforms :rbx do
    gem "rubysl-ipaddr"
    gem "rubysl-singleton"
    gem "rubysl-base64"
    gem "rubinius-coverage"
end
gem "r509", :git => "git://github.com/reaperhulk/r509.git"
#gem "r509-middleware-validity", :git => "git://github.com/sirsean/r509-middleware-validity.git"
#gem "r509-middleware-certwriter", :git => "git://github.com/sirsean/r509-middleware-certwriter.git"
#gem "r509-validity-redis", :git => "git://github.com/sirsean/r509-validity-redis.git"
gem "dependo", :git => "git://github.com/sirsean/dependo.git"
gem 'sinatra'
gemspec
group :documentation do
  gem "yard", "~>0.8"
  gem "redcarpet", "~>2.2.2"
  gem "github-markup", ">=0.7.5"
end
