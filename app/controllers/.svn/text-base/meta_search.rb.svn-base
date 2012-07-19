# $Id: MetaSearch.rb 386 2006-09-01 23:34:07Z dchud $

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

require 'monitor'

class MetaSearch < ActionController::Base
  #========================================================
  #_sets is a hash -- format passed should be
  # :set => 'oasis;aph',
  # :group => 'image'
  # _query == value returned from using the 
  # _params = hash containing info
  # :start => 0
  # :max => 10
  # :force_reload => 1 (to force reload)
  # :session => 'session number' (only present if needed)
  #=========================================================

  def SimpleSearch(_sets, _qtype, _qstring, _start, _max)
     case _qtype.class.to_s
        when "Array"
            return Search(_sets, _qtype, _qstring, _start, _max, nil,nil,nil,true)
        else
          qtype = Array.new
          qstring = Array.new
          qtype[0] = _qtype
          qstring[0] = _qstring
          return Search(_sets, qtype, qstring, _start, _max, nil, nil, nil, true)
      end
   end 

  def SimpleSearchAsync(_sets, _qtype, _qstring, _start, _max)
     case _qtype.class.to_s
        when "Array"
            logger.debug("I'm HERE")
            return SearchAsync(_sets, _qtype, _qstring, _start, _max, 1,nil,nil,true)
        else
          logger.debug("I'm HERE2")
          qtype = Array.new
          qstring = Array.new
          qtype[0] = _qtype
          qstring[0] = _qstring
          return SearchAsync(_sets, qtype, qstring, _start, _max, 1, nil, nil, true)
      end
   end


  def Search(_sets, _qtype, _qstring, _start, _max, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true) 
    record = Array.new()
    _zoom = nil
    _objRec = RecordSet.new
    _objRec.setKeyword( _qstring[0])
    _stype = _qtype[0]
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    #_dbh = Mysql.real_connect(config['host'], config['username'], config['password'], 
    #config['database'])
    #config['database'], config['port'], nil, nil)
    _tmp = ""
    _max_recs = 0
    
    if _max == nil 
      _max = 10
    end
    
    _collections = Collection.find_resources(_sets)
    _query = ""       
    #================================================
    # Check the cache
    #================================================
    _search_id = nil
    # Has this search been run before?  Return the matching row as array if so 
    logger.debug("IS THIS FIXED: " + _qstring[0].to_s)
    logger.debug("STILL Correct: " + _qstring.join(" "))
    cached_recs = CachedSearch.check_cache(_qstring, _qtype, '')
    if cached_recs.length==0
      # _last_id is generated when this search is saved
      logger.debug("No matching search found")
      _last_id = CachedSearch.set_query(_qstring, _qtype, '', _max.to_i)
    else
      # _last_id is the id of the matching search
      _last_id = cached_recs[0].id
      logger.debug("Matching search: %s" % _last_id)
      # _search_id starts with same id, but is modified later
      _search_id = cached_recs[0].id
      # _max_recs is the saved number of hits per collection 
      # (which might be insufficient)
      _max_recs = cached_recs[0].max_recs
      logger.debug("max hits: " + _max_recs.to_s)
    end
    
    $lthreads = []
   
    objAuth = Authorize.new 
    _collections.each do |_collect|
      if _collect['is_private'] == 1
         next
      end
      #================================================
      # If in Cache -- extract data from the cache
      # and return
      #================================================
      _lrecord = Array.new()
      is_in_cache = false
      #======================================================
      # Check to see if data was cached -- if it is load
      #======================================================
      # NOTE: only runs for matched searches
      if _search_id != nil
        _lxml = CachedSearch.retrieve_metadata(_search_id, _collect.id, _max.to_i)
        logger.debug("found in cache"); 
        if _lxml != nil
          is_in_cache = true    
          if _lxml.status == LIBRARYFIND_CACHE_OK
            # Note:  it should never happen that .data is nil
            if _lxml.data != nil
              # Load from cache
              _lrecord =  _objRec.unpack_cache(_lxml.data, _max.to_i) 
              record.concat(_lrecord)
            end
          else
            if _lxml.status == LIBRARYFIND_CACHE_ERROR
	      is_in_cache=false
            end
          end
        else
          logger.debug("Didn't find cached records")
        end
      end
     
      logger.debug("QUERYSTRING1: " + _qstring.join(" ") + _collect.conn_type) 
      if is_in_cache == false
		  if _collect.conn_type == "oai"
			begin
			  #The reason we have to do this is because of ferret.  I'm 
			  #not sure why -- but I'm having all kinds of trouble with 
			  #ferret causing trouble in a threaded environment.
				  _tmparray = Array.new()
				  _start_thread = Time.now().to_f
				  logger.debug("QUERYSTRING: " + _qstring.join(" "))
				   eval("_tmparray = #{_collect.conn_type.capitalize}SearchClass.SearchCollection(_collect, _qtype, _qstring, _start.to_i, _max.to_i, _last_id, _session_id, _action_type, _data, _bool_obj)")
				  _end_thread =  Time.now().to_f - _start_thread
				  CachedSearch.save_execution_time(_last_id, _collect.id, _end_thread.to_s)
				  if _tmparray != nil: record.concat(_tmparray) end
			rescue
				logger.debug("Error generating oai search class")
			end
		  else
			begin
			        if _qstring.join(" ").index("site:") != nil
				   # we skip because this is only present for harvested materials
  				   next
				end
				_qstringtemp = pNormalizeString(_qstring)
				logger.debug("not oai, starting thread")
 				$lthreads << Thread.new(_collect) do |_coll|
				 Thread.current["myrecord"] = Array.new()
				 Thread.current["mycount"] = 0

				 _tmparray = Array.new()
				 _start_thread = Time.now().to_f
				 if _coll.conn_type != 'connector'
                                   eval("_tmparray = #{_coll.conn_type.capitalize}SearchClass.SearchCollection(_coll, _qtype, _qstringtemp, _start.to_i, _max.to_i, _last_id, _session_id, _action_type, _data, _bool_obj)")
                                 else
                                    eval("_tmparray = #{_coll.host.capitalize}SearchClass.SearchCollection(_coll, _qtype, _qstringtemp, _start.to_i, _max.to_i, _last_id, _session_id, _action_type, _data, _bool_obj)")
                                 end
				 _end_thread =  Time.now().to_f - _start_thread
				 CachedSearch.save_execution_time(_last_id, _coll.id, _end_thread.to_s) 
   				 if _tmparray != nil
					Thread.current["myrecord"].concat(_tmparray)
					Thread.current["mycount"] = _tmparray.length
				 end
				end
			rescue
			  logger.debug("Error generating other searchclasses")
			end
		  end
      end
    end
    
    $lthreads.each {|_thread| 
      begin
        _thread.join(300)
        if _thread["mycount"] != 0
          record.concat(_thread["myrecord"])
        end
      #rescue RuntimeError => e
      #  logger.debug(e.to_s)
      rescue
        next
      end
    } 
    $lthreads = nil
   
    CachedSearch.save_hits(_last_id, _session_id, record.size, _action_type, _data)
    if _bool_obj==false
      return _tmp
    else
      record.sort!{|a,b| b.rank.to_f <=> a.rank.to_f}
      #if record.length > (_max.to_i * 4)
      #  return record.slice(0,(_max.to_i*4))           
      #else
      return record
      #end
    end
  end
  
  def SearchAsync (_sets, _qtype, _qstring, _start, _max, _session_id=nil, _action_type=1, _data = nil, _bool_obj=true) 
    _objRec = RecordSet.new
    _zoom = nil
    _objRec.setKeyword( _qstring[0])
    _stype = _qtype[0]
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    #_dbh = Mysql.real_connect(config['host'], config['username'], config['password'], 
    #config['database'])
    #config['database'], config['port'], nil, nil)
    _tmp = ""
    _max_recs = 0
    
    if _max == nil 
      _max = 10
    end
    
    _collections = Collection.find_resources(_sets)
    _query = ""       
    #================================================
    # Check the cache
    #================================================
    _search_id = nil
    # Has this search been run before?  Return the matching row as array if so 
    logger.debug("IS THIS FIXED: " + _qstring.join("|").to_s)
    cached_recs = CachedSearch.check_cache(_qstring, _qtype, '')
    if cached_recs.length==0
      # _last_id is generated when this search is saved
      logger.debug("No matching search found")
      _last_id = CachedSearch.set_query(_qstring, _qtype, '', _max.to_i)
    else
      # _last_id is the id of the matching search
      _last_id = cached_recs[0].id
      logger.debug("Matching search: %s" % _last_id)
      # _search_id starts with same id, but is modified later
      _search_id = cached_recs[0].id
      # _max_recs is the saved number of hits per collection 
      # (which might be insufficient)
      _max_recs = cached_recs[0].max_recs
      logger.debug("max hits: " + _max_recs.to_s)
    end
    
    spawn_ids = []
    myjob = []
    _objCache = []
    _collections.each_index { |_index|
      _is_private = false
      if _collections[_index]['is_private'] == 1
         _is_private = true
      end

      #================================================
      # If in Cache -- extract data from the cache
      # and return
      #================================================
      if _collections[_index] == nil
        continue;
      end
    
      myjob[_index] = JobQueue.create_job()
      spawn_ids[_index] = spawn do
		JobQueue.update_job(myjob[_index], nil, _collections[_index].alt_name, 1)	
		_objCache[_index] = CacheSearchClass.new()
		_objCache[_index].SearchCollection(_objRec, _collections[_index].id, _search_id, _max.to_i)     
		logger.debug("Spawn ID: " + spawn_ids[_index].to_s)
		logger.debug("IS IN CACHE: " + _objCache[_index].is_in_cache.to_s + "\n\n\n\n\n") 
		if _objCache[_index].is_in_cache == true  && _objCache[_index].records != nil
			logger.debug("spawn process to found in thread")
			logger.debug(myjob[_index].to_s)
			# need to mark query as finished.
			if _is_private == true
			   JobQueue.update_job(myjob[_index],_objCache[_index].records_id,  _collections[_index].alt_name, -2, _objCache[_index].records.length)
			else
                           JobQueue.update_job(myjob[_index],_objCache[_index].records_id,  _collections[_index].alt_name, 0, _objCache[_index].records.length)
 			end
		elsif _objCache[_index].is_in_cache == true && _objCache[_index].records == nil
		    # no records were found in the search -- results are zero
		    JobQueue.update_job(myjob[_index], _objCache[_index].records_id, _collections[_index].alt_name, 0, 0)
		else
		   begin
			_start_thread = Time.now().to_f
			my_id = 0
			my_hits = 0
			if _qstring.join(" ").index("site:") != nil
			   if _collections[_index].conn_type != 'oai'
  			  	tmpreturn = JobQueue.update_job(myjob[_index], my_id, _collections[_index].alt_name, 0, 0) 
				next
			   end
			end
		        if _collections[_index].conn_type != 'connector'
			  if _collections[_index].conn_type != 'oai'
                            logger.debug("INDEXER: " + LIBRARYFIND_INDEXER)
			    _querytmp = pNormalizeString(_qstring)
			    eval("my_id, my_hits = #{_collections[_index].conn_type.capitalize}SearchClass.SearchCollection(_collections[_index], _qtype, _querytmp, _start.to_i, _max.to_i, _last_id, _session_id, 1, _data, _bool_obj)")
			  else
			    eval("my_id, my_hits = #{_collections[_index].conn_type.capitalize}SearchClass.SearchCollection(_collections[_index], _qtype, _qstring, _start.to_i, _max.to_i, _last_id, _session_id, 1, _data, _bool_obj)")
			  end
  		        else
			  logger.debug("connector: " + _collections[_index].host.capitalize + "SearchClass.SearchCollection")
			  _qstringtmp = pNormalizeString(_qstring)
			  logger.debug("Query string: " + _qstringtmp.join(" "))
			  eval("my_id, my_hits = #{_collections[_index].host.capitalize}SearchClass.SearchCollection(_collections[_index], _qtype, _qstringtmp, _start.to_i, _max.to_i, _last_id, _session_id, 1, _data, _bool_obj)")
			end 
			_end_thread =  Time.now().to_f - _start_thread
			CachedSearch.save_execution_time(_last_id, _collections[_index].id, _end_thread.to_s)
			logger.debug("My_ID " + my_id.to_s)
			if my_id != nil
			  # Set the job id message for finished.
			  logger.debug("Updating status: " + "\njobid: " + myjob[_index].to_s + "\nmyid: " + my_id.to_s)
			  if _is_private == true
			    tmpreturn = JobQueue.update_job(myjob[_index], my_id, _collections[_index].alt_name, -2, my_hits)
			  else
  			    tmpreturn = JobQueue.update_job(myjob[_index], my_id, _collections[_index].alt_name, 0, my_hits) 
                          end
 			  logger.debug("return value from update: " + tmpreturn.to_s)
			else
			  # Set the job id message for error; 
   			  JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, -1, "Unable to establish/maintain a connection to the resource")
			end 
		   rescue Exception => bang
			logger.debug("unable to find class" + "\n\n" + bang)
			logger.debug(bang.backtrace.join("\n"))
			JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, -1, "Undefined error: Unable to content to the resource")
		   end
		end
      end
      # Update the thread_ids to the job
      #
      logger.debug("job id: " + myjob[_index].to_s)
      logger.debug("spawn id: " + spawn_ids[_index].handle.to_s)
      logger.debug("index: " + _index.to_s)
      JobQueue.update_thread_id(myjob[_index], spawn_ids[_index].handle)
    }
    
    return myjob
  end
  

  # pass a list of job ids and 
  # then deal with it
  def CheckJobStatus(_ids)
      objJobs = [] 
      i = 0
      case _ids.class.to_s
        when "Array"
           _ids.each do |_id|
              tmpobj = JobQueue.check_status(_id)
	      if tmpobj != nil
  	        objJobs[i] = JobItem.new()
 		objJobs[i].job_id = tmpobj.id
		objJobs[i].record_id = tmpobj.records_id
          	objJobs[i].thread_id = tmpobj.thread_id
		objJobs[i].target_name = tmpobj.database_name
		objJobs[i].hits = tmpobj.hits
		objJobs[i].status = tmpobj.status
		objJobs[i].error = tmpobj.error
		i = i + 1
	      end
           end
	   return objJobs
        else
	   tmpobj = JobQueue.check_status(_ids)
	   objJobs[i] = JobItem.new()
	   objJobs[i].job_id = tmpobj.id
	   objJobs[i].record_id = tmpobj.records_id
	   objJobs[i].thread_id = tmpobj.thread_id
           objJobs[i].target_name = tmpobj.database_name
	   objJobs[i].hits = tmpobj.hits
	   objJobs[i].status = tmpobj.status
	   objJobs[i].error = tmpobj.error
	   return objJobs[i]
       end

  end
  
  # Retrieve the individual job records.
  # this basically is just an extraction from the cache
  def GetJobRecord(job_id,  _max)
      _objRec = RecordSet.new
      _xml = JobQueue.retrieve_metadata(job_id, _max);
      if _xml != nil
         if _xml.status == LIBRARYFIND_CACHE_OK
           # Note:  it should never happen that .data is nil
           if _xml.data != nil
              return _objRec.unpack_cache(_xml.data, _max.to_i)
	   end
	 end
      end
      return nil
  end 

  def KillThread(job_id, thread_id)
     if (thread_id.to_i > 0) 
       JobQueue.update_job(job_id, 0, 0); 
       return Process.kill("KILL", thread_id);
     end
  end 

  def GetJobsRecords(job_ids, _max)
     _recs = []
     _tmp = []
     _objRec = RecordSet.new
     job_ids.each do |_id|
       _xml = JobQueue.retrieve_metadata(_id, _max)
       if _xml != nil
         if _xml.status == LIBRARYFIND_CACHE_OK
         # Note:  it should never happen that .data is nil
           if _xml.data != nil
	      #logger.debug("XML to UNPACK: " + _xml.data)
              # Load from cache
              _tmp =  _objRec.unpack_cache(_xml.data, _max.to_i)
	      if _tmp != nil
                _recs.concat(_tmp)
 	      end
           end
	 end
       end
     end
     return _recs;
  end

  def ListCollections()
    objList = []
    objCollections = Collection.get_all()
    objCollections.each do |item|
      objCollectionList = CollectionList.new()
      objCollectionList.id = "c" + item.id.to_s
      objCollectionList.name = item.alt_name
      objMembers = CollectionGroup.get_parents(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "g" + coll.collection_group_id.to_s
	tmpvals = CollectionGroup.get_item(coll.collection_group_id)
        if tmpvals != nil
           arrNames << tmpvals
        else
	   arrNames << "[undefined]"
	end
      end
      objCollectionList.member_ids = arrIds
      objCollectionList.member_names = arrNames
      objList << objCollectionList  
    end   
    return objList
  end
  
  def ListGroups()
    objList = []
    objGroups = CollectionGroup.get_all()
    objGroups.each do |item|
      objGroupList = GroupList.new()
      objGroupList.id = "g" + item.id.to_s
      objGroupList.name = item.full_name
      objMembers = CollectionGroup.get_members(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "c" + coll.collection_id.to_s
	tmpvals = Collection.get_item(coll.collection_id)
	if tmpvals != nil
          arrNames << Collection.get_item(coll.collection_id)
        else
	  arrNames << "[undefined]"
	end 
      end
      objGroupList.member_ids = arrIds
      objGroupList.member_names = arrNames
      objList << objGroupList
    end 
    return objList
  end
  
  def GetGroupMembers(name)
    objGroupList = GroupList.new()
    objGroups = CollectionGroup.get_item_by_name(name)
    objGroups.each do |item|
      objGroupList.id = "g" + item.id.to_s
      objGroupList.name = item.full_name
      objMembers = CollectionGroup.get_members(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "c" + coll.collection_id.to_s
        tmpvals = Collection.get_item(coll.collection_id)
        if tmpvals != nil
          arrNames << Collection.get_item(coll.collection_id)
        else
	  arrNames << "[undefined]"
	end 
      end
      objGroupList.member_ids = arrIds
      objGroupList.member_names = arrNames
    end
    return objGroupList
  end

  def GetId(id)
     arr = id.split(";")
     _objRec = RecordSet.new    
     _lxml = CachedSearch.retrieve_metadata(arr[0], arr[1], -1)     
     if _lxml == nil
       return nil
     end
     _lrecord =  _objRec.unpack_cache(_lxml.data, -1)
     _lrecord.each do |rec|
        if rec.id == id #arr[2]
           return rec
        end 
     end
     return nil 
  end

  def TestCollection(id)
    #to be implemented 
  end

  def pNormalizeString(_qstring)
    _tqstring = Array.new(_qstring)
    _tmpsite = ""
    i = 0
    while i != _tqstring.length
      if _tqstring[i].index("site:")!= nil
         _tmpsite = _tqstring[i].slice(_tqstring[i].index("site:"), _tqstring[i].length - _tqstring[i].index("site:")).gsub("site:", "")
         _tqstring[i] = _tqstring[i].slice(0, _tqstring[i].index("site:")).chop
         if _tmpsite.index('"') != nil
            _tqstring[i] << '"'
         end
      elsif _tqstring[i].index("sitepref:") != nil
         _tmpsite = _tqstring[i].slice(_tqstring[i].index("sitepref:"), _tqstring[i].length - _tqstring[i].index("sitepref:")).gsub("sitepref:","")
         _tqstring[i] = _tqstring[i].slice(0, _tqstring[i].index("sitepref:")).chop
         if _tmpsite.index('"') != nil
            _tqstring[i] << '"'
         end
       end 
       i = i+1
    end
    return _tqstring
  end
  
  
  
end 
