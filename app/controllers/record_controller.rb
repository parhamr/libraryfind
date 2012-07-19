# $Id: record_controller.rb 1306 2009-05-02 07:22:30Z reeset $

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

class RecordController < ApplicationController
  require_dependency 'user' 
  include ApplicationHelper
  layout "libraryfind", :except => [:spell_check,:advanced_search, :feed]
  
def index
  render(:action => 'search')
end

def search
  @client_ip = request.env["HTTP_CLIENT_IP"]
  @client_host = request.env["HOST"]
  @client_url = request.url
  @IsMobile = false
  if params[:mobile] != nil and  params[:mobile] == 'true'
     @IsMobile = true;
  end 
  setDefaults
  render(:action=>'search')
end

def advanced_search
  setDefaults
  render(:action=>'advanced_search')
end
  
def retrieve
  if params[:start_search]!="false" 
    if params[:query]!=nil 
        setDefaults
        initQueryAndType(params)
        if @query[0]!=nil and @query[0].to_s.strip!=""
          init_search  
          logger.debug("searching for query: " + @query.to_s + " and type: " + @type.to_s)
          if @IsMobile == true and request.user_agent.downcase.index('opera mini') != nil
	     dep_find_search_results
             render(:action => @tab_template)
          else
            @jobs = $objDispatch.SearchAsync(@sets, @type, @query, @start, @max) 
            render(:action => 'intermediate')
          end
        else
          render(:action=>"search")
       end
    else
      render(:action=>"search")
    end 
  else
    setDefaults
    if params[:query]!=nil
      initQueryAndType(params)
    else
      @query=['']
    end
    if params[:sets]!=nil && params[:sets]!=''
      @sets=params[:sets]
    else
      @sets=getSelectedSets
      if @sets==nil || @sets.empty?
        init_sets
      end
    end
    if @sets.rindex(',')==@sets.length-1
      @sets=@sets.chop
    end
    render(:action=>"search")   
  end
end 

#this method is used during pagination/filtering/sorting to keep user with the same results.  For example,
#if a user is paging through results that have been sorted, this method will forward to those
#sorted results.
def retrieve_page
  setDefaults
  set_query_values
  init_search
  find_search_results
  render(:action => @tab_template)
end

def dep_find_search_results(_type=@type, _query=@query, _sets=@sets, _start=@start, _max=@max)  
  logger.debug("searching for type="+_type.to_s+" query="+_query.to_s+" sets="+_sets.to_s+" start="+_start.to_s+" max="+_max.to_s)
  @results = dep_ping_for_results(_sets, _type, _query, _start, _max) 
  logger.debug("Results Found: " + @results.length.to_s)
  if @results==nil or @results.empty?
    flash.now[:notice]=translate('NO_RESULTS')
  else
    collectDBErrors
    buildAllDatabases
    filter_results
    sort_results
    #This is where I will drop building the database_subjects_authors. This will occur if it's a 
    #mobile interface
    #build_databases_subjects_authors
    filter_images
  end
rescue Exception => e
  logger.info("RecordController caught ERROR: " + e.to_s)
  logger.info(e.backtrace.to_s)
  flash.now[:error]=translate('ERROR_OCCURED',[e.to_s])
end

def dep_ping_for_results(_sets=@sets, _type=@type, _query=@query, _start=@start, _max=@max)  
    ids = $objDispatch.SearchAsync(_sets, _type, _query, _start, _max) 
    completed=[]
    errors=[]
    start_time=Time.now
    while ((completed.length.to_i+errors.length.to_i)<ids.length.to_i) && ((Time.now-start_time)<30)
      sleep(0.5)
      count=0
      for id in ids
        if !completed.include?(id)
	  #clear the record cache
 	  ActiveRecord::Base.clear_active_connections!() 
          item=$objDispatch.CheckJobStatus(id)
          count=count+1
          if item.status==-1
            if !errors.include?(id)
              errors<<id
            end
          elsif item.status==0
 	      logger.debug("completed: " + id.to_s)
              completed<<id
          end
        end
      end
    end
    return $objDispatch.GetJobsRecords(completed, _max)
end

