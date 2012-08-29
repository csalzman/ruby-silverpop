require 'nokogiri'

#############################
#
# Builds a Silverpop ruleset:
# -name is used for the ruleset name 
# -list_id is the list the ruleset is tied to
# -mailing_id is the id of the email template
# -content_area is the name that the email will refer to the content area with
# -default_content is the content that the content area will default to if no rules are matches
# -rules is an array of hashes each rule needs
#	# -name for the rule name
#	# -column_name for which column to check against
#	# -values to check against
#	# -contents for the content
# -rules can optionally include
#	# -type which determines how you match against the column
#	# -operators like <, >, =, and some silverpop specific ones check documentation
#	# -left and right parens which let you group rules together
#	# -and_or to use with different rules
#
#############################

module Silverpop_rulesets
	require 'nokogiri'
	def Silverpop_rulesets.build_ruleset(name, list_id, mailing_id, content_area, default_content, rules)
		builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
			xml.RULESET {
				xml.RULESET_ID
					xml.RULESET_NAME name
					xml.LIST_ID list_id
					xml.MAILING_ID mailing_id
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
			end
		return builder
	end
end

#Creates the array of hashes to use in building the rules later on
#Needs which versions to create rules for, the name of the ruleset, and the column name its comparing to
def create_digest_xml(content_array, name, column_name)
	array_of_hashes = []
	content_array.each do |x|
		array_of_hashes.push({:name => name, 
							:contents => "HTML Sample Data", 
							:expressions => [{:type => "TE", 
								:column_name => column_name, 
								:values => x},
							{:type => "TE", 
								:column_name => "Email Type", 
								:values => "0",
								:and_or => "AND"}]
							})
		array_of_hashes.push({:name => name, 
							:contents => "TEXT only Sample Data", 
							:expressions => [{:type => "TE", 
								:column_name => column_name, 
								:values => x},
							{:type => "TE", 
								:column_name => "Email Type", 
								:values => "1",
								:and_or => "AND"}]
							})
	end
	return array_of_hashes
end

#hashes that include the ruleset names and the columns to check against
rulesets = [{:name => "ruleset_1", :column => "column_name_1"},
			{:name => "ruleset_2", :column => "column_name_2"}]

#Mailingid for the template where the rulesets live
mailingid = "12345655"

#Array of content to use for the rulesets

content_array = ['Content1', 'Content2']

#For each of the rulesets write the ruleset to a file
rulesets.each do |x|
	ruleset = Silverpop_rulesets.build_ruleset(x[:name], 
							ENV['SILVERPOP_LIST_ID'], 
							mailingid, 
							x[:column], 
							"", 
							create_digest_xml(content_array, x[:name], x[:column]))
	filename = "Naming-Convention" + x[:name].to_s + ".xml"
	f = File.open(filename, "w+")
	f.write(ruleset.to_xml)
	f.close
end