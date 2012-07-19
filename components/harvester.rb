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


RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)

require 'rubygems'
require 'yaml'

if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
require ENV['LIBRARYFIND_HOME'] + 'config/boot.rb'
require 'oai'
#require "mysql"
require 'active_record'
require 'oai_dc'
require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'


local_indexer = ""
if LIBRARYFIND_INDEXER.downcase == 'ferret'
   require 'ferret'
   include Ferret
   local_indexer = 'ferret'
elsif LIBRARYFIND_INDEXER.downcase == 'solr'
   require 'solr'
   local_indexer = 'solr'
end 

def checknil(s)
  if s == nil: return "" end
  return s
end

db = YAML::load_file(ENV['LIBRARYFIND_HOME'] + "config/database.yml")

if ARGV.length==0
  ARGV[0] = "development"
end

dbtype = ""
reharvest = false

for arg in ARGV
  puts arg
  if arg.downcase == 'development' || arg.downcase == 'production' || arg.downcase =='test'
     dbtype = arg
  else
     if arg.downcase == 'all' 
	reharvest = true
     end
  end
end
        
#dbtype  = ARGV[0]
if dbtype == "" 
  dbtype = "development"
end


case PARSER_TYPE
  when 'libxml'
    require 'xml/libxml'
  when 'rexml'
    require 'rexml/document'
  else
    require 'rexml/document'
end


if local_indexer == 'ferret'
 if reharvest == true
   puts "reharvest set to true"
   index = Index::Index.new(:path => LIBRARYFIND_FERRET_PATH, :create => true)
 else 
   index = Index::Index.new(:path => LIBRARYFIND_FERRET_PATH, :create_if_missing => true)
 end 
elsif local_indexer == 'solr'
   index = Solr::Connection.new(LIBRARYFIND_SOLR_HOST)
   if reharvest == true
	 puts Solr::Request::Delete.new(:query => 'id:[* TO *]').to_s
 	 request = index.send(Solr::Request::Delete.new(:query => 'id:[* TO *]'))
	 index.send(Solr::Request::Commit.new)
   end 
end

#index = Index::Index.new(:path => LIBRARYFIND_FERRET_PATH, :create => true)
isFound = false

puts "Indexer: " + local_indexer

if local_indexer == 'ferret'
   puts "FERRET INDEX: " + LIBRARYFIND_FERRET_PATH
elsif local_indexer == 'solr'
   puts "SOLR HOST: " + LIBRARYFIND_SOLR_HOST
end 

puts "DATABASE INFO: " + db[dbtype]["database"]
#dbh = Mysql.real_connect(db[dbtype]["host"], db[dbtype]["username"], db[dbtype]["password"], db[dbtype]["database"])

if defined? db[dbtype]["port"]
   ActiveRecord::Base.establish_connection(
        :adapter => db[dbtype]["adapter"],
        :host => db[dbtype]["host"],
        :username => db[dbtype]["username"],
        :password => db[dbtype]["password"],
        :database => db[dbtype]["database"]
  )
else
     ActiveRecord::Base.establish_connection(
        :adapter => db[dbtype]["adapter"],
        :host => db[dbtype]["host"],
        :username => db[dbtype]["username"],
        :password => db[dbtype]["password"],
        :database => db[dbtype]["database"],
	:port => db[dbtype]["port"]
  )
end


class Control < ActiveRecord::Base
end

class Collection < ActiveRecord::Base
end

class Metadata < ActiveRecord::Base
end

if reharvest == true
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE controls;")
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE metadatas;")
  #dbh.query("TRUNCATE TABLE controls")
  #dbh.commit
  #dbh.query("TRUNCATE TABLE metadatas")
  #dbh.commit
  end

query = "Select * FROM collections where conn_type = 'oai' order by host DESC, is_parent DESC"
results = Collection.find_by_sql(query) #dbh.query(query);
query = "";

old_host = nil
old_parent = 0

