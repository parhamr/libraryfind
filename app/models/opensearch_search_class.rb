# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

require 'rubygems'
require 'opensearch'
require 'rexml/document'

class OpensearchSearchClass < ActionController::Base

  attr_reader :hits, :xml
  @pkeyword = ""
  @feed_url = ""
  @feed_id = ""
  @search_id = ""
  @feed_type = "" 
  @feed_name = ""

  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _last_id, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    _lrecord = Array.new()

    @feed_url = _collect.vendor_url
    @feed_id = _collect.id
    @search_id = _last_id
    @feed_type = _collect.mat_type
    @feed_name = _collect.alt_name
    @pkeyword = _qstring.join(" ")
    
    #====================================
    # Setup the OpenSearch Request
    #====================================    
    
    begin
      #initialize
      logger.debug("COLLECT: " + _collect.host)
      objOpen = OpenSearch::OpenSearch.new _collect.host
      logger.debug("COLLECT2")
      if _collect.bib_attr != ""
         _tmparray = _collect.bib_attr.split(";")
         _tmparray.each() {|a|
            _tmparray2 = a.split("=")
            case _tmparray2[0] 
            when 'language'
	        objOpen.language = _tmparray2[1]
            when 'output_encoding'
		objOpen.output_encoding = _tmparray2[1]
            when 'input_encoding'
		objOpen.input_encoding = _tmparray2[1]
	    end 
         }
      end
      objOpen.count = _max
      objOpen.start_index = _start
      altname = objOpen.short_name
   
      #Do the search -- setting the openurl application 
      #type if present.
      #note -- we only support RSS and Atom
  
      logger.debug("Record Schema: " + _collect.record_schema) 
      if _collect.record_schema == "": _collect.record_schema = "application/rss+xml" end 
 
      #perform the search
      feed = objOpen.search(_qstring.join(" "), _collect.record_schema)
    rescue
      if _action_type != nil
         _lxml = ""
         logger.debug("ID: " + _last_id.to_s)
         my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY)
         return my_id, 0
      else
	 return nil
      end
    end

    if feed != nil || feed != ""
      begin
        if _collect.record_schema == 'application/rss+xml'
           _lrecord = parse_rss(feed, _max.to_i)
        elsif _collect.record_schema == 'application/atom+xml'
           _lrecord = parse_atom(feed)
        else
	   if _action_type != nil
              _lxml = ""
              logger.debug("ID: " + _last_id.to_s)
              my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY)
              return my_id, 0
           else
	      return nil
	   end
        end
      rescue
	if _action_type != nil
	   _lxml = ""
           logger.debug("ID: " + _last_id.to_s)
           my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY)
           return my_id, 0
        else
	   return nil
	end
      end
    end

    _lprint = false
    if _lrecord != nil
	_lxml = CachedSearch.build_cache_xml(_lrecord)
   
	if _lxml != nil: _lprint = true end
	if _lxml == nil: _lxml = "" end

	#============================================
	# Add this info into the cache database
	#============================================
	if _last_id.nil?
		# FIXME:  Raise an error
		logger.debug("Error: _last_id should not be nil")
	else
		logger.debug("Save metadata")
		status = LIBRARYFIND_CACHE_OK
		if _lprint != true
			status = LIBRARYFIND_CACHE_EMPTY
		end
		my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, status)
	end
     else
	logger.debug("save bad metadata")
	_lxml = ""
	logger.debug("ID: " + _last_id.to_s)
	my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY)
     end

     if _action_type != nil
	if _lrecord != nil
	  return my_id, _lrecord.length
        else
	  return my_id, 0
        end
     else
        return _lrecord
     end
  end
 
  def self.strip_escaped_html(str, allow = [''])
        str = str.gsub("&#38;lt;", "<")
        str = str.gsub("&#38;gt;", ">")
        str = str.gsub("&lt;", "<")
        str = str.gsub("&gt;", ">")
        str.strip || ''
        allow_arr = allow.join('|') << '|\/'
        str = str.gsub(/<(\/|\s)*[^(#{allow_arr})][^>]*>/, ' ')
	str = str.gsub("<", "&lt;")
        str = str.gsub(">", "&gt;")
        return str
  end
 

  def self.parse_rss(xml, _max = 20) 
    _objRec = RecordSet.new()
    _title = ""
    _authors = ""
    _description = ""
    _subjects = ""
    _publisher = ""
    _link = ""
    _record = Array.new()
    _x = 0

    _xpath = Xpath.new()
    parser = ::PARSER_TYPE
    begin
      case parser
      when 'libxml'
        _parser = LibXML::XML::Parser.new()
        _parser.string = xml
        doc = LibXML::XML::Document.new()
        doc = _parser.parse
      when 'rexml'
        doc = REXML::Document.new(xml)
      end
    rescue
      return nil
    end

    namespaces = {'dc' => 'http://purl.org/dc/elements/1.1/', 
		  'dcterms' => 'http://purl.org/dc/terms/'}

    nodes = _xpath.xpath_all(doc, "//item", namespaces) 
    _hit_count = nodes.to_a.length.to_s
    logger.debug("HITS" + _hit_count)
    nodes.each { |item |
       if _x > _max 
	 next
       end 
       logger.debug("item: " + item.to_s)
       _start_time = Time.now()
       logger.debug("Title here")
       _title = _xpath.xpath_get_text(_xpath.xpath_first(item, "title")) #item.elements["title"][0].value
       logger.debug("We have a title: " + _title)
       begin
         if _xpath.xpath_first(item, "description") != nil: _description = strip_escaped_html(_xpath.xpath_get_text(_xpath.xpath_first(item, "description"))) end #item.elements["description"] != nil: _description = strip_escaped_html(item.elements["description"][0].value) end
       rescue 
       end
       logger.debug("Did we process the description")
       if _xpath.xpath_first(item, "dc:subject", namespaces) != nil #item.elements["dc:subject"] != nil
	 _xpath.xpath_all(item, "dc:subject", namespaces).each { |i|
         #item.elements.each("dc:subject") { |i|
            if _subjects != ""
              _subjects << "; " + _xpath.xpath_get_text(i) #i.value 
            else
              _subjects = _xpath.xpath_get_text(i) #i.value
            end
         }
       end
       logger.debug("past subjects")
       if _xpath.xpath_first(item, "dc:publisher", namespaces) != nil #item.elements["dc:publisher"] != nil 
         _publisher = _xpath.xpath_get_text(_xpath.xpath_first(item, "dc:publisher", namespaces)) #item.elements["dc:publisher"][0].value
       end
       logger.debug("past publishers")
 
       if _xpath.xpath_first(item, "dc:creator", namespaces) != nil #item.elements["dc:creator"] != nil
	 _xpath.xpath_all(item, "dc:creator", namespaces).each {|i|
         #item.elements.each("dc:creator") {|i|
           if _authors != ""
             _authors << "; " + _xpath.xpath_get_text(i) #i.value
           else
             _authors = _xpath.xpath_get_text(i) #i.value
           end
         }
       end 
       logger.debug("past authors")
       if _xpath.xpath_first(item, "link") != nil: _link = _xpath.xpath_get_text(_xpath.xpath_first(item, "link")) end
       #if item.elements["link"] != nil: _link = item.elements["link"][0].value end
       logger.debug("past links")
       #item text
       _keyword = normalize(_xpath.xpath_get_all_text(item))
      
       logger.debug("Keywords: " + _keyword) 
       record = Record.new()
       record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>'', 'rec' => _keyword , 'pos'=>1}, @pkeyword)
       logger.debug("past rank")
       record.vendor_name = @feed_name
       record.ptitle = normalize(_title)
       record.title =  normalize(_title)
       record.atitle =  ""
       record.issn =  ""
       record.isbn = ""
       record.abstract = normalize(_description)
       record.date = ""
       record.author = normalize(_authors)
       record.link = ""
       record.id = @search_id.to_s + ";" + @feed_id.to_s + ";" + (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s)
       record.doi = ""
       record.openurl = ""
       record.direct_url = normalize(_link)
       record.static_url = ""
       record.subject = normalize(_subjects)
       record.publisher = ""
       record.callnum = ""
       if @feed_url==nil: @feed_url = "" end
       record.vendor_url = @feed_url
       record.material_type = normalize(@feed_type)
       record.volume = ""
       record.issue = ""
       record.page = ""
       record.number = ""
       record.start = _start_time.to_f
       record.end = Time.now().to_f
       record.hits = _hit_count
       _record[_x] = record
       _x = _x + 1
    }
    return _record 

  end  

  def self.parse_atom(xml)
    _objRec = RecordSet.new()
    _title = ""
    _authors = ""
    _description = ""
    _subjects = ""
    _publisher = ""
    _link = ""
    _record = Array.new()
    _x = 0

    doc = REXML::Document.new(xml)
    _hit_count = doc.elements["//entry"].to_a().length.to_s 
    doc.elements.each("//entry") { |item |
       _start_time = Time.now()
       _title = item.elements["title"][0].value
       if item.elements["summary"] != nil: _description = strip_escaped_html(item.elements["summary"][0].value) end
       logger.debug("summary")
       if item.elements["category"] != nil
          item.elements.each("category") { |i|
            if _subjects != ""
              _subjects << "; " + i.attributes["term"]
            else
              _subjects = i.attributes["term"]
            end
          }
       end
       logger.debug("subjects")
       _publisher = ""
       if item.elements["author"] != nil
         item.elements.each("author") {|i|
           if _authors != ""
             _authors << "; " + i.elements["name"][0].value
           else
             _authors = i.elements["name"][0].value
           end
         }
       end
       logger.debug("authors")
       if item.elements["link"] != nil
         _link = item.elements["link"].attributes['href']
       end
       logger.debug("links")

       record = Record.new()
       record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>'', 'rec' => item.text, 'pos'=>1}, @pkeyword)
       record.vendor_name = @feed_name
       record.ptitle = normalize(_title)
       record.title =  normalize(_title)
       record.atitle =  ""
       record.issn =  ""
       record.isbn = ""
       record.abstract = normalize(_description)
       record.date = ""
       record.author = normalize(_authors)
       record.link = ""
       record.id = @search_id.to_s + ";" + @feed_id.to_s + ";" + (rand(1000000).to_s + rand(1000000).to_s + Time.now().year.to_s + Time.now().day.to_s + Time.now().month.to_s + Time.now().sec.to_s + Time.now().hour.to_s)
       record.doi = ""
       record.openurl = ""
       record.direct_url = normalize(_link)
       record.static_url = ""
       record.subject = normalize(_subjects)
       record.publisher = ""
       record.callnum = ""
       if @feed_url==nil: @feed_url = "" end
       record.vendor_url = @feed_url
       record.material_type = normalize(@feed_type)
       record.volume = ""
       record.issue = ""
       record.page = ""
       record.number = ""
       record.start = _start_time.to_f
       record.end = Time.now().to_f
       record.hits = _hit_count
       _record[_x] = record
       _x = _x + 1
    }
    return _record
  end

  def self.normalize(_string)
    return _string.gsub(/\W+$/,"") if _string != nil
    return ""
    #_string = _string.gsub(/\W+$/,"")
    #return _string
  end

end