def collectDBErrors
  errors=""
  vendors=Array.new
  for record in @results
   # if record.error!=nil and record.error!=""
   #   if !vendors.include?(record.vendor_name)
   #     vendors<<record.vendor_name
   #     errors=record.vendor_name+": "+record.error+"<br>"
   #   end
   # end
  end
  if errors!=""
    flash.now[:notice]=translate('DB_ERRORS',[errors])
  end
end


def find_search_results
  @results= $objDispatch.GetJobsRecords(@completed, '25')
  if @results==nil or @results.empty?
    flash.now[:notice]=translate('NO_RESULTS')
  else
    process_results
  end
rescue Exception => e
  logger.info("RecordController caught ERROR: " + e.to_s)
  logger.info(e.backtrace.to_s)
  flash.now[:error]=translate('ERROR_OCCURED',[e.to_s])
end

def process_results
    buildAllDatabases
    filter_results
    #sort_results
    if @IsMobile != true
       build_databases_subjects_authors
    end
    sort_results
    filter_images
end

def init_pinging_params
  if params[:jobs]==nil
    @jobs=[]
  else
    @jobs=params[:jobs].split(',')
  end
end

def check_job_status
  @completed=[]
  @jobs_remaining=0
  @completed_targets=""
  @remaining_targets=""
  completed_items=[]
  init_pinging_params
  for id in @jobs
    item=$objDispatch.CheckJobStatus(id)
    if item.status==0 
       @completed<<id
       completed_items<<item
     elsif item.status==1
      @jobs_remaining=@jobs_remaining+1
      if item.target_name!=nil and item.target_name.to_s!='nil'
        @remaining_targets=@remaining_targets+item.target_name.to_s+"<br/>"
      end
    end
  end
  sorted_completed=completed_items.sort{|a,b|b.hits.to_i <=> a.hits.to_i}
  for target in sorted_completed
     if target.target_name!=nil and target.target_name.to_s!='nil'
      @completed_targets=@completed_targets+"<span id='completed_targets'>"+target.target_name.to_s+"</span>"+target.hits.to_s+" hits<br/>"
    end
  end
  if params[:mobile] != nil and params[:mobile] == true
    @IsMobile = true
  end
  render(:partial => 'pinging')

end

def finish_search
  @completed=[]
  @errors=Hash.new
  @private = Hash.new
  init_pinging_params
  for id in @jobs
    item=$objDispatch.CheckJobStatus(id)
    if item.status==1
      if item.thread_id.to_i>0
        begin
          if item.target_name!=nil
            flash.now[:notice]=translate('SEARCH_STOPPED') 
          end
          $objDispatch.KillThread(id, item.thread_id)
        rescue Exception => e
          logger.info("RecordController caught ERROR: " + e.to_s)
          logger.info(e.backtrace.to_s)   
        end
      end
    elsif item.status==0 
      @completed<<id
    elsif item.status==-1
      @errors[item.target_name]=item.error
    elsif item.status==-2
       objAuth = Authorize.new
       if objAuth.IsPrivateVisible(request.env['REMOTE_ADDR'], request.env['HTTP_REFERER']) == false
         @private[item.target_name]=item.error
       else
	  @completed<<id
       end
    end
  end  

  @jobs=[]
  @results= $objDispatch.GetJobsRecords(@completed, '25')
  setDefaults
  set_query_values
  init_search
  spell_check
  if params[:mobile] != nil and params[:mobile] == 'true'
    @IsMobile = true
  end 
  if @results==nil or @results.empty?
    flash.now[:notice]=flash.now[:notice].to_s+'<br/>'+translate('NO_RESULTS')
  else
   process_results
  end 
  render(:action => @tab_template,:layout=>true)
end

def set_query_values
  @query=params[:query][:string].to_s.split(',')
  @type=params[:query][:type].to_s.split(',')
