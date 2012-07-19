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


class CacheSearchClass < ActionController::Base

  attr_reader :is_in_cache, :records, :records_id
  def initialize()
     @is_in_cache = is_in_cache
     @records = Array.new()
     @records = records
     @records_id = records_id
  end

  def SearchCollection(_objRec, _collect_id, _search_id, _max)
      #======================================================
      # Check to see if data was cached -- if it is load
      #======================================================
      # NOTE: only runs for matched searches
      if _search_id != nil
        _lxml = CachedSearch.retrieve_metadata(_search_id, _collect_id, _max)
        logger.debug("found in cache");
        if _lxml != nil
          @is_in_cache = true
          if _lxml.status == LIBRARYFIND_CACHE_OK
            # Note:  it should never happen that .data is nil
            if _lxml.data != nil
              # Load from cache
              @records =  _objRec.unpack_cache(_lxml.data, _max.to_i)
 	      @records_id = _lxml.id
            end
          else
            if _lxml.status == LIBRARYFIND_CACHE_ERROR
              @is_in_cache=false
	    else
	      @is_in_cache=true
	      @records = nil
	      @records_id = _lxml.id
            end
          end
        else
 	  @is_in_cache = false
          logger.debug("Didn't find cached records")
        end
      end
      return true
  end
end
