# $Id: z3950_search_class.rb 386 2006-09-01 23:34:07Z dchud $

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

class Z3950SearchClass < ActionController::Base
        @zoom = nil
	def self.SearchCollection(_coll, _qtype, _qstring, _start, _max, _last_id, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
	#Threading code has been moved outside the class to the initializing code in meta_search.rb.  These comments
        #will be removed in 0.9
        #$lthreads << Thread.new(collection) do |_coll|
	#	Thread.current["myrecord"] = Array.new()
	#	Thread.current["mycount"] = 0
		_ltrecord = Array.new()
		_tmprec = nil
	        _objRec = RecordSet.new
	       _objRec.setKeyword( _qstring[0])
	
		#=======================================================
		# we put the require here so users don't
		# have to load the z39.50 components unless they have to
		#=======================================================
		#@zoom = RZOOM.new if @zoom.nil?
		_zoom = RZOOM.new #@zoom
	       
		_params = _coll.zoom_params(_qtype[0])
		_params['search_id'] = _last_id
		_params['collection_id'] = _coll.id
	        
		_items = _zoom.search(_params, _qtype[0], _qstring[0], _start, _max.to_i)
		_params['hits'] = _zoom.hits
	        
		if _items != nil 
			for _i in 0.._items.length-1
				case _coll.record_schema.downcase
					when "sutrs"
						if _bool_obj == false
							_xml = _objRec.sutrs2xml(_items[_i].to_s) 
							_tmp << _objRec.unpack_marcxml(_params, _xml, _params['def'], false)
						else
							_xml = _objRec.sutrs2xml(_items[_i].to_s)
							#_lrecord <<  _objRec.unpack_sutrs(_params, _xml, _params['def'], true)
							_tmprec = _objRec.unpack_marcxml(_params, _xml, _params['def'], true)
							if _tmprec != nil: _ltrecord << _tmprec end
						end
					else
						logger.debug('Running here....')
						if _bool_obj == false
							_tmp << _objRec.unpack_marcxml(_params, _items[_i].xml("marc8", "utf8"), _params['def'], false)
						else
							#_lrecord <<  _objRec.unpack_marcxml(_params, _items[_i].xml("marc8", "utf8"), _params['def'], true)
							_tmprec = _objRec.unpack_marcxml(_params, _items[_i].xml("marc8", "utf8"), _params['def'], true)
							if _tmprec != nil: _ltrecord << _tmprec end
						end
				end 
			end  
			_tprint = false   
	       
			if _ltrecord !=nil 
				#Thread.current["myrecord"].concat(_ltrecord)
                                #logger.debug("First Record again: " + Thread.current['myrecord'][0].vendor_name)
				#Thread.current["mycount"] = _ltrecord.length
		    
				_lxml = CachedSearch.build_cache_xml(_ltrecord)

				if _lxml != nil: _tprint = true end            
				if _lxml == nil: _lxml = "" end
			end
			#=========================================================
			# Add this info into the cache
			#=========================================================
			if _last_id.nil?
				# FIXME: Raise an error
				logger.debug("Error, _last_id should not be null")
			else
				logger.debug("Save metadata")
				md = ""
				status = LIBRARYFIND_CACHE_OK
				if _tprint == true
					md = _lxml
				else
					if _items.nil?
						status = LIBRARYFIND_CACHE_ERROR
					else
						status = LIBRARYFIND_CACHE_EMPTY
					end
				end
				my_id = CachedSearch.save_metadata(_last_id, md, _coll.id, _max.to_i, status)
			end
		end
	#end #End Thread
        #we return a nil because the data is stored in the thread variables.
	#return nil  
        if _action_type != nil 
	   logger.debug("action_type set")
	   if _ltrecord != nil
	     return my_id,_ltrecord.length
           else
	     return my_id, 0
	   end
        else
	  logger.debug("action_type not set")
 	  return _ltrecord
        end
    end
end
