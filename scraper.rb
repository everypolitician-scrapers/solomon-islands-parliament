#!/bin/env ruby
# encoding: utf-8

# TODO:
#  scrape the list of 'by party' http://www.parliament.gov.sb/index.php?q=node/147
#  Historic lists are in a different format

require 'date'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def datefrom(date)
  Date.parse(date)
end

def scrape_term(term)
  url = term[:source]
  noko = noko_for(url)
  noko.css('div.entrytext').xpath('.//tr[td]').each do |row|
    tds = row.css('td')
    sort_name = tds[1].text.strip
    data = { 
      name: sort_name.split(', ', 2).reverse.join(" ").sub(/^Hon\.? /,''),
      sort_name: sort_name,
      constituency: tds[2].text[/MP for (.*)/, 1].strip,
      term: term[:id],
      source: term[:source],
    }
    mpsource = tds[1].css('a/@href').text
    data.merge! scrape_mp(URI.join(url, URI.escape(mpsource)).to_s) unless mpsource.empty?
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

def scrape_mp(url)
  noko = noko_for(url)
  box = noko.css('td.content')

  data = { 
    id: url[/(\d+)$/, 1],
    party: noko.xpath('.//p[strong[contains(.,"Affiliation")]]/following-sibling::ul[1]').text.tidy,
    phone: box.text[/Phone: (.*?)$/, 1],
    image: noko.css('.entrytext img/@src').text,
    source: url,
  }
  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  data
end

@terms = [
  {
    id: '10',
    name: '10th Parliament',
    start_date: '2014',
    source: 'http://www.parliament.gov.sb/index.php?q=node/833',
  }
]

@terms.each do |term|
  puts term
  scrape_term(term)
end

