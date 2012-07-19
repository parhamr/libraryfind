class CartController < ApplicationController
  include ApplicationHelper
  layout "libraryfind", :except => [:message, :add, :remove, :email]
  
  def add
    id=params[:id]
    if !get_cart.include?(id)
      session[:cart]<<id
      flash[:notice]=translate('ITEM_SAVED')
      render :action=>"message", :controller=>'/cart'
    end
  end
  
  def remove
    if session[:cart]!=nil && params[:id]!=nil && params[:id]!=''
      session[:cart].delete(params[:id])
        render :nothing => true
    end

  end
  
  def get_cart
    session[:cart] ||= []  
  end
        
  def build_cart_contents
    @cart_contents=[]
    if session[:cart]!=nil && !session[:cart].empty?
      for id in session[:cart]
      _result=$objDispatch.GetId(id.gsub("_") {";"}) 
      _result.id.gsub!(";") {"_"}
      strip_quotes(_result)
        @cart_contents<<_result
      end
    end
  end
  

  def email
    _email_address = params[:to]
    build_cart_contents
    email = ResultMailer.create_results(@cart_contents, _email_address) 
    email.set_content_type("text/html")
    ResultMailer.deliver(email)
    flash.now[:notice]=translate('EMAIL_SENT')
    render :action=>"message"
  end
  
   
  def strip_quotes(_record)
      _record.vendor_name.gsub!("'") {""}
      _record.subject.gsub!("'") {""}
      _record.author.gsub!("'") {""}
  end

 
end
