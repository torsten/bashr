%w.time rexml/document ubygems builder hpricot open-uri zlib..
each{|_|require _}


module Bashr
  
  RELEASE = 0
  
  FEED = 'http://german-bash.org/latest-quotes.xml'
  # FEED = 'latest-quotes.xml'
  
  CACHE_FILE = "#{File.expand_path(File.dirname(__FILE__))}/site_cache.gz"
  
  
  def self.fetch_entries
    
    cache = 
    File.open(Bashr::CACHE_FILE) do |file|
      gz = Zlib::GzipReader.new(file)
      hsh = Marshal.load gz.read
      gz.close
      
      hsh
    end rescue {}
    
    current_keys = []
    
    doc = REXML::Document.new(open(Bashr::FEED))
    
    
    entries =
    # Extract the items/entries from the feed
    doc.elements.collect("/rss/channel/item") do |entry|
      {
        :title => entry.elements['title'].text,
        :link => entry.elements['link'].text,
        :id => entry.elements['guid'].text,
      }
    end.
    # Get for each item the content either from the cache or the web
    map do |entry|
      cache_key = entry[:link].to_sym
      current_keys << cache_key
      
      if not cache[cache_key]
        $stderr.puts "MISS: #{entry[:link]}"
        cache[cache_key] = open(entry[:link]).read
      end
      
      hdoc = Hpricot(cache[cache_key])
      
      # Get the quote content and add line endings
      entry[:content] =
          (hdoc/"#quote#{entry[:link][%r{/id/(\d+)}, 1]} div.zitat").to_html.
            gsub('</span>', '<br/></span>')
      
      entry
    end
        
    
    # Cleanup the cache and then write it back
    cache.delete_if do |key, value|
      not current_keys.include? key
    end
    
    File.open(Bashr::CACHE_FILE, 'wb') do |file|
      gz = Zlib::GzipWriter.new(file)
      gz.write Marshal.dump(cache)
      gz.close
    end
    
    entries
  end
  
  
  def self.generate_atom updated, entries
    atom = Builder::XmlMarkup.new(:indent => 2)
    atom.instruct!
    
    
    atom.feed :xmlns => 'http://www.w3.org/2005/Atom' do
      atom.title "German-bash.org"
      
      atom.link :href => "http://www.german-bash.org/"

      atom.updated updated
      
      
      atom.author do
        atom.name "German-bash.org"
      end
      
      atom.id "tag:torsten.becker@gmail.com,2008-09:Bashr"
      
      atom.generator 'Bashr', :version => Bashr::RELEASE
      
      
      (entries or []).each do |entry|
        atom.entry do
          atom.title entry[:title]
          atom.link :href => entry[:link]
          atom.id entry[:id]
          atom.content entry[:content], :type => 'html'
        end
        
      end

    end

    atom.target!
    
  end
  
end
