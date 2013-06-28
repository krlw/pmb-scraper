# pmb-scraper

The pmb scraper downloads a predefined selection of preprogrammed queries
from the PMB library software and integrates them into one HTML document.

  
## Installation on Windows


### Download the pmb-scraper

* Download the repository as a zip (top left)
* Extract the folder to some place with write access (e.g. Desktop)


### Install the Ruby language

* Download and install the rubyinstaller (version 1.9.3) from http://rubyinstaller.org/downloads/
* follow the instructions on screen and select all of the following settings:
    * Install Tcl/Tk support
    * Add Ruby executables to your PATH
    * Associate .rb and .rbw files with your Ruby installation


### Install neccesary libraries

* Doubleclick _INSTALLATION/install-libraries.bat_
  and wait until the process finishes


## Configuration


### Access to your PMB instance

* Rename the file _config.yml.dist_ to _config.yml_
* open the _config.yml_ in a Text Editor
* fill in your details of your PMB instance:

```
# Initial configuration to access your PMB instance
 
# how to access the PMB instance
base_url: http://192.168.1.1/opac_ccf/
            ^                        ^
      the url of PMB      (dont forget the trailing slash)
     
username: admin   <---.
password: admin   <----`--- your user credentials for PMB 
     
# make sure this directory exists
result_dir: ./results   <--.
                            ` The result htmls will be saved here
                              (a dot (.) means the current directory)
```


## Using the pmb-scraper

The basic workflow for using the pmb-scraper looks like this:

1. Select and note the query ids in the first row of the _queries.csv_
2. run _query-creation-helper.rb_ to find neccesary query parameters
3. fill in these parameters into the _queries.csv_
4. run the _pmb-scraper.rb_ and create the resulting report

The following lines will explain these steps in detail.


### How it works / the role of _queries.csv_

The pmb scraper basically requests all queries which are noted together
with their neccesary parameters in the file _queries.csv_. CSV files are tables,
which can easily be edited with text editors or tools like Excel or Calc.
CSV means comma seperated, therefore table cells are seperated by a comma,
rows are seperated by a newline.

One column in _queries.csv_ describes one query done in PMB, a column must
include the id of the query (id_proc) and all neccesary parameters
(dates, section or whatever) and their values in a form that looks like:
```
QUERY_ID, PARAM_1, VALUE_FOR_PARAM_1, PARAM_2, VALUE_FOR_PARAM_2, ...
```

