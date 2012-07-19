class JsonController < ApplicationController
  def search
     begin
       setDefaults
       init_search
       ids = $objDispatch.SearchAsync(@sets, @type, @query, @start, @max)
     rescue
       ids << "error"
     end
     headers["Content-Type"] = "text/plain; charset=utf-8"
     render :text => ids.to_json 
  end

  def CheckJobStatus
      begin
        status = nil
        if params[:id] != nil
	   status = $objDispatch.CheckJobStatus(params[:id])
        end
      rescue
	  status << "error"
      end
      headers["Content-Type"] = "text/plain; charset=utf-8"
      render :text => status.to_json
  end

  def GetJobRecord
      begin
        id = params[:id]
        max = params[:max]
        record = $objDispatch.GetJobRecord(id, max)
      rescue
	record << "error"
      end 
      headers["Content-Type"] = "text/plain; charset=utf-8"
      render :text => record.to_json
  end	

  def ListCollections
     obj = $objDispatch.ListCollections
     headers["Content-Type"] = "text/plain; charset=utf-8"
     render :text => obj.to_json
  end

  def ListGroups
     obj = $objDispatch.ListGroups
     headers["Content-Type"] = "text/plain; charset=utf-8"
     render :text => obj.to_json
  end

  def GetGroupMembers
     begin
        obj = $objDispatch.GetGroupMembers(params[:name])
     rescue
	obj << "error"
     end
     headers["Content-Type"] = "text/plain; charset=utf-8"
     render :text => obj.to_json
  end

  def KillThread
      begin
        jobid = params[:jobid]
        threadid = params[:threadid]
        $objDispatch.KillThread(jobid, threadid)
        status << "success"  
      rescue
	status << "error"
      end

      headers["Content-Type"] = "text/plain; charset=utf-8"
      render :text => status.to_json
  end

def initQueryAndType(query, type)
   _query_array=buildQueryArray(query)
   if _query_array.length<2
    _type_param=type
    _query_param=query
  else
    _type_param=_query_array[0]
    _query_param=_query_array[1]
  end
  if _type_param==nil or _type_param.empty?
    @type = ["keyword"]
  else
    @type = [_type_param]
  end
  @query = [_query_param]
end

#Initialize all global variables.
#For sets, if they are specified as parameters, use those sets.  
def init_search
  @isbn_list = ""
  setDefaults
  logger.debug(params.to_s)
  initQueryAndType(params[:query][:string],params[:query][:type])
  if (params[:query][:mod] != "0") 
    initAttributeSearch(params[:query][:mod])
  end
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
end

def buildQueryArray(query)
  queryArray=[]
  if query!=nil
    attributeArray=Array["su:", "subject:", "au:", "author:", "ti:", "title:"]
    queryArray = query.split(":")
    if queryArray[0].to_s.downcase+":"==attributeArray[0]
      queryArray[0]="subject"
    else 
      if queryArray[0].to_s.downcase+":"==attributeArray[2] 
        queryArray[0]="creator"
      else 
        if queryArray[0].to_s.downcase+":"==attributeArray[3]
          queryArray[0]="creator"
        else 
          if queryArray[0].to_s.downcase+":"==attributeArray[4]
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

def initAttributeSearch(word_modifier)
  if word_modifier == "1"
    containsQuote = @query[0].to_s.index('"')
    lastQuote = @query[0].to_s.rindex('"')
    if containsQuote==nil || lastQuote!=@query[0].to_s.length-1
      containsQuote = @query[0].to_s.index('&quot;')
      lastQuote = @query[0].to_s.rindex('&quot;')
      if containsQuote==nil || lastQuote!=@query[0].to_s.length-1
        @query[0]='"' + @query[0] + '"'
      end
    end
  else
    if word_modifier == "2"
      containsOr = @query[0].to_s.index(" or ")
      if containsOr==nil
        newString = ""
        stringArray = @query[0].to_s.split(" ")
        iterate=stringArray.length-1
        iterate.times do |i|
          newString = newString + stringArray[i] + " or "
         end
        newString = newString + stringArray[stringArray.length-1]
        @query[0]=newString
      end
    end
  end
end


end
