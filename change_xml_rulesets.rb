#############
# Explanation: This script is used to update the rulesets in an email
# that changes from time to time. Rather than recreating the rulesets
# each time we need to make a change, we instead use the API to push new
# changes to the rulesets. Below is a very rough example of how we use 
# the method.
############

#Update a ruleset in Silverpop with new XML
#ruleset_id is what ruleset to change
#content_area defines the name of the content area the ruleset effects
#default_content is the content that displays if there's no match
#rules is an array of hashes that holds information for each of the rules in the set:
# -:name is the name of the rule
# -:contents has the content that the rule displays upon a match
# -:expressions is a hash that contains all of the matching rules (* is required)
#   -:type determines what type of match you're after
#   -*:column_name is the field in the db you're checking against
#   -:operators is the operator you're using to check (ie = < >)
#   -*:values is what you're checking for (ie a string to match against)
#   -:and_or determines whether the current expression is an AND or OR compared to the last
#   -left_parens opens up a parentheses on the current expression
#   -:right_parens closes a parentheses on the current expression
def change_xml(ruleset_id, content_area, default_content, rules)
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.Envelope {
      xml.Body {
        xml.ReplaceDCRuleset {
          xml.RULESET_ID ruleset_id
          xml.CONTENT_AREAS {
            xml.CONTENT_AREA(:name => content_area, :type => "Body-HTML") {
              xml.DEFAULT_CONTENT(:name => "Default.#{content_area}") { xml.cdata default_content }
            }
          }
          xml.RULES {
            rules.each_with_index do |rule, index|
              xml.RULE {
                xml.RULE_NAME "Rule#{index+1}.#{rule[:name]}"
                xml.PRIORITY index + 1
                xml.CRITERIA {
                  rule[:expressions].each do |expression|
                    xml.EXPRESSION {
                      expression[:type].nil? ? (xml.TYPE "TE") : (xml.TYPE expression[:type])
                      xml.COLUMN_NAME expression[:column_name]
                      expression[:operators].nil? ? (xml.OPERATORS { xml.cdata "=" }) : (xml.OPERATORS expression[:operators])
                      xml.VALUES { xml.cdata expression[:values] }
                      expression[:and_or].nil? ? (xml.AND_OR) : (xml.AND_OR expression[:and_or])
                      expression[:left_parens].nil? ? (xml.LEFT_PARENS) : (xml.LEFT_PARENS expression[:left_parens]) 
                      expression[:right_parens].nil? ? (xml.RIGHT_PARENS) : (xml.RIGHT_PARENS expression[:right_parens])
                    }
                  end
                }
                xml.CONTENTS {
                  xml.CONTENT(:name => "Area#{index + 1}.#{content_area}", :content_area => content_area) { xml.cdata rule[:contents] }
                }
              }
            end
          }
        }
      }
    }
  end
  silverpop = Silverpop.new
  response = silverpop.silverpop_request_post(builder)
  return response.body
end


#Creates the array of hashes to use in building the rules later on
#Needs which versions to create rules for, the name of the ruleset, and the column name its comparing to
def create_rules_hash(versions, name, column_name)
  digest_object = []
  versions.each do |x|
    digest_object.push({:name => name, 
              :contents => "Sample Content", 
              :expressions => [{:type => "TE", 
                :column_name => column_name, 
                :values => x},
              {:type => "TE", 
                :column_name => "Email Type", 
                :values => "0",
                :and_or => "AND"}]
              })
  end
  return digest_object
end

#hashes that include the ruleset names, the columns to check against, and the ruleset_id to overwrite
rulesets = [{:name => "ruleset_1", :column => "Field_1", :ruleset_id => '12345678' },
      {:name => "ruleset_2", :column => "Field_2", :ruleset_id => '12345679'}]

#Walk through the rulesets and change the xml for each ruleset_id
#Runs the change_xml method for the ruleset_id, on the column specificed
rulesets.each do |x|
  ruleset = change_xml(x[:ruleset_id], 
              x[:column], 
              "", 
              create_rules_hash(versions, x[:name], x[:column]))
  puts ruleset
end
