module ::TopicPreviews::SerializerLib

  def self.remove_links (excerpt)
    puts excerpt
    excerpt.gsub(/#{URI::regexp}/, '').gsub(/\s+/, ' ').strip
  end

end
