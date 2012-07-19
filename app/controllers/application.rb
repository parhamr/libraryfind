# $Id: application.rb 1285 2009-03-02 08:52:34Z reeset $

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

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base


#after_filter :set_charset

  if LIBRARYFIND_WSDL == 1 || LIBRARYFIND_IS_SERVER==true
    require 'record_set'
    require 'rubygems'
    if ::PARSER_TYPE == 'libxml'
      require 'xml/libxml'
    else
      require 'rexml/document'
    end
    require 'meta_search'
    require 'builder'
    #require "mysql"
    require "rzoom"
  end

  if LIBRARYFIND_INDEXER.downcase == 'ferret'
     require 'ferret'
  elsif LIBRARYFIND_INDEXER.downcase == 'solr'
     require 'solr'
  end

  require 'dispatch'
  require 'open-uri'
  require 'uri'
  require 'time'
  $objDispatch = Dispatch.new()
  
  private
  
#  def set_charset
#    content_type = headers["Content-Type"] || 'text/html'
#    if /^text\//.match(content_type)
#      headers["Content-Type"] = "#{content_type}; charset=utf-8"
#    end 
#  end 


  def authorize (role=nil, msg=nil)
    user = User.find_by_id(session[:user_id])
    session[:original_uri] = request.request_uri
    unless user
      logger.debug('UI needing authorization: ' + session[:original_uri])
      flash[:notice] =  msg || translate('PLEASE_LOG_IN')
      redirect_to(:controller => '/user', :action => 'login') and return
    end
    unless role.nil?
      if !user.send(role)
        response.headers["Status"] = "Unauthorized" 
        if msg?
          flash[:notice] = msg || translate('AUTHORIZATION_REQUIRED')
        end
        render :text => msg, :status => 401 and return  
      end
    end
  end
  
end