end
#Initialize all global variables.
#For sets, if they are specified as parameters, use those sets.  
#In the case that the group is being changed, then default to the sets for that group.
def init_search
  @isbn_list = ""
  @image_isbn_list = ""
  if params[:filter]!=nil && params[:filter]!="" && !params[:filter].empty?
    @filter=[]
    for filter_pair in params[:filter].to_s.split("/")
      if filter_pair!=nil and filter_pair!=""
        @filter<<filter_pair.split(":")
      end
    end
  end  
  if params[:query][:max]!=nil and params[:query][:max]!='' 
    @max = params[:query][:max]
  end  
  if params[:query][:mod]!=nil and params[:query][:mod]!='' 
    @mod = params[:query][:mod]
  end 
  if params[:mode]!=nil and params[:mode]!='' 
    @mode = params[:mode]
  end 
  if params[:sort_value]!=nil && params[:sort_value]!=''
    @sort_value=params[:sort_value]
  end
  if params[:query][:start]!=nil and params[:query][:start]!='' 
    @start = params[:query][:start]
  end
  if params[:tab_template]!=nil and params[:tab_template]!='' 
    @tab_template = params[:tab_template]
  end
  if params[:sets]!=nil && params[:sets]!=''
    @sets=params[:sets]
  else
    @sets=getSelectedSets
    if @sets==nil || @sets.empty?
      init_sets
    end
  end
  if @sets.rindex(',')==@sets.length-1
    @sets=@sets.chop
  end
  if params[:completed]!=nil and params[:completed]!='' 
    @completed = params[:completed].split(',')
  end
 
  if params[:mobile]!=nil and params[:mobile]=='true'
    @IsMobile = true
  end 
end

def defaultNilValues
  for record in @results
    if record.rank==nil
      record.rank='0'
    end
    if record.author==nil
      record.author=""
    end
    if record.date==nil
      record.date='00000000'
    end
  end
end

def setDefaults
  @filter=[]
  @max="25"
  @mod="0"
  @mode="simple"
  @query=[""]
  @sort_value='relevance'
  @start="0"
  @type=["keyword"]
  @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
  @tab_template=@config["GENERAL_TEMPLATE"]
  @jobs=nil
end

def buildQueryArray(query)
  queryArray=[]
  if query!=nil
    queryArray = query.split(":")
    if queryArray[0].to_s.downcase+":"==@attributeArray[0]
      queryArray[0]="subject"
    else 
      if queryArray[0].to_s.downcase+":"==@attributeArray[2] 
        queryArray[0]="creator"
      else 
        if queryArray[0].to_s.downcase+":"==@attributeArray[3]
          queryArray[0]="creator"
        else 
	  if queryArray[0].to_s.downcase+":"==@attributeArray[4]
	    queryArray[0]="title"
	  else
	    queryArray[0] = ""
	  end
        end
      end
    end
    if queryArray.length>2 
      for _query in queryArray
        queryArray[1] = queryArray[1].to_s + " " + _query.to_s 
      end
    end
  end
  queryArray
end

def strip_quotes(_record)
  _record.vendor_name.gsub!("'") {""}
  _record.subject.gsub!("'") {""}
  _record.author.gsub!("'") {""}
end

def buildAllDatabases
  _database_hash = Hash.new  
  for _record in @results    
    strip_quotes(_record)
    if _record.hits==nil or _record.hits==''
      _record.hits="0"
    end
    if _database_hash[_record.vendor_name]==nil 
      _database_hash[_record.vendor_name]=[_record,1]
    else  
      _database_hash[_record.vendor_name]=[_record,_database_hash[_record.vendor_name][1]+1]
    end
  end
  @all_databases=_database_hash.sort {|a,b| b[1][0].hits.to_i <=> a[1][0].hits.to_i} 
end
   
