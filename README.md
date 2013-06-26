# pmb-scraper

The pmb scraper crawls a predefined selection of preprogrammed queries
from the PMB library software and integrates them into one HTML document.
  
## INSTALLATION ON WINDOWS

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

* Doubleclick `INSTALLATION/Install-Libraries.bat`
  and wait until the process finishes

## CONFIGURATION

### Access to your PMB instance

* Rename the file `config.yml.dist` to `config.yml`
* open the `config.yml` in a Text Editor
* fill in your details of your PMB instance:

```
# BASIC CONFIGURATION FILE FOR THE PMB SCRAPER
 
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

## USING THE PMB SCRAPER

### How it works / the role of queries.csv

  The pmb scraper basically requests all queries which are noted together
  with their neccesary parameters in the file queries.csv
    
  This file can be edited either via a text editor or with a spreadsheet program
  like Excel.

  One column in queries.csv describes one query done in PMB, a column must
  include the id of the query and all neccesary parameters and their values in a
  form that it looks like:
  
```
  QUERY_ID, PARAM_1, VALUE_1, PARAM_2, VALUE_2, ...
```

  // TODO

### Configuring queries.csv with the help of query-creation-helper.rb

  The query creation helper only reads the proc ids from the firsts row of the
  queries.csv. It them visits all the

  // TODO

  

    

  
  


