require 'simplecov'

SimpleCov.configure do
  add_filter do |src|
    src.filename !~ /discourse-topic-previews/ ||
    src.filename =~ /spec/
  end
end
