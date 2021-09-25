require 'nokogiri'

module ::TopicPreviews::SerializerLib

  def self.remove_links (excerpt)
    doc = Nokogiri::HTML excerpt
    node = doc.at("a")
    node.replace(node.text) if node
    doc.to_str.gsub(/#{URI::regexp}/, '').gsub(/\s+/, ' ').strip
  end

end
