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
require 'flickraw'

class FlickrSearchClass < ActionController::Base

  attr_reader :hits, :xml
  @cObject = nil
  @pkeyword = ""
  @feed_id = 0
  @search_id = 0

  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _last_id, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    logger.debug("flickr collection entered")
    @cObject = _collect
    @pkeyword = _qstring.join(" ")
    @feed_id = _collect.id
    @search_id = _last_id
    _lrecord = Array.new()
    
    begin
      #initialize
      logger.debug("COLLECT: " + _collect.host)
   
      #Do the search -- setting the openurl application 
      #type if present.
      #note -- we only support RSS and Atom
  
      #perform the search
      photos = flickr.photos.search :text => _qstring.join(" "), :per_page => _max.to_i
      logger.debug("Search performed")
    rescue Exception => bang
      logger.debug("flickr error" + bang)
      if _action_type != nil
         _lxml = ""
         logger.debug("ID: " + _last_id.to_s)
         my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY)
         return my_id, 0
      else
	 return nil
      end
    end

    if photos != nil 
      begin
	 logger.debug("Parsing photos")
         _lrecord = parse_photos(photos)
      rescue Exception => bang
	logger.debug("flickr error: " + bang)
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
 

  def self.parse_photos(xml) 
    logger.debug("Entering Photo Parsing")
    _objRec = RecordSet.new()
    _title = ""
    _authors = ""
    _description = ""
    _subjects = ""
    _publisher = ""
    _link = ""
    _thumbnail = ""
    _record = Array.new()
    _x = 0

    _start_time = Time.now()
    _hit_count = xml.total.to_i
    if xml.total.to_i > 0
     xml.each  { |image|
       begin
	  info = flickr.photos.getInfo :photo_id => image.id, :secret => image.secret
          _title = info.title
          _authors = info.owner.realname
          _description = info.description
          _subjects = get_tags(info)
          _link = "http://www.flickr.com/photos/" + info.owner.nsid.to_s + "/" + info.id.to_s
          _thumbnail = "http://farm" + info.farm.to_s + ".static.flickr.com/" + info.server.to_s + "/" + info.id.to_s + "_" + info.secret.to_s + "_s.jpg"

          _keyword = normalize(_title) + " " + normalize(_description) + normalize(_subjects)
          record = Record.new()
          record.rank = _objRec.calc_rank({'title' => normalize(_title), 'atitle' => '', 'creator'=>normalize(_authors), 'date'=>info.dates.taken, 'rec' => _keyword , 'pos'=>1}, @pkeyword)
          logger.debug("past rank")
          record.vendor_name = @cObject.alt_name
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
          record.vendor_url = normalize(@cObject.vendor_url)
          record.material_type = normalize(@cObject.mat_type)
          record.volume = ""
          record.issue = ""
          record.page = ""
          record.number = ""
          record.thumbnail_url = normalize(_thumbnail)
          record.start = _start_time.to_f
          record.end = Time.now().to_f
          record.hits = _hit_count
          _record[_x] = record
          _x = _x + 1
       rescue Exception => bang
	logger.debug("flickr error: " + bang)
	next
       end
    }
    end
    return _record 

  end  

  def self.get_tags(obj) 
     tags = ""
     if obj.tags.length > 0 
       obj.tags.each { |tag|
	 tags << tag.raw + "; "
       }
      end
      return tags 
  end
  def self.normalize(_string)
    return _string.gsub(/\W+$/,"") if _string != nil
    return ""
    #_string = _string.gsub(/\W+$/,"")
    #return _string
  end

end