#this method uses one loop to build 3 arrays to diplay to the user: databases, 
#@databases is a list of all searched databases sorted on the number of hits
#@subjects is a list of all subjects in search results sorted on the number of records with that subject
#@authors is a list of all authors in search results sorted on the number of records with that author
def build_databases_subjects_authors
  _database_hash = Hash.new  
  _material_type_hash = Hash.new  
  _subject_hash= Hash.new
  _author_hash=Hash.new
  for _record in @results       
    if _record.hits==nil or _record.hits==''
      _record.hits="0"
    end
    _record.id.gsub!(";") {"_"}
    if _database_hash[_record.vendor_name]==nil 
       _database_hash[_record.vendor_name]=[_record,1]
     else  
       _database_hash[_record.vendor_name]=[_record,_database_hash[_record.vendor_name][1]+1]
     end    
     if _material_type_hash[_record.material_type]==nil 
      _material_type_hash[_record.material_type]=1
    else  
      _material_type_hash[_record.material_type]=_material_type_hash[_record.material_type]+1
    end  
     _subjects=_record.subject
    if _subjects!=nil and _subjects!=''
      _subject_array=_subjects.split(";")
      _subject_array.delete_if {|a| a.strip==""}
      for _subject in _subject_array
        _subject=_subject.strip
        if _subject_hash[_subject]==nil 
         if _subject_hash.length >= 15
            _subject_hash = _subject_hash.sort.inject({}) {|h, elem| h[elem[0]]=elem[1]; h}
            _subject_hash.shift
          end

          _subject_hash[_subject]=1
        else  
          _subject_hash[_subject]=_subject_hash[_subject]+1
        end
      end
    end
    _authors=_record.author
    if _authors!=nil and _authors!=''
      _author_array=_authors.split(";")
      _author_array.delete_if {|a| a.strip==""}
      for _author in _author_array
        _author=_author.strip
        if _author_hash[_author]==nil 
	  if _author_hash.length >= 15
             _author_hash = _author_hash.sort.inject({}) {|h, elem| h[elem[0]]=elem[1]; h}
             _author_hash.shift
          end

          _author_hash[_author]=1
        else  
          _author_hash[_author]=_author_hash[_author]+1
        end
      end
    end
  end
  @authors=_author_hash.sort {|a,b| b[1].to_i<=>a[1].to_i}
  @subjects=_subject_hash.sort {|a,b| b[1].to_i<=>a[1].to_i}
  @databases=_database_hash.sort {|a,b| b[1][0].hits.to_i <=> a[1][0].hits.to_i} 
  @material_types=_material_type_hash.sort {|a,b| a[0]<=>b[0]}   
end
  
def initQueryAndType(params)
  @query=[]
  @type=[]
  query_string=params[:query][:string]
  @attributeArray=Array["su:", "subject:", "au:", "author:", "ti:", "title:"]
  for attribute in @attributeArray
    if query_string.include?(attribute)
      initShortcutQuery(query_string)
      break
    end
  end
  if @query.empty?
    boolean_query=""
    if query_string!=nil and query_string.strip!=""
      boolean_query=query_string
    end
    if params[:query][:string_exact]!=nil and params[:query][:string_exact].to_s.strip!=""
      query_EXACT=buildEXACT(params[:query][:string_exact])
      if boolean_query!=""
        boolean_query=boolean_query+" AND "+query_EXACT
      else
        boolean_query=boolean_query+query_EXACT
      end
    end
    if params[:query][:string_any]!=nil and params[:query][:string_any].to_s.strip!=""
      query_OR=buildOR(params[:query][:string_any])
      if boolean_query!=""
        boolean_query=boolean_query+" AND "+query_OR
      else
        boolean_query=boolean_query+query_OR
      end
end
    if boolean_query!=""
      @query=[boolean_query]
      params[:query][:string]=boolean_query
      if params[:query][:type]!=nil and params[:query][:type].to_s.strip!=""
        @type=[params[:query][:type].to_s]
      else
        @type=['keyword']
      end
    end
  end
  if params[:query][:type_author]!=nil and params[:query][:type_author].to_s.strip!=""
    @query<<params[:query][:type_author].to_s
    @type<<"creator"
  end
  if params[:query][:type_subject]!=nil and params[:query][:type_subject].to_s.strip!=""
    @query<<params[:query][:type_subject].to_s
    @type<<"subject"
  end
  if params[:query][:type_title]!=nil and params[:query][:type_title].to_s.strip!=""
    @query<<params[:query][:type_title].to_s
    @type<<"title"
  end
end

def initShortcutQuery(query)
   _query_array=buildQueryArray(query) 
  _type_param=_query_array[0]
  _query_param=_query_array[1]
  if _type_param==nil or _type_param.empty? 
    @type = ["keyword"]
  else
    @type = [_type_param]
  end
  @query = [_query_param] 
end

def getSelectedSets
 checkboxes=params[:collection_group]
 if checkboxes!=nil
      @sets=""
    for group in checkboxes 
      if group[1]=='1'
        @sets=@sets+group[0]+','
      end
    end
  end
  @sets
end

