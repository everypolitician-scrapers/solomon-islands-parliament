#!/bin/env ruby
# encoding: utf-8

# TODO:
#  scrape the list of 'by party' http://www.parliament.gov.sb/index.php?q=node/147
#  Historic lists don't have links for people, so the catch by 'a' doesn't work
#  Finding too many elements

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'
require 'csv'

require 'colorize'
require 'pry'
require 'csv'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

@BASE = 'http://www.parliament.gov.sb/'

@terms = [
  {
    id: 10,
    name: '10th Parliament',
    start_date: '2014',
    source: 'http://www.parliament.gov.sb/index.php?q=node/833',
  },
  {
    id: 9,
    name: '9th Parliament',
    start_date: '2010-09-08',
    end_date: '2014-09-08',
    source: 'http://www.parliament.gov.sb/index.php?q=node/502',
  }
]

def noko_for(url)
  # url.prepend @BASE unless url.start_with? 'http:'
  # warn "Getting #{url}"
  Nokogiri::HTML(open(url).read) 
end

def datefrom(date)
  Date.parse(date)
end

def scrape_term(term)
  noko = noko_for(term[:source])
  noko.css('div.entrytext').xpath('.//tr[td]').each do |row|
    link = URI.join(term[:source], row.css('a/@href').text).to_s
    scrape_mp(link, { term: term[:id] })
  end
end

def scrape_mp(url, data)
  noko = noko_for(url)
  box = noko.css('td.content')

  data.merge!({
    id: url[/(\d+)$/, 1],
    name: box.css('div.heading').text,
    constituency: box.xpath('.//strong[contains(.,"Constituency")] | .//b[contains(.,"Constituency")]/following::text()[1]').text.strip,
    phone: box.text[/Phone: (.*?)$/, 1],
    # TODO also date of birth / DOB
    birth_date: box.text[/Year of birth: (\d+)/, 1],
    source: url,
  })
  binding.pry if data[:id] == '856'
  data[:image] &&= URI.join(url, data[:image]).to_s
  data[:birth_date] = box.text[/DOB: (\d+)/, 1] if data[:birth_date].empty?

  puts data
  # ScraperWiki.save_sqlite([:id, :term], data)

end

# ScraperWiki.save_sqlite([:id], terms, 'terms')
@terms.each do |term|
  scrape_term(term)
end

