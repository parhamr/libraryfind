module CartHelper
 
  def build_cart_contents
    @cart_contents=[]
    if session[:cart]!=nil && !session[:cart].empty?
      for id in session[:cart]
      _temp_id = id.gsub("_") {";"}
      _result=$objDispatch.GetId(_temp_id) 
      _result.id.gsub!(";") {"_"}
      strip_quotes(_result)
        @cart_contents<<_result
      end
    end
  end

  def paginate_cart(_page_size=10)
    build_cart_contents
    if @cart_contents==nil or @cart_contents.empty?
      return
    end
    @results_count=@cart_contents.length
    # @page => "Which page we're showing"
    if params[:page]
      @page = params[:page].to_i
    else
      @page = 1
    end

    @show_previous = false
    @show_next = false
    @page_list = []
    
    # Check for obvious errors
    #for this case, we add _page_size to the result count to handle the case of the last page
    if @results_count + _page_size <= (@page * _page_size)
      return
    elsif @page <= 0 
      return
    end
    
    # Limit the result set to this page
    @start_item = (@page - 1) * _page_size
    @finish_item = (@page * _page_size)
    if @finish_item > @results_count
      @finish_item = @results_count
    end
    @cart_page = @cart_contents[@start_item...@finish_item]
    
    # Should we show the "Previous" link?
    if @page != 1
      @show_previous = true
      @previous = @page - 1
    end
    
    # Should we show the "Next" link?
    _num_pages = (@results_count / Float(_page_size)).ceil
    if @page < _num_pages
      @show_next = true
      @next = @page + 1
    end
    # Find the page num range to display
    _first_page = ((((@page-1) / Float(_page_size)).floor)*10)+1
    if _num_pages < _first_page + 10
      _last_page = _num_pages + 1
    else
      _last_page = _first_page + 10
    end
    @page_list = _first_page ... _last_page
  end

 
  def strip_quotes(_record)
      _record.vendor_name.gsub!("'") {""}
      _record.subject.gsub!("'") {""}
      _record.author.gsub!("'") {""}
  end

end