For example if we only want include the query from this url:
```
http://192.168.1.1/opac_ccf/edit.php?categ=procs&sub=&action=execute&id_proc=70
                                                                     \___ ____/
                                                                         |
                                                            the id of the query
```
![Query in Browser Screenshot](https://raw.github.com/krlw/pmb-scraper/master/INSTALLATION/screenshot-proc-70-for-readme.jpg)



and want to run the query with these parameters 
* Statuts qui autorisent le prêt : __Accès Libre__ and __Animation__
* Date de début de prêt : du ... : __01/01/2012__
* Au ... : __31/12/2012__

our resulting _queries.csv_ should look like this:

```
proc_id,parameter,value,parameter,value,...,...
70 , Du , 2012-01-01 , Au , 2012-12-31 , statuts[] , 2 , statuts[] , 7
```
  
__It should be noted that the Dates given must be in the form of YYYY-MM-DD.__

But to create this request within the _queries.csv_ seems rather complicated.
It gets easier with the help of the _query-creation-helper.rb_, which takes all
the query ids and helps with the configuration of their query parameters.


### Configuring _queries.csv_ with the help of _query-creation-helper.rb_

The query creation helper only reads the proc_ids from the firsts row of the
_queries.csv_. It then visits all the given pages and outputs all avaible
parameters and, if possible, the values. It notes, when a parameter can take
multiple values. For each query it also takes the parameters and values found
and creates an example line.

Therefore it makes sense to start with a _queries.csv_ which only includes the ids
and for our example would look like this:
```
proc_id,parameter,value,parameter,value,...,...
70 
```

If we now run the _query-creation-helper.rb_ the output helps us to parameterize
the query:

```
  ...

RETRIEVING QUERY {"id_proc"=>"70"}
http://192.168.1.1/opac_ccf/edit.php?categ=procs&action=execute&id_proc=70 
Nombre d'exemplaires - empruntables mais pas empruntés entre ... et ...    
.. Mechanize::Form::Hidden
   name: Du
.. Mechanize::Form::Hidden
   name: Au
.. Mechanize::Form::MultiSelectList
   (selection of multiple values is possible)
   name: statuts[]
   values / descriptions:
     2 -> Accès libre
     7 -> Animation
     6 -> Bureau interne
     1 -> Consultation sur place
     4 -> Perdu
     3 -> Pilon
     5 -> Reliure
.. example queries.csv column
   70 , Du , [value for Du] , Au , [value for Au] , statuts[] , 2 , statuts[] , 7

   ...
```

If we at the same time open the browser at the site of the query we can deduct
the names of the parameters and their meaning, that:

* __Date de début de prêt : du ...__ should be noted as __Du__
* __Au ...__ should be noted as __Au__
* __Statuts qui autorisent le prêt__ should be noted as __statuts[]__

The parameters __Du__ and __Au__ want a date as their parameter.
As said before, they must be noted in the form YYYY-MM-DD.
If we want to explore the year 2012
the value given for __Du__ should be __2012-01-01__, and
the value for __Au__ should be __2012-12-31__.

Our line so far in _queries.csv_ therefore should look like:
```
70 , Du , 2012-01-01 , Au , 2012-12-31 
```

Also in the output of the _query-creation-helper.rb_ we can see the lines
```
.. Mechanize::Form::MultiSelectList
   (selection of multiple values is possible)
   name: statuts[]
   values / descriptions:
     2 -> Accès libre
     7 -> Animation
     6 -> Bureau interne
     1 -> Consultation sur place
     4 -> Perdu
     3 -> Pilon
     5 -> Reliure
```

First of all that means that the values for the parameter __statuts[]__
must be a number from 1 to 7. The corresponding meaning of these numbers is also
clearly visible.
The output also tells that multiple values can be selected.
This can be noted by repeating the parameter name with different values.
If we, for example are interested to inquiry the two categories __'Accès libre' (2)__
and __'Animation' (7)__ we would add
```
statuts[] , 2 , statuts[] , 7
```
to our line.

Finally, the complete row within _queries.csv_, which closely looks similar to the example
line from the output of _query-creation-helper.rb_, should look like that:
```
proc_id,parameter,value,parameter,value,...,...
70 , Du , 2012-01-01 , Au , 2012-12-31 , statuts[] , 2 , statuts[] , 7
```

This procedure should be repeated for all the queries which you want to be
included in your report - it really sounds more complicated than it is!

Note also that if you leave a row one line to the right in _queries.csv_ it will
be ignored by the _query-creation-helper.rb_ and the _pmb-scraper.rb_.
This can easily acived in _queries.csv_, if you add a comma before the line, like so:
```
proc_id,parameter,value,parameter,value,...,...
,70 , Du , 2012-01-01 , Au , 2012-12-31 , statuts[] , 2 , statuts[] , 7
```

If all the wanted queries are collected it's time to let _pmb-scraper.rb_
collect these queries and merge them within a single report.


### Executing the _pmb-scraper.rb_

Executing the pmb-scraper to generate the report is as easy as executing
_pmb-scraper.rb_. The programm then collects all queries noted in _queries.csv_
and accumulates their results as a well formatted HTML-document in the results folder.

In out example only one row is existing within _queries.csv_. The output of a
successful run of queries.csv would then look like this:

```
   ~~~  PMB SCRAPER  ~~~

INITIALIZING
.. URLs
..   base:    http://192.168.1.1/opac_ccf/
..   queries: http://192.168.1.1/opac_ccf/edit.php
..   logout:  http://192.168.1.1/opac_ccf/logout.php
.. base_hash: {"categ"=>"procs", "form_type"=>"gen_form", "dest"=>"TABLEAUHTML", "action"=>"execute"}
.. opening template
.. reading queries.csv
     {"id_proc"=>"70", "Du"=>"2012-01-01", "Au"=>"2012-12-31", "statuts[]"=>["2", "7"]}
LOGGING IN AS admin
RETRIEVING QUERY {"id_proc"=>"70", "Du"=>"2012-01-01", "Au"=>"2012-12-31", "statuts[]"=>["2", "7"]}
.. extracting information
.. formatting result
.. add directory link
LOGGING OUT
SAVING RESULT as ./results/2013-06-27_15-16-41.html
finished - press ENTER to exit
```

And we will find the accumulated results as as file named with the current
date and time in the results folder.


### Handling Errors

If the program fails just after `LOGGING IN AS ...`:
* the network connection is bad, can you access your PMB instance in the browser?
    * maybe just try to run the program again 
* the details in _config.yml_ are wrong:
    * Is the url to your PMB instance correct?
    * Are the login credentials correct?

If the program fails to retrieve the _first_ Query it might be that your forgot
the trailing slash (/) setting for `base_url` in your _config.yml_, it should look like
```
base_url: http://192.168.1.1/opac_ccf/
```

The program fails while retrieving a query: most probably you did not set (all)
the correct parameters and values for the query in question in _queries.csv_.
Check the row corresponding to the failing query. Otherwise check if the query
runs in the browser, maybe the SQL is just faulty.



  
  


