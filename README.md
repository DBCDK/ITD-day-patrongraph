# Visualisations of loaner data for a given book

## TODO

- Load ADHL-data into mongodb 
- visualise patronstat
- easy embedding in any page, ie. `<span class="patrongraph" data-faust="12345"></span>` ... `<script src="...patrongraph.js"></script>`

# Source code

## Definitions

We need a sample faust number for getting started, this will be removed later on, only used for testing when starting coding

    testFaust = 1234

## MongoDB databases and publishing

We have a mapping from faust-numbers to klyngeid

    faustDB = new Meteor.Collection("faust") 

and the actual database of patron statistics

    statDB = new Meteor.Collection("patronstat") 


## Create database

    if Meteor.isServer
        dbLoading = false

        initDB = ->
            return if dbLoading or statDB.findOne {_id: "dbLoaded"} 
            console.log "here we should parse the data dump and load it into the mongodb"

        Meteor.startup(initDB) 
