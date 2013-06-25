#
# ruby script to retrieve to find the parameters needed to
# write the queries.csv and finally execute the queries
# 
# from queries.csv it reads the first row (the id_proc)
# and then scrapes PMB for parameters which must be given
# it shows all parameters and gives an example configuration line
#

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

puts "\n   ~~~  PMB QUERY PARAMS FINDER  ~~~\n\n"

puts "INITIALIZING"
# load config
CONFIG = YAML.load_file 'config.yml'
result_file = File.join(CONFIG['result_dir'], Time.now.strftime("%Y-%m-%d_%H-%M-%S") + '.html')

queries_csv = 'queries.csv'

# setup urls
url_base = CONFIG['base_url']
url_query = url_base + 'edit.php'
url_logout = url_base + 'logout.php'

base_hash = {'categ' => 'procs', 'action' => 'execute'}

puts '.. URLs'
puts '..   base:    ' + url_base
puts '..   queries: ' + url_query
puts '..   logout:  ' + url_logout
puts ".. base_hash: #{base_hash}"

# load queries
puts ".. reading #{queries_csv}"
query_array = []
CSV.read(queries_csv,{:headers => true}).each do |row|
  query_array << {'id_proc' => row[0].to_s.strip}
end

puts query_array

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
    puts "\nwaiting 2 seconds"
    sleep 2
  end
  
  puts "\nRETRIEVING QUERY #{post_hash}"
  complete_hash = base_hash.merge(post_hash)
  p = a.post url_query, complete_hash
  example_array = [post_hash['id_proc']]

  query_string = complete_hash.to_a.collect{|h| h.join('=')}.join('&')
  full_url = url_query + '?' + query_string
  puts full_url
  
  form = p.form('formulaire')
  if form.nil?
    puts p.search('h1')[1].text
    puts '-> no parameters needed'
  else
    puts p.search('.form-contenu h3').text
    %w(id_query form_type).each {|field_name| form.delete_field! field_name}
    fields = form.fields
    fields.each do |field|
      puts ".. " + field.class.to_s #.split('::').last
      if field.class.to_s == "Mechanize::Form::MultiSelectList"
        puts "   (selection of multiple values is possible)"
      end
      
      puts "   name: " + field.name
      if field.respond_to? :options
        puts "   values / descriptions:"
        opt_count = 0
        field.options.each do |opt|
          unless opt.value.empty?
            puts "     " + opt.value + " -> " + opt.text
            if opt_count == 0 || (opt_count == 1 && field.class.to_s == "Mechanize::Form::MultiSelectList")
              example_array << field.name
              example_array << opt.value
            end
            opt_count = opt_count + 1
          end          
        end
      else
        example_array << field.name
        example_array << "[value for #{field.name}]"
      end
    end
  end
  puts ".. example queries.csv column"
  puts "   " + example_array.join(' , ');
end

# logout
puts "\nLOGGING OUT"
p = a.get url_logout

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

#
# form = p.form_with(:name => 'formulaire')
# complete_hash => {"categ"=>"procs", "action"=>"execute", "id_proc"=>38}
#form.keys

# => ["id_query", "form_type", "sections[]", "preteur"]

# 1.9.3p125 :071 > form.fields
# => [[hidden:0xc590e0 type: hidden name: id_query value: 38], [hidden:0xc58f8c type: hidden name: form_type value: gen_form], [multiselectlist:0xc58910 type:  name: sections[] value: []], [selectlist:0xc5830c type:  name: preteur value: ]]

#1.9.3p125 :072 > form.delete_field! 'id_query'
# => [[hidden:0xc58f8c type: hidden name: form_type value: gen_form], [multiselectlist:0xc58910 type:  name: sections[] value: []], [selectlist:0xc5830c type:  name: preteur value: ]]

#1.9.3p125 :073 > form.delete_field! 'form_type'
# => [[multiselectlist:0xc58910 type:  name: sections[] value: []], [selectlist:0xc5830c type:  name: preteur value: ]] 
#1.9.3p125 :074 > form.fields
# => [[multiselectlist:0xc58910 type:  name: sections[] value: []], [selectlist:0xc5830c type:  name: preteur value: ]] 
#





