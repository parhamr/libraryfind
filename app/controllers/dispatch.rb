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

class Dispatch  < ApplicationController
  
  def driver
    logger.debug("LibraryFind: " + ::LIBRARYFIND_WSDL.to_s)
    
    case LIBRARYFIND_WSDL
    when LIBRARYFIND_WSDL_ENGINE
      require 'soap/wsdlDriver'
      driver = SOAP::WSDLDriverFactory.new(LIBRARYFIND_WSDL_HOST).create_rpc_driver
      return driver
    else
      return MetaSearch.new()
    end
  end
  

  def SimpleSearch(ssets, qtype, sarg, sstart, smax) 
     objdriver = driver;
     objdriver.send :SimpleSearch, ssets, qtype, sarg, sstart, smax
  end 

  def SimpleSearchAsync(ssets, qtype, sarg, sstart, smax)
     objdriver = driver;
     objdriver.send :SimpleSearchAsync, ssets, qtype, sarg, sstart, smax
  end


  def SearchAsync(_sets, _qtype, _arg, _start, _max, _session_id=nil, _action_type=1, _data=nil, obj_bool=true)
    objdriver = driver
    case objdriver.class.to_s
        when "SOAP::RPC::Driver"
	   if _session_id == nil
	      objdriver.send :SearchAsync,  _sets, _qtype, _arg, _start, _max
	   else
	      objdriver.send :SearchAsync, _sets, _qtype, _arg, _start, _max, _session_id, _action_type, _data, obj_bool
	   end
	else
	   objdriver.send :SearchAsync, _sets, _qtype, _arg, _start, _max, _session_id, _action_type, _data, obj_bool
       end
  end

  def Search (_sets, _qtype, _arg, _start, _max, _session_id=nil, _action_type=nil, _data=nil, obj_bool=true)
    objdriver = driver;
    case objdriver.class.to_s
	when "SOAP::RPC::Driver"
	     if _session_id==nil 
	        objdriver.send :Search, _sets, _qtype, _arg, _start, _max
	     else
                objdriver.send :SearchEx, _sets, _qtype, _arg, _start, _max, _session_id, _action_type, _data, obj_bool
             end
        else
          objdriver.send :Search, _sets, _qtype, _arg, _start, _max, _session_id, _action_type, _data, obj_bool
    end
  end  

  def ListCollections()
    objdriver = driver
    objdriver.send :ListCollections
  end

  def ListGroups()
    objdriver = driver
    objdriver.send :ListGroups
  end  

  def GetGroupMembers(name)
    objdriver = driver
    objdriver.send :GetGroupMembers, name
  end

  def GetId(sid) 
     objdriver = driver
     objdriver.send :GetId, sid
  end 
 
  def TestCollection(sid)
     objdriver = driver
     objdriver.send :TestCollection, sid
  end

  def CheckJobStatus(sids)
     objdriver = driver
     objdriver.send :CheckJobStatus, sids
  end

  def CheckJobsStatus(sids)
     objdriver = driver
     objdriver.send :CheckJobStatus, sids
  end

  def GetJobRecord(jid, _max)
     objdriver = driver
     objdriver.send :GetJobRecord, jid, _max
  end
 
  def GetJobsRecords(jids, _max)
     objdriver = driver
     objdriver.send :GetJobsRecords, jids, _max
  end
 
  def KillThread(jobid, threadid)
    objdriver = driver
    objdriver.send :KillThread, jobid, threadid
  end
end

