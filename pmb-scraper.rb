#
# ruby script to retrieve multiple strored queries from PMB library software
# and merge them together in one file
#

#######################
#
# TODO / Workflow
# read config
# retrieve tables
#   login
#     loop and retrieve all tables
#   logout
# merge tables into on html file
#
#######################

require 'mechanize'
require 'yaml'
require 'csv'

# >>> patch the mechanize to allow posting array values for multi select
# thanks @ Nikolay V. Nemshilov
# http://st-on-it.blogspot.com/2010/03/mechanize-and-multiselect-fields.html
class Mechanize::Form::Field
  def query_value
    if @value.is_a?(Array)
      @value.collect{ |v| [@name, v || '']}
    else
      [[@name, @value || '']]
    end
  end
end
# <<< end patch

### INITIALIZATION

puts "\n   ~~~  PMB SCRAPER  ~~~\n\n"

puts "INITIALIZING"
# load config
CONFIG = YAML.load_file 'config.yml'
result_file = File.join(CONFIG['result_dir'], Time.now.strftime("%Y-%m-%d_%H-%M-%S") + '.html')

queries_csv = 'queries.csv'

# setup urls
url_base = CONFIG['base_url']
url_query = url_base + 'edit.php'
url_logout = url_base + 'logout.php'

base_hash = {'categ' => 'procs', 'form_type' => 'gen_form', 'dest' =>'TABLEAUHTML', 'action' => 'execute'}

puts '.. URLs'
puts '..   base:    ' + url_base
puts '..   queries: ' + url_query
puts '..   logout:  ' + url_logout
puts ".. base_hash: #{base_hash}"

# open template
puts '.. opening template'
temp_f = File.open('template.html')
template = Nokogiri::HTML.parse(temp_f)
temp_f.close
content_div = template.at_css('#content')
directory_div = template.at_css('#directory')

# load queries
puts ".. reading #{queries_csv}"
query_array = []
CSV.read(queries_csv,{:headers => true}).each do |row|
  break if row[0].to_s.strip.empty?
  hash = {'id_proc' => row[0].to_s.strip}
  # capture parameters
  col = 1
  while (!row[col].to_s.strip.empty?)
    key = row[col].to_s.strip
    val = row[col+1].to_s.strip
    # create array for multiple select
    if hash[key].nil?
      hash[key] = val
    else
      hash[key] = [hash[key]] if hash[key].is_a? String
      hash[key] << val if hash[key].is_a? Array        
    end    
    col += 2
  end  
  puts "     " + hash.to_s
  query_array << hash
end

### GO ONLINE AND DO STUFF

# login
a = Mechanize.new
puts "LOGGING IN AS #{CONFIG['username']}"
p = a.get(url_base)
login_form = p.forms.first

login_form['user'] =  CONFIG['username']
login_form['password'] = CONFIG['password']
login_form.submit

# retrieve tables
first_iteration = true

query_array.each do |post_hash|
  if first_iteration
    first_iteration = false
  else
    puts 'waiting 2 seconds'
    sleep 2
  end
  
  puts "RETRIEVING QUERY #{post_hash}"
  complete_hash = base_hash.merge(post_hash)
  p = a.post url_query, complete_hash

  puts '.. extracting information'
  pn = Nokogiri::HTML.parse p.body
  query_header = pn.css('h1')[1].dup
  query_header.name = 'h2'
  query_description = pn.css('h2').first.dup
  query_description.name = 'p'
  query_table = pn.css('table').first.dup
  query_code_text = pn.xpath('//body/text()').first.content
  query_code = Nokogiri::XML::Node.new('p', template)
  query_code.content = query_code_text
  query_code['class'] = 'code sql'
  query_params = Nokogiri::XML::Node.new('p', template)
  query_params.content = post_hash.to_s
  query_params['class'] = 'code params'
  
  puts '.. formatting result'
  request_div_id = "request_#{post_hash['id_proc']}"
  
  request_div = Nokogiri::XML::Node.new('div', template)
  request_div['class'] = 'request'
  request_div['id'] = request_div_id

  request_div.add_child(query_header)
  request_div.add_child(query_description)
  request_div.add_child(query_params)
  request_div.add_child(query_code)
  request_div.add_child(query_table)

  content_div.add_child(request_div)

  puts '.. add directory link'
  directory_link = Nokogiri::XML::Node.new('a', template)
  directory_link.content = query_header.text
  directory_link['href'] = '#' + request_div_id

  directory_div.add_child(directory_link)
end

# logout
puts "LOGGING OUT"
p = a.get url_logout

### SAVE RESULT
puts "SAVING RESULT as #{result_file}"
File.open(result_file, 'w') {|f| template.write_html_to f}

puts 'finished - press ENTER to exit'
gets #dont close windows terminal
exit 0

# mixmax
# mit parameter
#  a.post "http://192.168.1.1/opac_ccf/edit.php",
#    {'categ' => 'procs', 'id_proc' => 50, 'action' => 'execute', 'nombre_minimum' => 4, 'form_type' => 'gen_form'}

# TODO
# javascript
#   select table: http://stackoverflow.com/questions/2044616/select-a-complete-table-with-javascript-to-be-copied-to-clipboard
#   hide directory
#   hide all sql
# show forms elements to add to table





