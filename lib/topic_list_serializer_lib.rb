require 'nokogiri'

module ::TopicPreviews::SerializerLib

  def self.remove_links (excerpt)
    doc = Nokogiri::HTML excerpt
    node = doc.at("a")
    node.replace(node.text) if node
<<<<<<< HEAD
    if SiteSetting.topic_list_keep_link_text_content
      doc.to_str.strip
    else
      doc.to_str.gsub(/#{URI::regexp}/, '').gsub(/\s+/, ' ').strip
    end
=======
    doc.to_str.gsub(/#{URI::regexp}/, '').gsub(/\s+/, ' ').strip
>>>>>>> ad9b55090f022d171e72928a10b0ea7100f14543
  end
  
end
