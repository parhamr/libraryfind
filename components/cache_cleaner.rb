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

require 'rubygems'
if ENV['LIBRARYFIND_HOME'] == nil: ENV['LIBRARYFIND_HOME'] = "../" end
require ENV['LIBRARYFIND_HOME'] + 'config/boot.rb'
require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'

require "mysql"
require 'yaml'
require "date"
require 'soap/wsdlDriver'


def checknil(s)
  if s == nil: return "" end
  return s
end

db = YAML::load_file(ENV['LIBRARYFIND_HOME'] + "config/database.yml")

if ARGV.length==0
  ARGV[0] = "development"
end

dbtype  = ARGV[0]

case PARSER_TYPE
  when 'libxml'
    require 'xml/libxml'
  when 'rexml'
    require 'rexml/document'
  else
    require 'rexml/document'
end

dbh = Mysql.real_connect(db[dbtype]["host"], db[dbtype]["username"], db[dbtype]["password"], db[dbtype]["database"])
dbh1 =  Mysql.real_connect(db[dbtype]["host"], db[dbtype]["username"], db[dbtype]["password"], db[dbtype]["database"])


datetime = Time.now - (4*(24*(60*60)))
myDate = Mysql::Time.new(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)

puts myDate.to_s
query = "delete from cached_records where created_at < " + datetime.strftime("%Y%m%d") 


dbh.query(query)

puts "Cached has been purged."
#End
