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

class OaiSearchClass < ActionController::Base

  
  attr_reader :hits, :xml
  
  @pid = 0
  @pkeyword = ""
  def self.keyword (_string)
    @pkeyword = _string
  end

  def self.insert_id(_id) 
    @pid = _id
  end
  
  def self.SearchCollection(_collect, _qtype, _qstring, _start, _max, _last_id, _session_id=nil, _action_type=nil, _data = nil, _bool_obj=true)
    #_obj_OAI = FerretIndexClass.new()
    _lrecord = Array.new()
    keyword(_qstring[0])
    _type = ""
    _alias = ""
    _group = ""
    _vendor_url = ""
    _coll_list = ""
    
    _query = "SELECT DISTINCT collections.id, collections.alt_name, controls.id, controls.oai_identifier, controls.collection_id, controls.url, controls.title, controls.description, metadatas.dc_subject, metadatas.dc_creator, metadatas.dc_date, metadatas.dc_format, metadatas.dc_type, metadatas.osu_thumbnail from collections LEFT JOIN controls ON collections.id=controls.collection_id  LEFT JOIN metadatas on controls.id = metadatas.controls_id where ("
    
    _coll_list =_collect.id 
    _type = _collect.mat_type
    _alias = _collect.alt_name
    _group = _collect.virtual
    _is_parent = _collect.is_parent
    _col_name = _collect.host.gsub(":", "_") + _collect.name
    _vendor_url = _collect.vendor_url
    
    #_lrecord = _obj_OAI.RetrieveOAI_Single(_last_id, _query, _qtype, _qstring, _type, _coll_list, _alias, _group, _vendor_url, _max.to_i)
    _lrecord = RetrieveOAI_Single(_last_id, _query, _qtype, _qstring, _type, _coll_list, _alias, _group, _vendor_url, _is_parent, _col_name,_max.to_i)
    
    _lprint = false; 
    if _lrecord != nil
		#record.concat(_lrecord)
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
 
  def self.normalizeFerretKeyword(_string)
     return "" if _string == nil
     #the quote isn't escaped because it is actually useful in this case.
     _string = _string.gsub(/([\'\:\(\)\[\]\{\}\!\+\~\^\-\|\<\>\=\*\?\\])/, '\\\\\1')
     return _string
  end

  def self.normalizeSolrKeyword(_string)
     return "" if _string == nil
     # Escape characters: +-&&||!(){}[]^"~*?:\
     _string = _string.gsub(/([\'\:\(\)\[\]\{\}\!\+\~\^\-\|\<\>\=\*\?\\])/, '\\\\\1')
     return _string
  end
 
  def self.normalizeDate(_string)
    return "" if _string == nil
    return "" if _string == ""
    _string = _string.gsub(/-/, "")
    arr = _string.split(';')
    arr.each do |item|
	item = item.chomp
	logger.debug("Item: " + item + "\nLength: " + item.length.to_s)
	if item.length <= 10
          _string = _string.gsub(/[^0-9]/, "")
          case _string.length
            when 8: return _string.slice(0,4) + _string.slice(4,2) + _string.slice(6,2)
            when 6: return _string.slice(0,4) + _string.slice(4,2) + "00"    
            when 4: return _string + "0000"
            else return ""
          end
        end
    end
    return ""
  end
  
  def self.normalize(_string)
    return _string.gsub(/\W+$/,"") if _string != nil
    return ""
    #_string = _string.gsub(/\W+$/,"")
    #return _string
  end
 
  def self.RetrieveOAI_Single(_search_id, _query, _qtype, _qstring, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name,  _max)
     htype = {_coll_list => _type}
     halias = {_coll_list => _alias}
     hgroup = {_coll_list => _group}
     hvendor = {_coll_list => _vendor_url}
     hparent = {_coll_list => _is_parent}
     hcolname = {_coll_list => _collection_name}
     _recs = Array.new()
     logger.debug("Oai_Qstring2: " + _qstring.length.to_s)
     return  RetrieveOAI(_search_id, _query, _qtype, _qstring, htype, _coll_list, halias, hgroup, hvendor, hparent, hcolname, _max)
  end
 
  def self.RetrieveOAI(_search_id, _query, _qtype, _qstring, _type, _coll_list, _alias, _group, _vendor_url,  _is_parent, _collection_name, _max)
    _x = 0
    _y = 0
    _oldset = ""
    _newset = ""
    _count = 0
    _tmp_max = 1
    _xml_tmp = ""
    _xml = ""
    _start_time = Time.now()
    _objRec = RecordSet.new()
    _hits = Hash.new()
    _bfound = false;

    logger.debug("OAI Search")

    if _max.class != 'Int': _max = _max.to_i end

    _keywords = _qstring.join("|")
    #if _keywords.slice(0,1)=='"'
    logger.debug("keywords enter")
    #_keywords = _keywords.gsub(/^"*/,'')
    #_keywords = _keywords.gsub(/"*$/,'')
    #logger.debug("keywords exit")
    #else  
    #   _keywords = '"' + _keywords + '"' 
    #end 

    _site = nil 
    _sitepref = nil 
    logger.debug("KEYWORD BEFORE PREF: " + _keywords)
    if _keywords.index("site:")!= nil 
      _site = _keywords.slice(_keywords.index("site:"), _keywords.length - _keywords.index("site:")).gsub("site:", "")
      _keywords = _keywords.slice(0, _keywords.index("site:")).chop
      if _site.index('"') != nil
         _site = _site.gsub('"', "")
         _keywords << '"'
      end
    elsif _keywords.index("sitepref:") != nil
      _sitepref = _keywords.slice(_keywords.index("sitepref:"), _keywords.length - _keywords.index("sitepref:")).gsub("sitepref:", "")
      logger.debug("SITE PREF: " + _sitepref)
      _keywords = _keywords.slice(0, _keywords.index("sitepref:")).chop
      if _sitepref.index('"') != nil
    	_sitepref = _sitepref.gsub('"', "")
  	_keywords << '"'
      end
    end

    logger.debug("KEYWORDs: " + _keywords)
    _calc_keyword = _keywords

    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      _keywords = normalizeFerretKeyword(_keywords)
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      _keywords = normalizeSolrKeyword(_keywords)
    end
    if _keywords.slice(0,1) != "\""
      if _keywords.index(' OR ') == nil
        _keywords = _keywords.gsub("\"", "'")
	#I think this is a problem.
        #_keywords = "\"" + _keywords + "\""
      end
    end

    if LIBRARYFIND_INDEXER.downcase == 'ferret'

      #_keywords = _keywords.gsub("'", "\'")   
      #_keywords = _keywords.gsub("\"", "'")
      #index = Ferret::Index::Index.new(:path => LIBRARYFIND_FERRET_PATH)
      #  index.search_each('collection_id:(' + _coll_list.to_s + ') AND ' + _qtype.join("|") + ':"' + _keywords + '"', :limit => _max) do |doc, score|
      index = Ferret::Search::Searcher.new(LIBRARYFIND_FERRET_PATH)
      #index = Ferret::Index::Index.new(:path => LIBRARYFIND_FERRET_PATH)
      queryparser = Ferret::QueryParser.new()
      logger.debug("KEYWORD: " + _keywords)
      if _is_parent[_coll_list] == 1 
         logger.debug("IS PARENT")
         raw_query_string = 'collection_id:("' + normalizeFerretKeyword(_coll_list.to_s) + '") AND ' + _qtype.join("|") + ":(" + _keywords + ")"
         query_object = queryparser.parse(raw_query_string)
         logger.debug("RAW FERRET QUERY: "  + raw_query_string)
         logger.debug("FERRET QUERY: " + query_object.to_s)
      else
         logger.debug("NOT PARENT: " + _collection_name[_coll_list])
         _collection_name[_coll_list] = _collection_name[_coll_list].gsub("http_//", "") 
	 
	 raw_query_string = "collection_name:(\"" + normalizeFerretKeyword(_collection_name[_coll_list]) + "\") AND " + _qtype.join("|") + ":(" + _keywords + ")"
         query_object  = queryparser.parse(raw_query_string)
         logger.debug("RAW FERRET QUERY: " + raw_query_string)
         logger.debug("FERRET QUERY: " + query_object.to_s)
      end
      index.search_each(query_object, :limit => _max) do |doc, score|

        # An item should have a score of 50% or better to get into this list
          break if score < 0.40
          _query << " controls.id=" + index[doc]["controls_id"].to_s + " or "
          _bfound = true;

       end 
    
       index.close

    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
       logger.debug("Entering SOLR")
       conn = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
       if _is_parent[_coll_list] == 1
     	 logger.debug("IS PARENT: SOLR")
    	 raw_query_string = "+collection_id:(\"#{_coll_list.to_s}\") +" + _qtype.join("|") + ":(" + _keywords + ")"
       else
    	 logger.debug("NOT PARENT")
 	  
         _collection_name[_coll_list] = _collection_name[_coll_list].gsub("http_//", "")
    	 raw_query_string = "+collection_name:(\"#{_collection_name[_coll_list]}\") +" + _qtype.join("|") + ":(" + _keywords + ")"
       end
       logger.debug("RAW STRING: " + raw_query_string)
       conn.query(raw_query_string, :rows => _max) do |hit|
          if defined?(hit["controls_id"]) == false
             break
          end 
	  _query << " controls.id=" + hit["controls_id"].to_s + " or "
	  _bfound = true
       end
    end 
    if _bfound == false 
       logger.debug("nothing found: " + _coll_list.to_s)
       return nil 
    end
    _query = _query.slice(0, (_query.length- " or ".length)) + ")"
    
    if _site != nil 
       _query << " and controls.url like '%" + _site + "%'"
    end
    _query <<  " order by controls.collection_id"
    logger.debug("COLLECION: " + _coll_list.to_s + " -- QUERY: " + _query)
    config = ActiveRecord::Base.configurations[RAILS_ENV]
   # _dbh = Mysql.real_connect(config['host'], config['username'], config['password'], config['database'])
   _results = Collection.find_by_sql(_query) 

    #_results = _dbh.query(_query)
    _record = Array.new()
    _tmpArray = Array.new()
    _i = 0
    _newset = ""
    _trow = nil
    _results.each { |_row|
      if _is_parent[_coll_list] != 1
         logger.debug("Find: " + _coll_list.to_s)
	 _trow = Collection.find(_coll_list)
         if _trow != nil then
           logger.debug("COLLECTION RESOLVED")
           _newset = _trow.alt_name
	   logger.debug('NEW COLLECTION NAME SET' + _newset)
         else
	  logger.debug("CHECK: " +  _row.collection_id.to_s + ";" + normalize(_row.oai_identifier))
          _newset = _row.alt_name
         end
      else
        logger.debug("CHECK: " +  _row.collection_id.to_s + ";" + normalize(_row.oai_identifier))
        _newset = _row.alt_name
      end

      if _oldset != ""  
        if  _oldset != _newset
	  _hits[_oldset] = _tmp_max-2 
          _count = 0
          _tmp_max = 1
        end
      elsif _oldset == ""
        #_alias[_row["collection_id"]] = ""
        _count = 0
      end
      
      if _tmp_max <= _max
        logger.debug("Prepping to print Title, etc.")
        record = Record.new()
        logger.debug("Title: " + normalize(_row.title))
        logger.debug("creator: " + normalize(_row.dc_creator))
        logger.debug("date: " + normalizeDate(_row.dc_date))
        logger.debug("description: " + normalize(_row.description))
        logger.debug("SITE PREF: " + normalize(_sitepref))
        logger.debug("SITE URL: " + normalize(_row.url))

        begin
           record.rank = _objRec.calc_rank({'title' => normalize(_row.title), 'atitle' => '', 'creator'=>normalize(_row.dc_creator), 'date'=>normalizeDate(_row.dc_date), 'rec' => normalize(_row.description), 'pos'=>1, 'pref' => _sitepref, 'url' => normalize(_row.url) }, _calc_keyword)
        rescue StandardError => bang2 
           logger.debug("ERROR: " + bang2)
	   record.rank = 0
	end
	if _is_parent[_coll_list] != 1 && _trow != nil
           record.vendor_name = normalize(_trow.alt_name)
        else
           record.vendor_name = _row.alt_name
        end 
        #record.vendor_name = _newset

        _tmp_type = normalize(_type[_row.collection_id.to_i])
        if _row.dc_type != nil and _row.dc_type.index(/[;\/\?\.]/) == nil
          _tmp_type = normalize(_row.dc_type.capitalize)
        end

        record.ptitle = normalize(_row.title)
	if normalize(_tmp_type) == 'Article'
	   record.title = ""
	   record.atitle = normalize(_row.title)
	else
           record.title =  normalize(_row.title)
           record.atitle =  ""
	end

        logger.debug("record title: " + record.title)
        record.issn =  ""
        record.isbn = ""
        record.abstract = normalize(_row.description)
        record.date = normalizeDate(_row.dc_date)
        record.author = normalize(_row.dc_creator)
        record.link = ""
        record.id = _search_id.to_s + ";" + _row.collection_id.to_s + ";" + normalize(_row.oai_identifier)
        record.doi = ""
        record.openurl = ""
        record.thumbnail_url = normalize(_row.osu_thumbnail)
        record.direct_url = normalize(_row.url)
        record.static_url = ""
        record.subject = normalize(_row.dc_subject)
        record.publisher = ""
        record.callnum = ""
        
        if _is_parent[_coll_list] != 1 && _trow != nil
          if _vendor_url[_trow.id] == nil: _vendor_url[_trow.id] == "" end
          record.vendor_url = _vendor_url[_trow.id]
	  record.material_type = normalize(_tmp_type)
        else          
	  if _vendor_url[_row.collection_id]==nil: _vendor_url[_row.collection_id] = "" end 
          record.vendor_url = _vendor_url[_row.collection_id]
          record.material_type = normalize(_tmp_type)
        end 

        record.volume = ""
        record.issue = ""
        record.page = ""
        record.number = ""
        record.start = _start_time.to_f
        record.end = Time.now().to_f
        _record[_x] = record
        _x = _x + 1
      end
      
      _oldset = _newset
      _count = _count + 1
      _tmp_max = _tmp_max + 1
    }

    if _hits.length!=0
       logger.debug("Hits: " + _record.length.to_s)
       logger.debug("hits array: " + _hits.length.to_s)
       for _i in 0..(_record.length-1)
	   _record[_i].hits = _hits[_record[_i].vendor_name].to_i #(_tmp_max-1)
       end
    else
       logger.debug("Hits 2: " + _record.length.to_s)
       for _i in 0..(_record.length-1)
         _record[_i].hits = _tmp_max - 1
       end
    end
    logger.debug("Record Hits: " + _record.length.to_s)
    
    return _record
  end
end
