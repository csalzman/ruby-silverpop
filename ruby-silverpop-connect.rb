##############
#
#Connecting to the SP XML API
#Create a new Silverpop object with your login information
# 
############

require 'rest-client'
require 'nokogiri'
require 'uri'

#Silverpop class. Initializes and finds the jsessionid, which is needed for everything else.
class Silverpop
  require 'nokogiri'
  require 'rest-client'
  
  attr_accessor :sessionid, :username, :password, :endpoint

  def initialize(username, password, endpoint)
    @username = username
    @password = password
    @endpoint = endpoint

    #set sessionid block
    jsession_builder = Nokogiri::XML::Builder.new do 
        Envelope {
          Body {
            Login {
              USERNAME username
              PASSWORD password
            }
          }
        }
    end
    
    response = RestClient.get(ENV['SILVERPOP_ENDPOINT'] + "?xml=" + URI::encode(jsession_builder.to_xml))
    
    #parse response for sessionid (or error) and set as objects' @sessionid
    doc = Nokogiri::XML(response)

    #If successful sets sessionid appropriately. If not, exits with errorid and fault string
    if (doc.at_xpath('//SESSIONID'))
      @sessionid = doc.at_xpath('//SESSIONID').inner_text
    else
      puts "Silverpop Errorid: " + doc.at_xpath('//errorid').inner_text + ". " + doc.at_xpath('//FaultString').inner_text
    end
  end    

  #Post a well-formatted bit of xml to Silverpop  
  def silverpop_request_post(xml)
    url = ENV['SILVERPOP_ENDPOINT'] + ";jsessionid=#{@sessionid.to_s}"
    return RestClient.post(url, xml.to_xml, :Content_type => "text/xml", :Content_length => xml.to_xml.length)
  end
  
end

#New object with authentication. Find your endpoint in the SP api documentation.
silverpop = Silverpop.new(ENV['SILVERPOP_USERNAME'], ENV['SILVERPOP_PASSWORD'], ENV['SILVERPOP_ENDPOINT'])