def init_sets
    @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
    @sets=""
    groups=@config["DEFAULT_GROUPS"].to_s.split(',')
    for group in groups
      _item = $objDispatch.GetGroupMembers(group)
      @sets = @sets+_item.id+","
    end
    if @sets==nil or @sets==''
      default_sets
    end
  rescue Exception => e
    logger.info("RecordController caught ERROR: " + e.to_s)
  logger.info(e.backtrace.to_s)
    flash.now[:error]=translate('ERRORS_GETTING_GROUPS')
    default_sets
end    
  
def default_sets
  @sets = 'g2,g3'
end
  
def buildEXACT(query)
  containsQuote = query.index('"')
  lastQuote = query.rindex('"')
  if containsQuote==nil || lastQuote!=query.length-1
    containsQuote = query.index('&quot;')
    lastQuote = query.rindex('&quot;')
    if containsQuote==nil || lastQuote!=query.length-1
      query='"' + query + '"'
    end
  end
  query
end
    
def buildOR(query)
  containsOr = query.index(" or ")
  if containsOr==nil 
    newString = ""
    stringArray = query.split(" ")
    iterate=stringArray.length-1
    iterate.times do |i|
      newString = newString + stringArray[i] + " or "
     end
    newString = newString + stringArray[stringArray.length-1]
    query=newString
  end
  query
end

def filter_results
  if @filter!=nil and @filter!="" and @results!=nil and !@filter.empty?
    for filter_pair in @filter
      if filter_pair!=nil and !filter_pair.empty?
        filter_type=filter_pair[0].to_s
        filter_value=filter_pair[1].to_s
        @results.delete_if {|_record| _record.send(filter_type)==nil or !_record.send(filter_type).downcase.include?(filter_value.downcase)}
      end
    end
      if @results==nil or @results.empty?
    flash.now[:notice]=translate('FILTER_DID_NOT_MATCH')
  end
  end  
end

  
def filter_images
  if @results!=nil
    @config ||= YAML::load_file(RAILS_ROOT + "/config/config.yml")
    if @tab_template!=@config["IMAGES_TEMPLATE"]
      found_first=false
      filtered_results=Array.new
      for record in @results
        if record.material_type.downcase=="image"
          if !found_first
            found_first=true
            filtered_results<<record
          end
        else
          filtered_results<<record
        end 
      end
      @all_results=@results
      @results=filtered_results
    end
  end
end
  
  
def sort_results
  _nrec = Hash.new
  defaultNilValues
  for record in @results
    if defined? LIBRARYFIND_SPECIAL_WEIGHT
      if (defined?(record.oclc_num)==true and (record.oclc_num != nil or record.oclc_num != ''))
         if _nrec.has_key?(record.oclc_num) == true
           if _nrec[record.oclc_num].vendor_name.index(LIBRARYFIND_SPECIAL_WEIGHT) == nil
              if record.vendor_name.index(LIBRARYFIND_SPECIAL_WEIGHT) != nil
                 _nrec[record.oclc_num] = record
              else
                 if record.rank.to_i > _nrec[record.oclc_num].rank.to_i
                   _nrec[record.oclc_num] = record
                 end
              end
           end
         else
           _nrec[record.oclc_num] = record
         end
      else
         _nrec[record.id] = record
      end
    end

    diff=8-record.date.length
    if diff > 0
      padding="0"*diff
      record.date=record.date+padding
    end
  end

  if defined? LIBRARYFIND_SPECIAL_WEIGHT
     @results = _nrec.values
  end
 if @sort_value=='relevance' or @sort_value==nil or @results==nil
    @results.sort!{|a,b| b.rank.to_f <=> a.rank.to_f} 
  else
    case @sort_value
      when "dateup"
        #Using 500000000-rank so that results are displayed with highest rank first
        @results=@results.sort_by{|a| [a.date,  500000000-a.rank.to_f]}  
      when "datedown"
        #using 100000000-date so that dates are displayed with highest first
        @results=@results.sort_by{|a| [100000000-a.date.to_i,  500000000-a.rank.to_f]}   
      when "authorup"
        @results=@results.sort_by{|a| [a.author,  500000000-a.rank.to_f]}  
      when "authordown"        
        @results=@results.sort_by{|a| [a.author,  a.rank.to_f]}  
        @results.reverse!
    end
  end
end

