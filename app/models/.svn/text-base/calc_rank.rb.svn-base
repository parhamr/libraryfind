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

class CalcRank
   def calc_rank(_rec, _keyword)
    _trank = 0
    _keyword = strip_ex(_keyword, "/^\W+$/",'')
    _keyword = _keyword.strip.downcase
    _t = Array.new()
    _lsubject = ""

    if _rec['subject'] != nil
      _lsubject = _rec['subject'].downcase
    end


    if _rec['special'] != nil
      _trank = _trank + 100 
    end

    _trank = _trank + (30-_rec['pos'].to_i)
    if _trank < 0
      _trank = 0
    end

    if _rec['atitle'] != nil
        if _rec['atitle']!=""
          _rec['title'] = _rec['atitle']
        end
    end

    _rec['title'] = strip_ex(_rec['title'],'/\W+$/','').downcase
    if _rec['title']!=nil
      if _keyword == _rec['title']
        _trank = _trank + 5000
      elsif _rec['title'].index(_keyword) != nil and _rec['title'].index(_keyword) < 5 
	 _trank = _trank + 2000
      end
    end

    if _rec['creator']!=nil
      if _keyword == _rec['creator'].downcase
        _trank = _trank + 5000
      elsif _rec['creator'].downcase.index(_keyword) != nil
	_trank = _trank + 1000
      end
    else
    	_trank = _trank - 20
    end

    if _lsubject == _keyword
      _trank = _trank + 5000
    end

    if _lsubject == ""
      _trank = _trank - 10
    end

    _t = _keyword.split(' ')
    _last = _t.length-1

    _z = _lsubject.index(_keyword)
    if _z != nil
       if _z <= 1
         _trank = _trank + 300
       else
         _trank = _trank + 75
       end
    else
      for _x in 0.._last
        _t[_x] = strip_ex(_t[_x], "/\W+$/",'')
        if _t[_x].strip.size>0
          if is_stop(_t[_x])!=true
            if _lsubject.downcase.index(_t[_x])
              if _x==0 : _trank = _trank + 25
              else _trank = _trank + 20
              end
            end
          end
        end
      end
    end

    if _rec['creator']!=nil
      _z = _rec['creator'].downcase.index(_keyword)
      if _z != nil
         if _z <=1
            _trank = _trank + 300
         else
            _trank = _trank + 75
         end
      else
        for _x in 0.._last
          _t[_x] = strip_ex(_t[_x], "/\W+$/",'')
          if _t[_x].strip.size>0
            if is_stop(_t[_x])!=true
              if _rec['creator'].downcase.index(_t[_x])
                if _x==0 : _trank = _trank + 25
                else _trank = _trank + 20
                end
              end
            end
          end
        end
      end
    end

    if _rec['title']!=nil
      _z = _rec['title'].index(_keyword)
      if _z != nil
        if _z <= 1
          _trank = _trank + 500
        else
          _trank = _trank + 300
        end
      end
    end

    if _rec['rec']!=nil
      if _rec['rec'].downcase.index(_keyword)
         _trank = _trank + (25 * string_count(_rec['rec'], _keyword))
      end
    end

    for _x in 0.._last
      _t[_x] = strip_ex(_t[_x],  "/\W+$/",'' )
      if _t[_x].strip.size>0
        if is_stop(_t[_x])!=true
          if _rec['title']!=nil
            if _rec['title'].index(_t[_x])
              if _x==0  : _trank = _trank + 50
              else  _trank = _trank + 25
              end
            end
          end
          if _rec['rec']!=nil
            _trank = _trank + (0.25 * string_count(_rec['rec'], _t[_x]))
          end
        end
      end
    end

    if defined?(_rec['pref'])
      if _rec['pref'] != nil
        #_rec['url'] = _rec['url'].gsub(".", "\.")
        #_rec['url'] = _rec['url'].gsub("/", "\/")
        #if _rec['url'].index(/#{_rec['pref']}/) != nil
        if _rec['url'].index(_rec['pref']) != nil
	   _trank = _trank + 50000
        end
      end
    end
    return _trank.to_s
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
    if _string == nil: return "" end
    _string = _string.gsub(/\W+$/,_rep)
    _string = _string.gsub(/^\W+/,_rep)
    return _string
  end
end
  

