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
require 'sru'

class SruSearchClass < ActionController::Base

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
      client = SRU::Client.new(_collect.host, :parser => ::PARSER_TYPE)
      logger.debug("Host: " + _collect.host)

      _params = _collect.zoom_params(_qtype[0])
      _params['search_id'] = _last_id
      _params['collection_id'] = _collect.id

      pquery = ""
      @pkeyword = @pkeyword.gsub("\"", "")
      if _qtype[0] == 'keyword'
        pquery = "\"" + @pkeyword + "\""
      else
        pquery = _qtype[0] + "=" + "\"" + @pkeyword + "\""
      end 
     
      logger.debug("SRU Query: " + pquery)
      logger.debug("recordSchema: " + _params['syntax'])
      sru_records = client.search_retrieve(pquery, {:recordSchema => _params['syntax'], :maximumRecords => _max})
      logger.debug("SRU Results: " + sru_records.entries.size.to_s)
      _params['hits'] = sru_records.entries.size
      _objRec = RecordSet.new()
      _tmprec = nil
      for record in sru_records
         logger.debug("SRU -- have entered loop")
         #if marcxml then we unpack
	 if _params['syntax'].downcase == 'marcxml'
           logger.debug("Processing SRU result")
           record = record.to_s.gsub("</zs:recordData>", "").gsub("<zs:recordData>", "")
           _tmprec = _objRec.unpack_marcxml(_params, record, _params['def'], true)
           if _tmprec != nil: _lrecord << _tmprec end
         #else #assume dc
         #  _tmprec = parse_dc(record)
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

    if sru_records.entries.size <= 0
      begin
	 if _action_type != nil
            _lxml = ""
            logger.debug("ID: " + _last_id.to_s)
            my_id = CachedSearch.save_metadata(_last_id, _lxml, _collect.id, _max.to_i, LIBRARYFIND_CACHE_EMPTY)
            return my_id, 0
         else
	    return nil
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
end
