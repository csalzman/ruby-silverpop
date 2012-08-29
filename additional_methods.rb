################
# Once you connect to the SP API, hooking into it with Ruby is as simple
# as replicating the XML in the documentation. These scripts use Nokogiri
# to build XML in a friendlier format.
###############

#Add a recipient to a database or list
def addrecipient(email, listid)
  builder = Nokogiri::XML::Builder.new do
    Envelope {
      Body {
        AddRecipient {
          LIST_ID listid
          CREATED_FROM '1'
          UPDATE_IF_FOUND 'true'
          COLUMN {
            NAME 'EMAIL'
            VALUE email
          }
        }
      }
    }
  end
  
  response = silverpop_request_post(builder)
  return response.body
end
  
#Return information on a user
def get_user(email, listid)
  builder = Nokogiri::XML::Builder.new do
    Envelope {
      Body {
        SelectRecipientData {
          LIST_ID listid
          EMAIL email 
        }
      }
    }
  end

  response = silverpop_request_post(builder)
  return response.body
end

#Return an array of rulesets for an email
def rulesets_for_email(mailing_id)
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.Envelope {
      xml.Body {
        xml.ListDCRulesetsForMailing {
          xml.MAILING_ID mailing_id
        }
      }
    }
  end
  response = silverpop_request_post(builder)
  
  rulesets = Nokogiri::XML(response)

  ruleset_array = []
  
  rulesets.xpath('//RULESET_ID').each do |x|
    ruleset_array.push(x.inner_text)
  end

  return ruleset_array
end