results.each { |row|

 if old_host != nil
    if old_host == row.host && old_parent == 1
       puts "Already harvested collection: " + row.name + "...skipping\n\n"
       now = DateTime::now()
       Collection.update(row.id, { :harvested => now.year.to_s + "-" + now.month.to_s + "-" + now.day.to_s })

       next
    elsif old_host != row.host 
       old_host = ""
    else
       old_host = nil
    end
 end  
    
 resumption_token=nil
 begin 
  puts row.host + "\n"
  puts row.name + "\n\n" 
  puts row.is_parent.to_s + "\n\n"
  #if reharvest == true
  #   dbh.query("delete from controls where collection_id = '" + row['id'] + "'")
  #   dbh.commit
  #   dbh.query("delete from metadatas where collection_id = '" + row['id'] + "'")
  #   dbh.commit
  #end 

  begin
    tmphost = row.host.gsub(":", "_")
    client = OAI::Client.new row.host, :parser =>PARSER_TYPE
    opts = Hash.new()
    if resumption_token == nil
      begin
        if row.is_parent != 1
          opts["set"] = row.name
        end

        opts["metadata_prefix"] = row.record_schema
 
        if reharvest == false && row.harvested != nil && row.harvested != ''
           t = DateTime.now
	   if row.harvested == t.year.to_s + "-" + t.month.to_s + "-" + t.day.to_s
	      puts "Already have harvested today...skipping"
	      next
	   end 

           puts "harvested data: " + row.harvested
           parts = row.harvested.split("-")
	   if parts[1].length < 2
   		parts[1] = "0" + parts[1]
	   end

	   if parts[2].length < 2
  	        parts[2] = "0" + parts[2]
	   end
	   
           opts["from"] = parts[0] + "-"  + parts[1] + "-"  + parts[2] #row.harvested
        end
        records = client.list_records opts
      rescue Net::ProtocolError
	#Timeout
        puts row.host + " has timed out\n"
	next
      rescue Errno::ETIMEDOUT
	#Internal timeout
        puts row.host + " has timed out\n"
	next
      rescue Exception => e
        if defined?(e.code)
          if e.code == 'noRecordsMatch'
	    #For harvesting materials using a from, if there are no 
	    #records, we get this error code. 
	    next
          else
            #no set
            puts 'Dropped into rescue mode'
            puts "\n\n\n\n"
            puts "Name: " + row.host
         
            opts["metadata_prefix"] = row.record_schema

            if reharvest == false && row.harvested != nil && row.harvested != ''
	      puts 'last harvest: ' + row.harvested
	      parts = row.harvested.split("-")
              if parts[1].length < 2
                parts[1] = "0" + parts[1]
              end

              if parts[2].length < 2
                parts[2] = "0" + parts[2]
              end

              opts["from"] = parts[0] + "-" + parts[1] + "-" + parts[2] #row.harvested

              #opts["from"] = row.harvested
            end
 
            records = client.list_records opts
           end
        else
	  #Something else has happened -- dump the request
          puts "Error encountered:  "  + e.to_s
          next
        end
      end
    else
      puts "Resumption Token for data: " + resumption_token
      begin
        records = client.list_records :resumption_token => resumption_token
      rescue Net::ProtocolError
        #traps for timeout
        #try one more time
	#begin
        #  records = client.list_records :resumption_token => resumption_token
        #rescue Net::ProtocolError
        puts row.host + " resumption token: " + resumption_token + " has timed out. Exception: Net::ProtocolError"
        resumption_token = nil
        next
      rescue Errno::ETIMEDOUT
        #Internal Error
        puts row.host + " resumption token: " + resumption_token + " has timed out.  Exception:  Errno::ETIMEDOUT"
        resumption_token  = nil
        next
      rescue Net::HTTPInternalServerError
	puts row.host + " resumption token: " + resumption_token + " has thrown an processing error. Exception: NET::HTTPInternalServerError"
	resumption_token  = nil
        next
      rescue
	puts row.host + " unknown error...skipping rest of harvest for this site."
        resumption_token = nil
        next
      end
    end

    resumption_token = records.resumption_token
    if resumption_token == '': resumption_token = nil end
    #begin
      x = 0
      oaidc = OaiDc.new()
      for record in records
        set_spec = record.header.set_spec.to_s
        set_spec = set_spec.gsub(/<\/?[^>]*>/, "")
        oaidc.parse_metadata(record)
        if oaidc.title != nil
          prim_title = checknil(oaidc.title[0])
        else
          prim_title = "untitled"
        end
        oai_identifier = record.header.identifier
        collection_id = row.id
        if oaidc.description !=nil
          prim_description = checknil(oaidc.description[0])
        else
          prim_description = ""
        end
        if oaidc.identifier!=nil
          #no identifier -- no record
	  if oaidc.identifier[oaidc.identifier.size-1] == nil
	    next
	  else 
            url = oaidc.identifier[oaidc.identifier.size-1]
          end
        else
          url = ""
        end

        isFound = false
        db_record =  Control.find(:all, :conditions => "oai_identifier = '#{oai_identifier}'")
        if db_record.empty? == true
	  _control = Control.new(
	   :oai_identifier => oai_identifier, 
	   :title => prim_title, 
	   :collection_id => collection_id, 
	   :description => prim_description, 
	   :url => url, 
	   :collection_name => tmphost  + set_spec
           )
	   _control.save!()

 	   db_record = Control.find(:all, {:order => "id DESC", :limit => 1})
        else
	   puts "found -- oai-identifier: " + oai_identifier           
	   isFound = true
        end
        last_id = db_record[0].id
        #======================================
        #set harvested values
        #====================================== 
        dctitle = ""
        dccreator = ""
        dcsubject = ""
        dcdescription = ""
        dcpublisher = ""
        dccontributor = ""
        dcdate = "" 
        dctype = "" 
        dcformat = ""
        dcidentifier = ""
        dcsource = ""
        dcrelation = "" 
        dccoverage = ""
        dcrights = ""
        dcthumbnail = ""
        keyword = ""

        if oaidc.title != nil: dctitle = oaidc.title.join("; ").gsub('; ;',';') end
        if oaidc.creator != nil: dccreator = oaidc.creator.join("; ").gsub('; ;',';') end
        if oaidc.creator!=nil
          oaidc.creator.each {|_tmp|
            if _tmp != nil
              if _tmp.index(',')!=nil
               _tmpa = _tmp.split(',')
               if _tmpa.length >= 2
                 dccreator << _tmpa[1] + ' ' + _tmpa[0] + '; '
               end
              end
            end
           }
        end
        if oaidc.subject != nil: dcsubject = oaidc.subject.join("; ").gsub('; ;',';') end
        if oaidc.description != nil: dcdescription = oaidc.description.join("; ").gsub('; ;',';') end
        if oaidc.publisher != nil: dcpublisher = oaidc.publisher.join("; ").gsub('; ;',';') end
        if oaidc.contributor != nil: dccontributor = oaidc.contributor.join("; ").gsub('; ;',';') end
        if oaidc.date != nil: dcdate = oaidc.date.join("; ").gsub('; ;',';') end
        if oaidc.type != nil: dctype = oaidc.type.join("; ").gsub('; ;',';') end
        if oaidc.format != nil: dcformat = oaidc.format.join("; ").gsub('; ;',';') end
        if oaidc.identifier != nil: dcidentifier = oaidc.identifier.join("; ").gsub('; ;',';') end
        if oaidc.source != nil: dcsource = oaidc.source.join("; ").gsub('; ;',';') end
        if oaidc.relation != nil: dcrelation = oaidc.relation.join("; ").gsub('; ;',';') end
        if oaidc.coverage != nil: dccoverage = oaidc.coverage.join("; ").gsub('; ;',';') end
        if oaidc.rights != nil: dcrights = oaidc.rights.join("; ").gsub('; ;',';') end
        keyword = dctitle + " " + dccreator + " " + dcsubject + " " + dcdescription + " " + dcpublisher + " " + dccontributor + " " + dccoverage + " " + dcrelation
	if oaidc.thumbnail != nil: dcthumbnail = oaidc.thumbnail.join("") end
        
        #========================================================================
        # If thumbnail is blank and the item is set an an image, then we 
        # assume that its a CONTENTdm resource (for now) and build a link to the
        # CDM image.
        #========================================================================
        if row['mat_type'].downcase == 'image' && dcthumbnail == ''
	   #build the CDM image location
	   thumbstem = url.split('u?')[0]
           thumbargs = url.split('u?/')[1]
           if thumbargs!=nil and thumbargs!=''
              thumbarg_parts = thumbargs.split(',')
              dcthumbnail = thumbstem + 'cgi-bin/thumbnail.exe?CISOROOT=/' + thumbarg_parts[0] +'&CISOPTR=' + thumbarg_parts[1]
	   end
 	end

	if isFound == true
           db_record = Metadata.find(:all, :conditions => "controls_id = #{last_id}")
           Metadata.update(db_record[0].id, { :collection_id => row.id, :dc_title => dctitle, 
					      :dc_creator => dccreator, :dc_subject => dcsubject, 
					      :dc_description => dcdescription, :dc_publisher => dcpublisher, 
					      :dc_contributor => dccontributor, :dc_date => dcdate, 
					      :dc_type => dctype, :dc_format => dcformat, 
					      :dc_identifier => dcidentifier, :dc_source => dcsource,
					      :dc_relation => dcrelation, :dc_coverage => dccoverage, 
					      :dc_rights => dcrights, :osu_thumbnail => dcthumbnail})
	else
          _metadata = Metadata.new(
	    :collection_id => row.id, 
	    :controls_id => last_id.to_s, 
	    :dc_title => dctitle, 
	    :dc_creator => dccreator, 
	    :dc_subject => dcsubject,
	    :dc_description => dcdescription, 
	    :dc_publisher => dcpublisher, 
	    :dc_contributor => dccontributor, 
	    :dc_date => dcdate, 
	    :dc_type => dctype, 
	    :dc_format => dcformat, 
	    :dc_identifier => dcidentifier, 
	    :dc_source => dcsource, 
	    :dc_relation => dcrelation, 
	    :dc_coverage => dccoverage, 
	    :dc_rights => dcrights, 
	    :osu_thumbnail => dcthumbnail
	  )
	  _metadata.save!()
          db_record = Metadata.find(:all, {:order => "id DESC", :limit => 1})
  	end
        main_id = db_record[0].id
	#results2 = dbh.query(query)
        #main_id = dbh.insert_id()


        if local_indexer == 'ferret'
         if isFound == true
           doc = index[main_id.to_s]
	   doc[:collection_id] = row['id']
           doc[:collection_name] = tmphost + set_spec
           doc[:controls_id] = last_id
           doc[:title] = dctitle
           doc[:subject] = dcsubject
           doc[:author] = dccreator + " " + dccontributor
	   doc[:keyword] = keyword
           index << doc
         else  
           index << {:id => main_id, :collection_id => row['id'], :collection_name => tmphost + set_spec, :controls_id => last_id, :title => dctitle, :subject => dcsubject, :author => dccreator + " " + dccontributor, :keyword => keyword}
	 end
	elsif local_indexer == 'solr'
          if isFound == true
	     index.update(:id=>main_id, 
			  :collection_id => row['id'],
			  :collection_name => tmphost + set_spec,
			  :controls_id => last_id,
			  :title => dctitle,
			  :subject => dcsubject,
			  :author => dccreator + " " + dccontributor,
			  :keyword => keyword)
          else
	     index.add(:id => main_id, :collection_id => row['id'], :collection_name => tmphost + set_spec, :controls_id => last_id, :title => dctitle, :subject => dcsubject, :author => dccreator + " " + dccontributor, :keyword => keyword)
	  end
        end

        #===============================================================
        # index into ferret
        #============================================================== 
        #puts "Titles: " + oaidc.title.join("; ").gsub('; ;',';') + "\n"
        #puts "Subjects: " + oaidc.subject.join("; ").gsub('; ;',';') + "\n\n"
        x += 1
      end
     #rescue
     #  puts row['host'] + " unable to be processed"
     #end
   end until resumption_token == nil 
 rescue OAI::Exception
  puts row.host + " unable to be processed"
 rescue Timeout::Error
  puts row.host + " timed out."
 end
 now = DateTime::now()
 Collection.update(row.id, { :harvested => now.year.to_s + "-" + now.month.to_s + "-" + now.day.to_s })
 #dbh.query("update collections set harvested = '" + now.year.to_s + "-" + now.month.to_s + "-" + now.day.to_s + "' where id = '" + row['id'] + "'")

 if row.is_parent.to_s == '1'
   puts "is parent set"
   old_host = row.host
   old_parent = 1 
 elsif old_host == row.host && old_parent == 1
   old_host = row.host
   old_parent = 1
 else
   old_host = row.host
   old_parent = 0
 end 

 if LIBRARYFIND_INDEXER.downcase == 'solr'
    index.send(Solr::Request::Commit.new)
 end
 #dbh.commit
}
#close the ferret indexes

if LIBRARYFIND_INDEXER.downcase == 'ferret'
  index.close()
end

# If you're files are not created so that they are readable -- you will 
# need to change that here.
#system('chmod -R 777 ' + LIBRARYFIND_FERRET_PATH);
print "Finished processing\n"