def image_tooltip
  _id = params[:id]
  @selected_image=nil
   id = params[:id]
  @selected_image=$objDispatch.GetId(id.gsub("_") {";"}) 
  @selected_image.id.gsub!(";") {"_"}
  strip_quotes(@selected_image)
  if @selected_image==nil
    flash.now[:notice]=translate('IMAGE_NOT_FOUND')
  else
    render(:layout=>false)
  end
end
 
def show_citation
  id = params[:id]
  @record_for_citation=$objDispatch.GetId(id.gsub("_") {";"}) 
  @record_for_citation.id.gsub!(";") {"_"}
  strip_quotes(@record_for_citation)
  @record_for_citation
  render(:layout=>false)  
end
 
def spell_check
  #todo - when we implement advanced search with more than 1 query term, we'll need to change this
  #_word=the array of query terms the user entered to be spell-checked
  _query=@query[0].to_s
  _attribute_list = ["su:","subject:","au:","author:","ti:","title:"]
  #strip out any 'or' or 'and' from the query before getting spelling suggestions
  _query = _query.gsub(" or ", " ")
  _query = _query.gsub(" and ", " ")
  #strip any attribute shortcuts out of query before getting spelling suggestions
  _attribute=""
  for _att in _attribute_list
    if _query.include? _att
      _query=_query.gsub(_att,"")
      _attribute=_att
      break
    end
  end
  @spelling_list=Array.new
  if _query!=nil and _query!=''
    _google_spell = GoogleSpell.new
    #_words=the wordlist of corrected words from google
    _words = _google_spell.GetWords(_query)
    if _words!=nil and !_words.empty?
      _length=1
      _temp = Array.new
      #This routine figures out how many suggestions to present to user
      _no_suggestions=true
      for _n in 0.._words.length-1 
        if _words[_n]['data'].empty?
           _temp[_n] = _words[_n]['original'].to_a
        else
          _no_suggestions=false
          _temp[_n] = _words[_n]['data'].split(/\t/)
        end
        _length=_length*_temp[_n].length
      end
      if _no_suggestions
        return
      end
     #@spelling_list contains the list of combined suggestions to present to user
      #this routine iterates through all suggestions from google and creates all possible combinations to present to user
      #_i is the column and _j is the row for _temp
      
      for _i in 0.._temp.length-1
        if _temp!=nil and _temp[_i]!=nil and _temp[_i].length>0
        _count=0
        _j=0
        while _count<_length
          #_rep is the number of repetitions for each word to be placed in the array
          _rep=1
          for _m in _i+1.._temp.length-1
            _rep=_rep*_temp[_m].length
          end
          _rep=_rep-1
          for _k in 0.._rep
            if @spelling_list[_count]==nil
              @spelling_list[_count]=_attribute+_temp[_i][_j].to_s
            else
              @spelling_list[_count]=@spelling_list[_count]+" "+_temp[_i][_j].to_s
            end
            _count=_count+1
          end  #end for
          if _j==(_temp[_i].length)-1
            _j=0
          else 
            _j=_j+1
          end
        end    #end for 
      end    #end if
    end      #end for
  end      #end if
end        #end if
rescue
    #ignore spelling errors?
end          #end def


def feed
 begin
   setDefaults
   init_search
   initQueryAndType(params)
   logger.debug("FEED TYPE: " + @type.to_s)
   logger.debug("FEED QUERY: " + @query.to_s)
   ids = $objDispatch.SearchAsync(@sets, @type, @query, @start, @max)
   logger.debug(ids.to_s)
   #loop through the ids to get info
    completed=[]
    errors=[]
    start_time=Time.now
    while ((completed.length.to_i+errors.length.to_i)<ids.length.to_i) && ((Time.now-start_time)<30)
      sleep(0.5)
      count=0
      for id in ids
        if !completed.include?(id)
          #clear the record cache
          ActiveRecord::Base.clear_active_connections!()
          item=$objDispatch.CheckJobStatus(id)
          count=count+1
          if item.status==-1
            if !errors.include?(id)
              errors<<id
            end
          elsif item.status==0
              logger.debug("completed: " + id.to_s)
              completed<<id
          end
        end
      end
    end
    @records =  $objDispatch.GetJobsRecords(completed, @max)
    headers["Content-Type"] = "application/xml"
    render :layout =>false
 rescue
   ids << "error"
 end
end

end
