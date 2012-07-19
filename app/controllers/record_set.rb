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

require 'net/http'
require 'uri'
require 'ropenurl'

class RecordSet  < ActionController::Base
  #Structs
  @@citation = Struct.new(:volume, :issue,:page)
  #I believe that static is deprecated -- but will include for now
  @@url = Struct.new(:open, :direct,:static,:vendor) 
  attr_reader :pkeyword
  attr_reader :hits, :xml
  
  def setKeyword(_val) 
    @pkeyword = _val
  end
  
  def getKeyword()
    return @pkeyword
  end

  def setId(_val) 
    @pid = _val
  end

  def getId()
    return @pid
  end
 
  #unpack the cache xml
  def unpack_cache(_recs, _max)
    if _recs == nil
      logger.debug("_recs is nil")
    end
    if _recs == ''
      logger.debug("_recs is empty")
    end 

    return nil if _recs == nil
    return nil if _recs == ''
    arr_rec = Array.new()
    _counter = 0

    _xpath = Xpath.new()
    parser = ::PARSER_TYPE
    begin
      case parser
      when 'libxml' 
        _parser = LibXML::XML::Parser.new()
        _parser.string = _recs
        _xml = LibXML::XML::Document.new()
        _xml = _parser.parse
      when 'rexml'
        _xml = REXML::Document.new(_recs)
      end
    rescue
      return nil
    end
 
    nodes = _xpath.xpath_all(_xml, "//item") #_xml.find("//item")
    if _max ==  -1: _max = nodes.length  end
    nodes.each do |rec|
      record = Record.new()
      rec.each do |item|
        _tmpText = _xpath.xpath_get_text(item)
        if _xpath.xpath_get_name(item) != nil
        #if item.name != 'text'
          if _xpath.xpath_get_name(item)!=nil
            eval("record." + _xpath.xpath_get_name(item) + "=" + _tmpText.dump) 
          end
        end
      end 
      arr_rec << record
      _counter = _counter + 1
      if _counter >= _max
         return arr_rec
      end
    end
    return arr_rec
  end

 
  #unpacks a MARCXML record utilizing the information from the def.
  #might want to look at if we can use YAML or using Sax
  #process to handle a bit more of this.
  def unpack_marcxml(_host, _recs, _def, _bool_obj) 
    _start_time = Time.now()
    _openvals = Hash.new
    _rechash = Hash.new
    _tarray = _def.split(';')
    #_xml = Document.new(_recs)
    _prefix = ''

    @xml = ""

    if _recs.index('marc:') != nil
      _prefix = "marc:"
    else
      #if non-standard namespaces are used, 
      #we need to strip them otherwise, they won't 
      #world
      if _recs.index(":datafield")!=nil
        _recs = _recs.gsub(/<[a-zA-Z0-9]*\:/, '<').gsub(/<\/[a-zA-Z0-9]*\:/, '</') 
      end
    end
    
    if _recs.index('xmlns="http://www.loc.gov/MARC21/slim"') != nil
      _recs = _recs.gsub('xmlns="http://www.loc.gov/MARC21/slim"', "")
    end

    _xpath = Xpath.new()
    parser = ::PARSER_TYPE
    case parser
    when 'libxml'
      _parser = XML::Parser.new()
      _parser.string = _recs
      _xml = XML::Document.new()
      _xml = _parser.parse
    when 'rexml'
       _xml = REXML::Document.new(_recs)
    end
    
    
    _url = checknil(_host['url'])
    _tarray.each() {|_x|
      _start = _x.index('=')
      _tlabel = getLabel(_x.slice(0,_start))
      #define our hash entries
      
      if _rechash[_tlabel]==nil
        _rechash[_tlabel] = ''
      end
      
      _tfield = _x.slice(_start+1,_x.size-(_start+1))
      
      if _tfield.size > 3
        #has subfield or position data
        _tsubfield = _tfield.slice(3,_tfield.size-3)
        #if _tfield!='link'
          _tfield = _tfield.slice(0,3)
        #end
      else
        _tsubfield = nil
      end
     
      if _tlabel == 'link'
        #======================================
        # first thing -- look for title and 
        # issn.
        #======================================
	begin 
          _tmp = ''
          _linktext = ''
           _nodes = _xpath.xpath_all(_xml, "//" + _prefix + "datafield[@tag='" +  _tfield + "']")
           _nodes.each {|_element|

            _tmp = _xpath.xpath_all(_element, "subfield[@code='t']")
            if _tmp != nil && _tmp!=""
	       _rechash['title'] = _xpath.xpath_get_text(_tmp[0])
            end

            _tmp = _xpath.xpath_all(_element, "subfield[@code='x']")
            if _tmp != nil && _rechash['issn'] == nil
              _rechash['issn'] = _xpath.xpath_get_text(_tmp[0])
            end 

            _tmp = _xpath.xpath_all(_element, "subfield[@code='d']")
            if _tmp != nil
              _tmpb = _xpath.xpath_get_text(_tmp[0])
	      if _tmpb != nil
              _i = /(\d+)([ ]?)/i
              if _tmpb.match(_i)!=nil
                _tmpb = _tmpb.match(_i)[1]
 		logger.debug("Date: " + _tmpb.to_s)
                if _tmpb != nil && _rechash['date']==nil
		   _rechash['date'] = _tmpb 
    		else 
		   logger.debug("DATE: " + _rechash['date'])
	        end
              end
	      end
            end

	    _tmpfield = _xpath.xpath_all(_element, "subfield[@code='g']")
             if _tmpfield != nil
                _tmpb = _xpath.xpath_get_text(_tmpfield[0])
		if _tmpb != nil
		  _i = /(v[ol]*[\. ]*)(\d+[ ]?)([\(\[]?[A-Z0-9\-]*[\)\]]?)/i
          	  if _tmpb.match(_i)!=nil
            		_tmp = _tmpb.match(_i)[2]
            		if _tmp !=nil && _rechash['vol'] == nil: _rechash['vol'] = _tmp end
		        if _rechash['issue']==nil && _tmpb.match(_i)[3]!=nil
			   _rechash['issue'] = _tmpb.match(_i)[3]
			   if _rechash['issue'].slice(0,1).downcase=="n"
				_i = /(n[o]?[\.]?[ ]?)(.*)/i
				if (_rechash['issue'].match(_i)!=nil)
				   if _rechash['issue'].match(_i)[2]!=nil
					_rechash['issue'] = _rechash['issue'].match(_i)[2]
				   end 
				end 
			   end
			end	
          	   end

          	   _i = /(v[ol\. ]*)(\d+)/
          	   if _tmpb.match(_i)!=nil
            		_tmp = _tmpb.match(_i)[2]
            		 if _tmp !=nil && _rechash['vol']==nil: _rechash['vol'] = _tmp end
          	   end

		   _i = /(n[o]?)[\.]?[ ]?(\d+)/i
          	   if _tmpb.match(_i)!=nil
            		_tmp = _tmpb.match(_i)[2]
            		if _tmp !=nil && _rechash['issue']==nil : _rechash['issue'] = _tmp end
                   end

                _i = /(\d+)([ ]?\()/i
                if _tmpb.match(_i) != nil
                   _tmpb = _tmpb.match(_i)[1]
                   if _tmpb != nil && _rechash['vol'] == nil: _rechash['vol'] = _tmpb end
                end
		end 

                _i = /(\()(\d+)(\))/i
                _tmpb = _xpath.xpath_get_text(_tmpfield[0])
		if _tmpb != nil
                if _tmpb.match(_i) != nil
                  _tmpb = _tmpb.match(_i)[2]
                  if _tmpb != nil && _rechash['issue'] == nil: _rechash['issue'] = _tmpb end
                end
		end 

                _i = /(\)[, ]*)(\d+)/i
                _tmpb = _xpath.xpath_get_text(_tmpfield[0])
		if _tmpb != nil
                if _tmpb.match(_i) != nil
                  _tmpb = _tmpb.match(_i)[2]
                  if _tmpb != nil && _rechash['page'] == nil: _rechash['page'] = _tmpb end
                end
		end
              end
	    #_linktext << _element.content
  	    _tmp = _xpath.xpath_all(_element, "subfield")
	    _tmp.each {|_el| 
	      _tmpb = _xpath.xpath_get_text(_el)
	      logger.debug("TMPB: " + _tmpb.to_s)
	      if _tmpb != nil
	        _linktext << _tmpb + " "
	      end 
	    }
	    if _linktext == nil: _linktext = "" end
          }
          #================================
          # We now need to push the linking
          # text into a function to break
          # this information out and then
          # return a hash to fill in the
          # master hash data.
          #================================
          
	  _linktext = _linktext.downcase
          logger.debug("LINKTEXT: " + _linktext)
	  _rechash['raw_citation'] = _linktext
	  _i = /(v[ol]*[\. ]*)(\d+[ ]?)([\(\[]?[A-Z0-9\-]*[\)\]]?)/i
	  if _linktext.match(_i)!=nil
            _tmp = _linktext.match(_i)[2]
            if _tmp !=nil && _rechash['vol'] == nil
	       _rechash['vol'] = _tmp 
	       if _linktext.match(_i)[3] != nil
		_rechash['issue'] = _linktext.match(_i)[3].gsub("(", "").gsub(")", "")
 	        if _rechash['issue'].slice(0,1).downcase=="n"
                   _i = /(n[o]?[\.]?[ ]?)(.*)/i
                   if (_rechash['issue'].match(_i)!=nil)
                      if _rechash['issue'].match(_i)[2]!=nil
                         _rechash['issue'] = _rechash['issue'].match[_i][2]
                      end
                    end 
                end

	       end
	    end
          end

          _i = /(v[ol\. ]*)(\d+)/
          if _linktext.match(_i)!=nil
            _tmp = _linktext.match(_i)[2]
            if _tmp !=nil && _rechash['vol']==nil: _rechash['vol'] = _tmp end
          end

	  _i = /(n[o]?)[\.]?[ ]?(\d+)/i
          if _linktext.match(_i)!=nil
            _tmp = _linktext.match(_i)[2]
            if _tmp !=nil && _rechash['issue']==nil : _rechash['issue'] = _tmp end
	  end

          _i = /(\d+)/i
          if _linktext.match(_i)!=nil
            _tmp = _linktext.match(_i)[2]
            if _tmp != nil && _rechash['issue']==nil: _rechash['issue'] = _tmp end
	  end 

          _i = /(issue[\. ]*)(\d+)/i
          if _linktext.match(_i)!=nil
            _tmp = _linktext.match(_i)[2]
            if _tmp != nil && _rechash['issue']==nil: _rechash['issue'] = _tmp end
          end

          _i = /( p[g. ]*)(\d+)/i
          if _linktext.match(_i)!=nil
            _tmp = _linktext.match(_i)[2]
            if _tmp !=nil && _rechash['page']==nil: _rechash['page'] = _tmp end
	  end 
        rescue StandardError => bang
           logger.debug("Error: " + bang)	
        rescue
           logger.debug("Error in processing the data") 
        end

      elsif _tfield.to_i < 10
	begin
        _tmp = ''
        _length = '0'
        _start = '-1'
        if _tsubfield != nil
           if _tsubfield.index(":") !=nil
              _tmparr = Array.new
	      _tmparr = _tsubfield.split(":")
              _start = _tmparr[0]
              _length = _tmparr[1]
           else
	      _length = _tsubfield
           end
        end
        #_xml.find("//" + _prefix + "controlfield[@tag='" + _tfield + "']").each { |_element|
        _nodes = _xpath.xpath_all(_xml, "//" + _prefix + "controlfield[@tag='" + _tfield + "']")
        _nodes.each { |_element|
          _xpathtext = _xpath.xpath_get_text(_element)
	  logger.debug("Under 010 value: " + _xpathtext)
          if _start.to_i > -1 
            if _length.to_i > 0
              _tmp << _xpathtext.slice(_start.to_i, _length.to_i) + "; "
            else
	      _tmp << _xpathtext.slice(_start.to_i, _xpathtext.length - _start.to_i) + "; "
	    end
          else
            if _length.to_i > 0
              _tmp << _xpathtext.slice(0, _length.to_i) + "; "
            else
               _tmp << normalize(_xpathtext) + "; "
            end
          end  
	  logger.debug("TMP: " + _tmp)
        }
        if _tmp != ''
	  _rechash[_tlabel] << _tmp 
	  _tmp = ''
        end
	rescue StandardError => bang
           logger.debug("Error: " + bang)
	end
      else
	begin
        _tmp = ''
        if _tsubfield!=nil
          _length = '0' 
          _start = '-1'
          if _tsubfield.size > 1 
            _tmp = _tsubfield.slice(1, _tsubfield.length-1)
            if _tmp.index(":") != nil
               _tmparr = Array.new
               _tmparr = _tmp.split(":")
               _start = _tmparr[0]
               _length = _tmparr[1]
            else
               _length = _tmp
            end 
            _tmp = ''
            _tsubfield = _tsubfield.slice(0,1)
          end
          #_xml.find("//" + _prefix + "datafield[@tag='" + _tfield + "']/subfield[@code='" + _tsubfield + "']").each { |_element|

          _nodes = _xpath.xpath_all(_xml, "//" + _prefix + "datafield[@tag='" + _tfield + "']/subfield[@code='" + _tsubfield + "']")
          _nodes.each {|_element|
            _xpathtext = _xpath.xpath_get_text(_element)
            if _start.to_i > -1
               if _length.to_i > 0
                 _tmp << _xpathtext.slice(_start.to_i, _length.to_i) + "; "
 	       else
		 _tmp << _xpathtext.slice(_start.to_i, _xpathtext.length - _start.to_i) + "; "
               end
            else
              if _length.to_i > 0
	        _tmp << _xpathtext.slice(0, _length.to_i) + "; "
              else
                _tmp << normalize(_xpathtext)  + "; "
              end
            end
          }
          if _tmp != nil || _tmp != '' 
	    logger.debug("Setting data for: " + _tlabel)
	    _rechash[_tlabel] << _tmp 
            logger.debug("Value set: " + _rechash[_tlabel].to_s)
            _tmp = ''
	  end
        else
          #_xml.find("//" + _prefix + "datafield[@tag='" + _tfield + "']").each {|_element|
          _xpath.xpath_all(_xml, "//" + _prefix + "datafield[@tag='" + _tfield + "']").each {|_element|
            #_element.find("subfield").each { |_subfield| _tmp << _subfield.content + " " }
            _xpath.xpath_all(_element, "subfield").each {|_subfield| _tmp << _xpath.xpath_get_text(_subfield) + " " }
            if _tmp != '' 
	      _rechash[_tlabel] << _tmp.rstrip + "; " 
 	    end
            _tmp = ''
          }
        end
	rescue StandardError => bang
           logger.debug("Error: " + bang)
	end
      end
    }

    _rechash.each_key {|key|
       _rechash[key] = checknil(_rechash[key]).chomp('; ')
    }
    #=============================================
    #At this point, we should have the data 
    #extracted.
    #Here we handle special data (like subjects)
    #then normalize the data and place them into 
    #the class parameters
    #=============================================
    if normalize(_rechash['author'])!=""
      if _rechash['author']!=''
        _tmpl = _rechash['author'].split('; ')
        _rechash['author']= _tmpl[0];
        if _rechash['author'].index(',')!=nil
          _rechash['author'] = _rechash['author'].slice(0, _rechash['author'].index(","))
        end
      end
    end

    _openvals['issn']=normalize(_rechash['issn'])
    _openvals['isbn']=normalize(_rechash['isbn'])
    _openvals['title']=normalize(_rechash['title'])
    _openvals['atitle']=normalize(_rechash['atitle'])
    _openvals['aulast']=normalize(_rechash['author'])
    _openvals['volume'] = normalize(_rechash['vol'])
    _openvals['num'] = normalize(_rechash['num'])
    _openvals['issue'] = normalize(_rechash['issue'])
    _openvals['date'] = normalizeDate(_rechash['date'])
    if normalize(_rechash['doi'])!="" 
      _openvals['rft_id'] = "info:doi/" + checknil(_rechash['doi'])
    else
      _openvals['rft_id'] = ""
    end
    _openvals['spage'] = normalize(_rechash['page'])
    
    _rechash['date'] = normalizeDate(_rechash['date'])
    _rechash['ass_num'] = normalize(_rechash['ass_num'])
    _rechash['static'] = checknil(_rechash['static'])
    if _rechash['static'].index('; ') != nil
      _rechash['static'] = _rechash['static'].split('; ')[0].chomp('; ')
    end

 
    _openurl = "" 
    if defined? LIBRARYFIND_OPENURL 
      _openurl = buildopenlink(_openvals, ::LIBRARYFIND_OPENURL)
    end
    #_openurl = _openurl.gsub("%20", "+")
    _direct = ''
    if _openurl!='' 
       logger.debug('entering parsedirect')
      _direct =  ParseDirect(_openvals) #ParseDirect(buildopenlink(_openvals, ::LIBRARYFIND_OPENURL))
    else
      logger.debug('libraryfind_ill?')
      if defined? LIBRARYFIND_ILL
        logger.debug('Entering ILL')
        _openurl = BuildILL(_openvals,::LIBRARYFIND_ILL ) #this is for the citation link
        logger.debug('exiting ill')
        if _openurl.strip == '' || _openurl == nil
         _openurl = ::LIBRARYFIND_OPENURL
        end
      else 
        logger.debug('no ill');
  	_openurl = ""
      end
    end 
    _openvals.clear
    if defined? _rechash['static'] 
      _tindex = _rechash['static'].index('http')
      if _tindex!=nil 
        if _tindex>0 
          _rechash['static'] = _rechash['static'].slice(_tindex, _rechash['static'].size-_tindex)
        end
      end 
      #_rechash['static'] = procUrl(_rechash['static'])
      #if _direct=='' 
      #  _direct = normalize(_rechash['static']).strip
      #end 
      if LIBRARYFIND_USE_PROXY == true && _host['proxy']==1
	_host['vendor_url'] = GenerateProxy(normalize(_host['vendor_url']).strip)
      end

      if _rechash['static']!=""
          #logger.debug("Proxy info: " + _host['proxy'].to_s)
	  if LIBRARYFIND_USE_PROXY == true && _host['proxy']==1
            _direct = GenerateProxy(normalize(_rechash['static']).strip)
          else
	    _direct = normalize(_rechash['static']).strip
	  end
      end
    end 
    #if _rechash['ass_num']!=''
    #  if _direct=='' 
    #    _direct = normalize(_url.gsub(/\{ass_num\}/, normalize(_rechash['ass_num'])))
    #  end 
    #end 

    #Contributed by Noel Peden with modifications
    if _direct==''
     _url.split(/(\{.*?\})/).each do |_token|
        if _token[0] == 123 
           _token.sub!(/^\{(.*?)(\??)\}$/, '\1')
           if ($2 !='?' && (!_rechash[_token] || _rechash[_token] == '')) 
              _direct = ''
              break
           else
              _direct << (_rechash[_token]) ? _rechash[_token] : ''
           end
        else
           _direct << _token
        end
     end
    end
    if _rechash['atitle']==nil
      _ptitle=_rechash['title'] 
    else  
      _ptitle=_rechash['atitle'] 
    end

    _tmp = "" 
    if defined? LIBRARYFIND_SPECIAL_WEIGHT
       _tmp_list = LIBRARYFIND_SPECIAL_WEIGHT.split(";")
       _tmp_list.each do |el|
	  logger.debug("SPECIAL?")
          if _host['vendor_name'].index(el) != nil
	     logger.debug("SPECIAL RAN")
             _tmp = calc_rank({'special' => '1', 'title' => _rechash['title'],
                                        'atitle' => _rechash['atitle'],
                                        'creator' => _rechash['author'],
                                        'date' => _rechash['date'],
                                        'rec' => _recs,
                                        'pos' => 1}, @pkeyword)
	     break
	  end
       end
    else 
       _tmp = calc_rank({'title' => _rechash['title'],
                                        'atitle' => _rechash['atitle'],
                                        'creator' => _rechash['author'],
                                        'date' => _rechash['date'],
                                        'rec' => _recs,
                                        'pos' => 1}, @pkeyword) 
    end
   
    if _bool_obj == false
      _tmp = "<item rank = \"" + _tmp + "\">"
      _rechash.keys.each { |_x|
        _tmp << "<#{_x}>" + _rechash[_x] + "</#{_x}>\n"
      } 
      _tmp << "<mat_type>" + _host['mat_type'] + "</mat_type>\n"
      _tmp << "<url>"
      _tmp << "<openurl>" + _openurl + "</openurl>\n"
      _tmp << "<direct>" + _direct + "</direct>\n"
      _tmp << "<static>"  + _rechash['static'] + "</static>\n"
      _tmp << "<vendor>" + _host['vendor_url']  + "</vendor>\n"
      _tmp << "</url>"
      _tmp <<  "</item>\n"
      return _tmp 
    else
     
      _rechash['callnum'] = GetPrimaryCall(checknil(_rechash['callnum']))
 
      record = Record.new()
      record.rank = _tmp
      record.hits = _host['hits']
      record.vendor_name = _host['vendor_name']
      record.ptitle = _ptitle
      record.title = checknil(_rechash['title'])
      record.atitle = checknil(_rechash['atitle'])
      record.issn = checknil(_rechash['issn'])
      record.isbn = checknil(_rechash['isbn'])
      record.abstract = checknil(_rechash['abstract'])
      record.date = checknil(_rechash['date'])
      record.author = checknil(normalize(_rechash['author']))
      record.link = checknil(_rechash['link'])
      record.id = _host['search_id'].to_s + ";" + _host['collection_id'].to_s + ";" + (rand(1000000) + checknil(_rechash['ass_num']).to_i).to_s
      record.doi = checknil(_rechash['doi'])
      record.openurl = _openurl
      record.direct_url = _direct
      record.static_url = checknil(_rechash['static'])
      record.subject = checknil(normalize(_rechash['subject']))
      record.publisher = checknil(normalize(_rechash['publisher']))
      record.callnum = checknil(_rechash['callnum'])
      record.vendor_url = _host['vendor_url']
      record.material_type = _host['mat_type']
      record.volume = normalize(_rechash['vol'])
      record.issue = checknil(_rechash['issue'])
      record.page = checknil(_rechash['page'])
      record.number = checknil(_rechash['number'])
      record.start = _start_time.to_f
      record.end = Time.now().to_f
      record.raw_citation = checknil(_rechash['raw_citation'])
      record.oclc_num = checknil(_rechash['oclc_num'])
      return record
    end	
  end
  
  def sutrs2xml(_s)
    logger.debug('SUTRS RECORD: ' + _s)
    _header = '<record>' + #  xmlns="http://www.loc.gov/MARC21/slim">' +
  		  '<leader>01059naa a2200289Ia 4500</leader>' 
    _tarray = Array.new()
    _tarray = _s.split("\n")
    _rechash = Hash.new()
    
    for _x in 1..(_tarray.length-1)
      logger.debug('line: ' + _tarray[_x].downcase)
      case _tarray[_x].downcase
      when 'ti title:'
        _rechash['atitle'] = _tarray[_x+1]	
        _i = _x+2
	if (_tarray[_i] == nil):  break end
        until(_tarray[_i].slice(_tarray[_i].length-1, 1)==":")
          _rechash['atitle'] << " " + _tarray[_i].chomp("\r\n\t ")
          _i = _i+1 
	  if (_tarray[_i] == nil):  break end
        end	
        _x = _i-1
      when 'au author:'
        _rechash['author'] = _tarray[_x+1] 
        _i = _x+2
	if (_tarray[_i] == nil):  break end
        until(_tarray[_i].slice(_tarray[_i].length-1, 1)==":")
          _rechash['author'] << " " + _tarray[_i].chomp("\r\n\t ")
          _i = _i+1
	  if (_tarray[_i] == nil):  break end
        end     
        _x = _i-1
      when 'is issn:'
        _rechash['issn'] = _tarray[_x+1] 
        _i = _x+2
	if (_tarray[_i] == nil):  break end
        until(_tarray[_i].slice(_tarray[_i].length-1, 1)==":")
          _rechash['issn'] << " " + _tarray[_i].chomp("\r\n\t ")
          _i = _i+1
	  if (_tarray[_i] == nil):  break end
        end     
        _x = _i-1
      when 'do doi:'
        _rechash['doi'] = _tarray[_x+1] 
        _i = _x+2
	if (_tarray[_i] == nil):  break end
        until(_tarray[_i].slice(_tarray[_i].length-1, 1)==":")
          _rechash['doi'] << " " + _tarray[_i].chomp("\r\n\t ")
          _i = _i+1
	  if (_tarray[_i] == nil):  break end
        end     
        _x = _i-1
      when 'py publication year:'
        _rechash['date'] = _tarray[_x+1] 
        _i = _x+2
	if (_tarray[_i] == nil):  break end
        until(_tarray[_i].slice(_tarray[_i].length-1, 1)==":")
          _rechash['date'] << " " + _tarray[_i].chomp("\r\n\t ")
          _i = _i+1
	  if (_tarray[_i] == nil):  break end
        end     
        _x = _i-1
      when 'an accession number:'
        _rechash['ass_num'] = _tarray[_x+1] 
        _i = _x+2
	if (_tarray[_i] == nil):  break end
        until(_tarray[_i].slice(_tarray[_i].length-1, 1)==":")
          _rechash['ass_num'] << " " + _tarray[_i].chomp("\r\n\t ")
          _i = _i+1
	  if (_tarray[_i] == nil):  break end
        end     
        _x = _i-1
        
      when 'so source:'
        _rechash['source'] = _tarray[_x+1] 
        _i = _x+2
	if (_tarray[_i] == nil):  break end
        until(_tarray[_i].slice(_tarray[_i].length-1, 1)==":")
          _rechash['source'] << " " + _tarray[_i].chomp("\r\n\t ")
          _i = _i+1
	  if (_tarray[_i] == nil):  break end
        end     
        _x = _i-1
      end 
    end 
   
    #Print out the data in MARCXML
    _xml = _header + "\n"
    _rechash.each {|_key, _value|
      case _key
      when "atitle"
        _xml << '<datafield tag="245" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
      when "author"
        _xml << '<datafield tag="700" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
      when "issn"
        _xml << '<datafield tag="022" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
      when "doi"
        _xml << '<datafield tag="028" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '<subfield code="b">doi</subfield>'+
			   '</datafield>'
      when "date"
        _xml << '<datafield tag="260" ind1="0" ind2="0">'+
			   '<subfield code="c">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
      when "ass_num"
        _xml << '<controlfield tag="001">' + normalizeForXML(_value) + '</controlfield>'
      when "source"
        _xml << '<datafield tag="773" ind1="0" ind2="0">'+
			   '<subfield code="t">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
      else
      end
    }
    _xml << '</record>'
  
    logger.debug('SUTRS XML: ' + _xml) 
    return _xml 
  end
 
  def normalizeForXML(_s) 
    return _s
    _s = _s.gsub('&','&amp;')
    _s = _s.gsub('>','&gt;')
    _s = _s.gsub('<','&lt;')
    return _s
  end
 
  def GetPrimaryCall(_string) 
    return _string.split(";")[0]
  end
  
  def calc_rank(_rec, _keyword)
     objCalc = CalcRank.new
     return objCalc.calc_rank(_rec, _keyword)
  end
  
  
  def string_count(_haystack, _needle)
    _x = 1
    _pos = -1
    while _x==nil
      _x = _haystack.index(_x,_needle)
      if _x!=nil : _pos = _x end
    end
    return _pos
  end
  
  def is_stop(_s)
    return false
  end
  
  def strip_ex(_string, _pat, _rep)
    _string = _string.gsub(/\W+$/,_rep)
    _string = _string.gsub(/^\W+/,_rep)
    return _string
  end 
  
  def normalize(_string)
    return "" if _string == nil
    _string = _string.gsub(/^\s*/,"") 
    _string = _string.gsub(/\s*$/,"")
    #Remove trailing punctuation
    _string = _string.gsub(/[.,;:-]*$/,"")
    #Remove html data 
    _string = _string.gsub(/<(\/|\s)*[^>]*>/, "")
    #_string = strip_tags(_string)
    
    return _string
  end
 
  
  def normalizeDate(_string)
    return "" if _string == nil
    _string = _string.gsub(/[^0-9]/, "").chomp
    case _string.length
    when 8: 
      if _string.slice(4,2).to_i > 12: return _string.slice(0,4) end
      return _string.slice(0,4) + _string.slice(4,2) + _string.slice(6,2)
    when 6:  
      return _string.slice(0,4) + _string.slice(4,2) + "00"
    when 4: 
      return _string + "0000"
    else return ""
    end
  end
  
  def getLabel(_s)
    case _s.downcase
    when 'linking' : return 'link'
    when 'staticurl' : return 'static'
    when 'bn' : return 'isbn'
    when 'ti' : return 'title'
    when 'ati' : return 'atitle'
    when 'au' : return 'author'
    when 'an' : return 'ass_num'
    when 'note' : return 'abstract'
    when 'abs' : return 'abstract'
    when 'cnum' : return 'callnum'
    when 'pub' : return 'publisher'
    else return _s.downcase
    end
  end
  
  def buildopenlink(_val, _stem) 
    if _stem == "": return "" end
    if _stem.index('?')==nil: _stem + '?' end
    co = OpenURL::ContextObject.new
    if _val['rft_id']!='' 
      if _val['rft_id'].index("info:doi/")!=nil
        _tmphash = Hash.new
        _tmphash['rft_id'] = _val['rft_id']
        co = co.resolve_doi(::DOI_SERVLET.gsub("{@DOI}", URI.escape(_val['rft_id'].gsub("info:doi/", ""))), _val['atitle'])
        if co == nil
          co = OpenURL::ContextObject.new
          co.import_hash(_tmphash)
        end
        return _stem + co.kev
      else  
        return ""
      end
    elsif _val['date']=='' || (_val['issn']=='' && _val['isbn']=='')
      return '';
    else 
      if _val['aulast']!=''
        _tmpl = _val['aulast'].split('; ')
        _val['aulast']= _tmpl[0];
        if _val['aulast'].index(',')!=nil
          _val['aulast'] = _val['aulast'].slice(0, _val['aulast'].index(","))
        end 
      end 
      co.import_hash(_val)
      return _stem + co.kev
    end 
  end 
  
  def ParseDirect(_val)
    url = nil
    co = OpenURL::ContextObject.new 
    logger.debug('import hash')
    co.import_hash(_val)
    logger.debug('hash imported')
    begin
      case LIBRARYFIND_OPENURL_TYPE
      when LIBRARYFIND_LOCAL
	logger.debug("Using LOCAL")
        objProvider = Coverage.search_coverage(co) 
        if objProvider != nil
          url = Coverage.processURL(objProvider.url, co)
          if objProvider.proxy == "y"
            url = GenerateProxy(url)
          end
        else
          url=""
        end
      when LIBRARYFIND_SFX
	 logger.debug("Using SFX")
         url = Coverage.search_SFX(co) 
      when LIBRARYFIND_SS
	 logger.debug("Using SS")
	 url = Coverage.search_SS(co)
      when LIBRARYFIND_GD
	 logger.debug("Using GoldDust Link Resolver")
	 url = Coverage.search_GD(co)
      end
    rescue  => detail
	logger.debug("ERROR in PARSEDIRECT")
    end

    if url==nil
       return ""
    else
       return url
    end
  end 

  def BuildILL(_val,_stem)
    url = nil
    co = OpenURL::ContextObject.new
    co.import_hash(_val)
    return _stem + co.kev
  end


  def ParseDirectEx(_s) 
    return ""
    _tmp = ''
    if _s!=''
      begin
        #open(_s) do |_f|
        #  _tmp << _f.gets
        #end
	response = Net::HTTP.get_response(URI.parse(_s))
	return response.body
      rescue
	return "";
      end
    else 
      return "";
    end 
  end
  
  def checknil(_s) 
     return "" if _s == nil
     return _s.chomp()
  end

  def GenerateProxy(s) 
    objProxy = Proxy.new()
    url = objProxy.GenerateProxy(s)
    return url
  end


end
