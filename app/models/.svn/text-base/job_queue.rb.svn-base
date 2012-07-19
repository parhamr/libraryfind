# $Id: cached_search.rb 1020 2007-07-31 05:50:42Z reeset $

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

# Use to be cached_searches.  Moved to 
# accom. rails naming convention

class JobQueue < ActiveRecord::Base
  has_many :cached_record

  def self.check_status (id)
    begin
      objRecords = JobQueue.find(id)
      return nil if objRecords == nil
      return objRecords
    rescue
      return nil
    end
  end

  def self.update_job (id, rec_id, database_name = '', mystatus = 0, totalhits = 0, myerror = "")
    begin
      objRecord = JobQueue.find(id, :lock=>true)
      return nil if objRecord == nil
      objRecord.records_id = rec_id
      #objRecord.thread_id = thread_id
      objRecord.database_name = database_name
      objRecord.status = mystatus.to_i 
      objRecord.hits = totalhits.to_i
      objRecord.error = myerror
      objRecord.save
      return 1
    raise
      return nil
    end
  end

  def self.update_thread_id (id, thread_id) 
    begin
      objRecord = JobQueue.find(id, :lock=>true)
      return nil if objRecord == nil
      objRecord.thread_id = thread_id
      objRecord.save
      return 1
    raise
      return nil
    end
  end

  def self.create_job(rec_id = -1, thread_id = -1, database_name="nil", mystatus=1, myhits = 0, myerror="")
    objSearch = JobQueue.new("records_id" => rec_id, "thread_id" => thread_id,  "database_name" => database_name, "status" => mystatus, "hits" => myhits, "error" => myerror)
    objSearch.save
    return objSearch.id
  end

  def self.retrieve_metadata(id, max)
    begin
      objJob = JobQueue.find(id)
      objRecords = CachedRecord.find(objJob.records_id)
      return nil if objRecords == nil
      return objRecords
    rescue
      return nil
    end
  end 
end
