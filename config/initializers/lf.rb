#========================================================================
# Create some text based constants
#========================================================================
LIBRARYFIND_LOCAL = 1
LIBRARYFIND_WSDL_ENGINE = 0
LIBRARYFIND_SFX = 2
LIBRARYFIND_SS = 3

#========================================================================
# LIBRARYFIND_BASEURL: Sets the base url
#    Description:  This is used to set the Proxy info
#========================================================================
LIBRARYFIND_BASEURL = "http://libdev-current.library.oregonstate.edu/"

#========================================================================
# LIBRARYFIND_PROCESS_TIMEOUT: Sets timeout property for connections that
# require it
#========================================================================
LIBRARYFIND_PROCESS_TIMEOUT = 30

#========================================================================
# LIBRARYFIND_PROXY_TYPE: Sets the proxy type
#     which is used for determining proxy styles.
#     value:
#          WAM -- III's proxy setup
#          EZPROXY -- EZPROXY's proxy url setup
#          NONE -- No proxy
#========================================================================
LIBRARYFIND_PROXY_TYPE = "EZPROXY"

#========================================================================
# LIBRARYFIND_PROXY_ADDRESS: Sets proxy address for use when writing
#     WAM or Ezproxy URLS
#     Description: Used for generating proxy info
#========================================================================
LIBRARYFIND_PROXY_ADDRESS = 'http://proxy.library.oregonstate.edu/login?url='

#========================================================================
# LIBRARYFIND_PROXY_STUB: 
#     Description: Used to evaluate proxy string for authentication
#========================================================================
LIBRARYFIND_PROXY_STUB = 'proxy.library.oregonstate.edu'

#========================================================================
# LIBRARYFIND_USE_PROXY: Uses proxy generation
#   Value: true, false
#========================================================================
LIBRARYFIND_USE_PROXY = true

#=======================================================================
# LIBRARYFIND_OFFER_LOGIN: 
# Value: true, false
# Description: Set this value if you want to offer proxy authentication
# for private resources
#=======================================================================
LIBRARYFIND_OFFER_LOGIN = true


#========================================================================
# LIBRARYFIND_IS_SERVER: Denotes if application is a wsdl producer
#   Values: true -- Does serve WSDL
#           false -- Does not server WSDL
#========================================================================
LIBRARYFIND_IS_SERVER = true

#=========================================================================
# LIBRARYFIND_WSDL:  Denotes if search is done locally or through a WSDL
#                    interface
#
#Enum for LIBRARYFIND_WSDL
# LIBRARYFIND_WSDL_ENGINE
# LIBRARYFIND_LOCAL
#==========================================================================
LIBRARYFIND_WSDL = LIBRARYFIND_LOCAL
LIBRARYFIND_WSDL_HOST = "http://apollo.library.oregonstate.edu:3000/query/wsdl"

#===========================================================================
# LIBRARYFIND_OPENURL_TYPE: Denotes look ahead options.  Current options
#                           available: LIBRARYFIND_LOCAL or LIBRARYFIND_SFX
# Enum for LIBRARYFIND_OPENURL_TYPE
#  LIBRARYFIND_LOCAL
#  LIBRARYFIND_SFX
#  LIBRARYFIND_SS
#  LIBRARYFIND_GD  (Gold Dust Link Resolver)
#===========================================================================
LIBRARYFIND_OPENURL_TYPE = LIBRARYFIND_LOCAL

#============================================================================
# LIBRARYFIND_OPENURL: Defines OpenURL base for queries.  This can be any
#                      openurl resolver that supports OpenURL 1.0
#============================================================================
LIBRARYFIND_OPENURL = 'http://oasis.oregonstate.edu:4550/resserv?'

#=========================================================================
# LIBRARYFIND_EMAIL_USER:  Email address from which LibraryFind mail will
#                                                  be sent (e.g. for emailing selected search results)
#   Example:
#   LIBRARYFIND_EMAIL_USER = 'LFadmin@myuniversity.edu'
#=========================================================================
LIBRARYFIND_EMAIL_USER = 'terry.reese@oregonstate.edu'

LIBRARYFIND_CACHE_OK = 0
LIBRARYFIND_CACHE_EMPTY = 1
LIBRARYFIND_CACHE_ERROR = 2



require 'yaml'

yp = YAML::load_file(RAILS_ROOT + "/config/config.yml")
LIBRARYFIND_FERRET_PATH = yp['LIBRARYFIND_FERRET_PATH']
LIBRARYFIND_SOLR_HOST = yp['LIBRARYFIND_SOLR_HOST']
LIBRARYFIND_INDEXER = yp['LIBRARYFIND_INDEXER']
PARSER_TYPE = yp['PARSER_TYPE']
#LIBRARYTHING_DEVKEY = yp['LIBRARYTHING_DEVKEY']
#OPENLIBRARY_COVERS = yp['OPENLIBRARY_COVERS']
GOOGLE_COVERS = yp['GOOGLE_COVERS']

# Extract the ILL Link Associated with LibraryFind
LIBRARYFIND_ILL = yp['ILL_URL']

CROSSREF_ID = "osul:osul1211"
DOI_SERVLET = "http://doi.crossref.org/servlet/query?id={@DOI}&pid=" + CROSSREF_ID
YAHOO_APPLICATION_ID = 'QlxYkgvV34EfBvtpTxwm160eWujk1advwfSZCHllZQUyQJf8PanUbw7dcJPJfLJlOpdWyhYNcKavKPST'

LIBRARYFIND_OCLC_SYMBOL= 'ORE'
LIBRARYFIND_SERVER_IP = '128.193.163.0'
LIBRARYFIND_IP_RANGE = '128.193.;10.;140.211.24.;'

ActiveRecord::Base.allow_concurrency  = true
ActiveRecord::Base.verification_timeout  = 590

