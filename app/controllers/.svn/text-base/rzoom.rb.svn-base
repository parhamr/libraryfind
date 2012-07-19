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


class RZOOM   < ActionController::Base
  require 'zoom'
  require 'timeout'

  @debug = false
  attr_reader :hits
  def search(_host, _stype, _keyword, _start=1, _max=10) 
    is_connected = false
    _qstring = "";
    _isword_title = ""
    _records = Array.new
    if _max.class!="Int": _max = _max.to_i end
    begin 
    hOptions = Hash.new
    if (_host['username']!="")
      logger.debug("USERNAME WAS SET")
      hOptions['user'] = _host['username']
    end

    if (_host['password']!='')
       logger.debug("PASSWORD WAS SET")
       hOptions['password'] = _host['password']
    end 
    conn = ZOOM::Connection.new(hOptions) 
    if conn != nil
    #ZOOM::Connection.open(_host['host'], _host['port']) do |conn|
       is_connected=true
       #if (_host['username']!="") 
       #  conn.set_option('username',_host['username'])
       #end

       #if (_host['password']!="")
       #  conn.set_option('password',_host['password'])
       #end 

       conn = conn.connect(_host['host'], _host['port'])
       conn.set_option('timeout', LIBRARYFIND_PROCESS_TIMEOUT)
       logger.debug(LIBRARYFIND_PROCESS_TIMEOUT)
       conn.database_name = _host['name'] 
       conn.preferred_record_syntax = _host['syntax']

       logger.debug("Username: " + _host['username'])
       logger.debug("Password: " + _host['password'])
       logger.debug("Database Name: " + _host['name'])
       logger.debug("Host: " + _host['host']) 
       logger.debug("Port: " + _host['port'].to_s)
       logger.debug("Syntax: " + _host['syntax'])
       _querystring = ""
   
       _keyword = normalize(_keyword.downcase) 

       case _stype.downcase
	  when "title" : _qstring = '@attr 1=4'
	  when "creator" : _qstring = '@attr 1=1003'
	  when "author" : _qstring = '@attr 1=1003'
	  when "subject" : _qstring = '@attr 1=21'
	  when "issn" : _qstring = '@attr 1=8'
	  when "isbn" : _qstring = '@attr 1=7'
	  when "callnum" : _qstring = '@attr 1=16'
	  else 
            if _host['isword'].to_i > 0
	      _isword_title = '@or @attr 1=4 "' + _keyword + '"'
	    end 
            _qstring = '@attr 1=1016'
       end


         #================
         if _keyword.index(' and ') == nil && _keyword.index(' or ') == nil
           _querystring = _qstring + " " + "\"" + _keyword + "\""
         else
           #==================
           # We break this up
           #==================

           #==========================
           # for now, we ignore the
           # grouping elements
           #==========================
           _keyword.gsub(/\(\)/,"")
           _prefix = ""
           _index = 1;
           if _keyword.index(" or ") != nil && _keyword.index(" and ")!=nil
              _tmpand = _keyword.split(" and ")
              _tmpand.each do |_t|
                 if _index <=  _tmpand.length-1
                   _prefix <<  "@and "
                 end
                 if _t.index(" or ")!=nil
                    _tmpor = _t.split(" or ")
                    for num in (1.._tmpor.length-1)
                       _prefix << "@or "
                    end
                    _tmpor.each do |_z|
                        if _z.slice(0,1) == "'" && _z.slice(_z.length-1, 1) != "'"
                           _z = _z.slice(1,_z.length-1)
                        elsif _z.slice(0,1) != "'" && _z.slice(_z.length-1, 1) == "'"
                           _z = _z.slice(0, _z.length-1)
                        end
                       _querystring << _qstring + " \"" + _z + "\" "
                    end
                 else
                    _querystring << _qstring + " \"" + _t + "\" "
                 end
                _index = _index + 1
              end
           elsif _keyword.index(" or ")!=nil
               _tmpor = _keyword.split(" or ")
               for num in (1.._tmpor.length-1)
                 _prefix << "@or "
               end
               _tmpor.each do |_t|
                 if _t.slice(0,1) == "'" && _t.slice(_z.length-1, 1) != "'"
                    _t = _t.slice(1,_t.length-1)
                 elsif _t.slice(0,1) != "'" && _t.slice(_t.length-1, 1) == "'"
                    _t = _t.slice(0, _t.length-1)
                 end
                 _querystring << _qstring + " \"" + _t + "\" "
               end
           elsif _keyword.index(" and ")!=nil
               _tmpand = _keyword.split(" and ")
               for num in (1.._tmpand.length-1)
                 _prefix << "@and "
               end
               _tmpand.each do |_t|
                 if _t.slice(0,1) == "'" && _t.slice(_z.length-1, 1) != "'"
                    _t = _t.slice(1,_t.length-1)
                 elsif _t.slice(0,1) != "'" && _t.slice(_t.length-1, 1) == "'"
                    _t = _t.slice(0, _t.length-1)
                 end
                 _querystring << _qstring + " \"" + _t + "\" "
               end
           else
             _querystring = _qstring + " \"" + _keyword + "\""
           end
             _querystring = _prefix + _querystring
         end



       if _host['bib_attr']!=nil 
         if  _host['bib_attr'].index(':') == nil
           _querystring = _host['bib_attr'] + " " + _querystring 
         else
	   local_attr = _host['bib_attr'].split(':')
	   _querystring = local_attr[0] +  " " + _querystring
	 _host['bib_attr'] = local_attr[1]
         end
       end

       if _host['isword'].to_i > 0 && (_querystring.index('@and')==nil && _querystring.index('@or')==nil)
         _querystring = _isword_title + " " + _querystring.to_s
       end 
       logger.debug("Z39.50 QueryString: " + _querystring.to_s)	
       rset = ZOOM::ResultSet
       rset = conn.search(_querystring.to_s)
       logger.debug("Results set size: " + rset.size.to_s)
       if  _host['isword'].to_i > 0
         if rset.size == 0 
           if _querystring.index("@attr 1=4")!=nil && _querystring.index("@attr 1=1016")!=nil
             logger.debug("new search: " + _querystring.slice(_querystring.index("@attr 1=1016"), (_querystring.length-_querystring.index("@attr 1=1016"))))
             rset = conn.search(_querystring.slice(_querystring.index("@attr 1=1016"), (_querystring.length-_querystring.index("@attr 1=1016"))))
           end
         end
       end
       @hits = rset.size
         
       logger.debug("Raw Hits: " + rset.size.to_s)
       if rset.size >=_max+1
	  _hits = _max+1
       else 
	  _hits = rset.length
       end

       logger.debug("Z39.50 Hits: " + _hits.to_s)
       rset.set_option('timeout', LIBRARYFIND_PROCESS_TIMEOUT)
       begin
          status = Timeout::timeout(LIBRARYFIND_PROCESS_TIMEOUT) {
	     if _host['bib_attr']!=nil && _host['bib_attr'].index('@')==nil
	 	rset.set_option('elementSetName', _host['bib_attr'])
	     end
   	     if _start < 1: start = 1 end
             _records = rset[(_start-1).._hits]
          }
       rescue Timeout::Error
         logger.debug("Timeout error")
          return nil
       rescue 
         logger.debug("other error")
         return nil
       end
    end
    if is_connected==false
       logger.debug('Not Connected')
       return nil
    else
      return _records
    end
    rescue StandardError => bang
       logger.debug("Error: " + bang)
       return nil
    rescue 
      logger.debug("Raise Error")
      return nil #_records
    end
   end

   def normalize(_string)
      return "" if _string == nil
      if _string.class!="String": _string = _string.to_s end
      _string = _string.gsub(/&/,'and')
      #_string = _string.gsub(/'/,'')
      _string = _string.gsub('"',"'")
      #_string = '"' + _string + '"'
      return _string
   end


   
end

